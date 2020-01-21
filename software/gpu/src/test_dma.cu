#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <GpuAsync.h>


//-----------------------------------------------------------------------------

void checkError(CUresult status);
bool wasError(CUresult status);

//-----------------------------------------------------------------------------

__global__ void data_move(uint32_t *in, uint32_t *out) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    //int tid;

    uint32_t size = in[1]/4;

    if ( tid < size ) {
    //for (tid=0; tid < size; tid++) {
        out[tid] = in[tid+8];
    }
}


int main(int argc, char *argv[]) {
   uint x;
   int res = -1;

   int fd = open("/dev/datagpu_0", O_RDWR);
   if (fd < 0) {
      printf("Error open file\n");
      return -1;
   }

   ////////////////////////////////////////////
   // Open and setup GPU
   ////////////////////////////////////////////
   CUresult status;
   checkError(cuInit(0));

   int total = 0;
   checkError(cuDeviceGetCount(&total));
   fprintf(stderr, "Total devices: %d\n", total);

   CUdevice device;
   checkError(cuDeviceGet(&device, 1));

   char name[256];
   checkError(cuDeviceGetName(name, 256, device));
   fprintf(stderr, "Select device: %s\n", name);

   size_t global_mem = 0;
   checkError( cuDeviceTotalMem(&global_mem, device));
   fprintf(stderr, "Global memory: %llu MB\n", (unsigned long long)(global_mem >> 20));
   if(global_mem > (unsigned long long)4*1024*1024*1024L) fprintf(stderr, "64-bit Memory Address support\n");

   CUcontext  context;
   checkError(cuCtxCreate(&context, 0, device));

   ////////////////////////////////////////////////
   // Create write and read buffers
   ////////////////////////////////////////////////
   size_t size = 0x10000;
   CUdeviceptr hwWritePtr = 0;
   CUdeviceptr hwReadPtr  = 0;
   uint32_t * hostWriteBuff = (uint32_t *)malloc(size);
   uint32_t * hostReadBuff  = (uint32_t *)malloc(size);

   memset(hostWriteBuff,0,size);
   memset(hostReadBuff,0,size);

   status = cuMemAlloc(&hwWritePtr, size);
   if(wasError(status)) printf("Failed to alloc write pointer\n");

   status = cuMemAlloc(&hwReadPtr, size);
   if(wasError(status)) printf("Failed to alloc read pointer\n");

   cuMemcpyHtoD( hwWritePtr, hostWriteBuff, size );
   cuMemcpyHtoD( hwReadPtr, hostReadBuff, size );

   uint32_t flag = 1;

   cuPointerSetAttribute(&flag, CU_POINTER_ATTRIBUTE_SYNC_MEMOPS, hwWritePtr);
   cuPointerSetAttribute(&flag, CU_POINTER_ATTRIBUTE_SYNC_MEMOPS, hwReadPtr);

   ////////////////////////////////////
   // Add buffer to hardware
   ////////////////////////////////////
   printf("Setting write pointer\n");
   gpuAddNvidiaMemory(fd,1,(uint64_t)hwWritePtr,size);
   printf("Setting read pointer\n");
   gpuAddNvidiaMemory(fd,0,(uint64_t)hwReadPtr,size);
   printf("Done with pointers\n");

   ////////////////////////////////////////////////
   // Map FPGA register space to GPU
   ////////////////////////////////////////////////

   // Setup FPGA Registers
   printf("Mapping FPGA registers\n");
   uint8_t * swFpgaRegs = (uint8_t *) dmaMapRegister(fd, 0x00A00000, 0x00100000);

   if ( swFpgaRegs == NULL ) printf("Failed to map FPGA registers\n");
   else printf("swFpgaRegs = 0x%lx\n",(uint64_t)swFpgaRegs);

   printf("Enabling IO memory for FPGA registers\n");
   status = cuMemHostRegister(swFpgaRegs, 0x00100000, CU_MEMHOSTREGISTER_IOMEMORY);
   if(wasError(status)) printf("Failed to host register memory. Status = %i\n",status);

   CUdeviceptr hwWriteStart = 0;
   CUdeviceptr hwReadStart  = 0;

   printf("Mapping write start register\n");
   status = cuMemHostGetDevicePointer(&hwWriteStart, swFpgaRegs + 0x300, 0);
   if(wasError(status)) printf("Failed to map device write start pointer. Status = %i\n",status);

   printf("Mapping read start register\n");
   status = cuMemHostGetDevicePointer(&hwReadStart,  swFpgaRegs + 0x400, 0);
   if(wasError(status)) printf("Failed to map device read start pointer. Status = %i\n",status);

   printf("Mapped FPGA registers\n");

   ////////////////////////////////////
   // Setup GPU streaming
   ////////////////////////////////////
   CUstream stream;

   cudaStreamCreate(&stream);

   fprintf(stderr, "Trigger write\n");
   cuStreamWriteValue32(stream,hwWriteStart,0x00,0);
   cuStreamWaitValue32(stream, hwWritePtr+4, 1, CU_STREAM_WAIT_VALUE_GEQ);

   // Do GPU processing here
   data_move<<<4,1024,1,stream>>>((uint32_t*)hwWritePtr,(uint32_t*)hwReadPtr);
   //data_move<<<1,1,1,stream>>>((uint32_t*)hwWritePtr,(uint32_t*)hwReadPtr);

   //cuStreamWriteValue32(stream,hwReadStart,((uint32_t*)(hwWritePtr))[1],0);
   cuStreamWriteValue32(stream,hwReadStart,0x2020,0);

   fprintf(stderr, "Stream Sync\n");
   cudaStreamSynchronize(stream);

   cuCtxSynchronize();
   cuMemcpyDtoH( hostWriteBuff, hwWritePtr, size );
   cuMemcpyDtoH( hostReadBuff, hwReadPtr, size );

   for (x=0; x < 100; x++) printf("data: %i 0x%8x - 0x%8x\n",x,hostWriteBuff[x],hostReadBuff[x]);

   res = gpuRemNvidiaMemory(fd);
   if(res < 0) fprintf(stderr, "Error in IOCTL_GPUDMA_MEM_UNLOCK\n");
}

// -------------------------------------------------------------------

void checkError(CUresult status)
{
    if(status != CUDA_SUCCESS) {
        const char *perrstr = 0;
        CUresult ok = cuGetErrorString(status,&perrstr);
        if(ok == CUDA_SUCCESS) {
            if(perrstr) {
                fprintf(stderr, "info: %s\n", perrstr);
            } else {
                fprintf(stderr, "info: unknown error\n");
            }
        }
        exit(0);
    }
}

//-----------------------------------------------------------------------------

bool wasError(CUresult status)
{
    if(status != CUDA_SUCCESS) {
        const char *perrstr = 0;
        CUresult ok = cuGetErrorString(status,&perrstr);
        if(ok == CUDA_SUCCESS) {
            if(perrstr) {
                fprintf(stderr, "info: %s\n", perrstr);
            } else {
                fprintf(stderr, "info: unknown error\n");
            }
        }
        return true;
    }
    return false;
}


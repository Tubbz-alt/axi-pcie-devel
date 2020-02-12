#!/usr/bin/env python3

import pyrogue
import time
import cProfile

pyrogue.addLibraryPath('../../firmware/submodules/axi-pcie-core/python')
pyrogue.addLibraryPath('../../firmware/submodules/surf/python')
pyrogue.addLibraryPath('../../firmware/python')

import pyrogue.pydm
import pyrogue.gui
import rogue

from AxiPcieDevel.InterCardTest import InterCardRoot

#rogue.Logging.setFilter('pyrogue.memory.block',rogue.Logging.Debug)
#rogue.Logging.setFilter('pyrogue.prbs.rx',rogue.Logging.Debug)
#rogue.Logging.setLevel(rogue.Logging.Debug)

def loopReadTest(root,count):
    for i in range(count):
        root.PcieControl[0].Fpga.AxiPcieCore.AxiVersion.ScratchPad.get()

def loopWriteTest(root,count):
    for i in range(count):
        root.PcieControl[0].Fpga.AxiPcieCore.AxiVersion.ScratchPad.set(i)

def loopRawReadTest(root,count):
    for i in range(count):
        root.PcieControl[0].Fpga.AxiPcieCore.AxiVersion._rawRead(0x4)

def loopRawWriteTest(root,count):
    for i in range(count):
        root.PcieControl[0].Fpga.AxiPcieCore.AxiVersion._rawWrite(0x4,i)

with InterCardRoot(pollEn=False) as root:

    ##########################################################
    time.sleep(5)

    stime = time.time()
    count = 500000

    with root.updateGroup():
        cProfile.run('loopReadTest(root,count)')

    etime = time.time()
    dtime = etime - stime
    rate = count / dtime

    print(f"Completed {count} reads in {dtime} seconds. Rate = {rate}")

    ##########################################################
    time.sleep(5)

    stime = time.time()
    count = 500000

    with root.updateGroup():
        cProfile.run('loopWriteTest(root,count)')

    etime = time.time()
    dtime = etime - stime
    rate = count / dtime

    print(f"Completed {count} writes in {dtime} seconds. Rate = {rate}")

    ##########################################################
    time.sleep(5)

    stime = time.time()
    count = 500000

    with root.updateGroup():
        cProfile.run('loopRawReadTest(root,count)')

    etime = time.time()
    dtime = etime - stime
    rate = count / dtime

    print(f"Completed {count} raw reads in {dtime} seconds. Rate = {rate}")

    ##########################################################
    time.sleep(5)

    stime = time.time()
    count = 500000

    with root.updateGroup():
        cProfile.run('loopRawWriteTest(root,count)')

    etime = time.time()
    dtime = etime - stime
    rate = count / dtime

    print(f"Completed {count} raw writes in {dtime} seconds. Rate = {rate}")


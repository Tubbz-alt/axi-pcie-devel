#!/usr/bin/env python3
import pyrogue as pr
import axipcie
import surf.protocols.ssi

class Fpga(pr.Device):

    def __init__(self,name='Fpga',**kwargs):
        pr.Device.__init__(self,name=name,**kwargs)

        self.add(axipcie.AxiPcieCore(useSpi=True))

        for i in range(4):
            self.add(surf.protocols.ssi.SsiPrbsTx(name=f'PrbsTx[{i}]',offset=0x00800000 + (i*0x100000)))

        for i in range(4):
            self.add(surf.protocols.ssi.SsiPrbsRx(name=f'PrbsRx[{i}]',offset=0x00800000 + ((i+4)*0x100000)))



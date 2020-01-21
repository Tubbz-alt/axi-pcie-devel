#!/usr/bin/env python3
import pyrogue as pr
import rogue.hardware.axi
import pyrogue.utilities.prbs
import AxiPcieDevel.InterCardTest

class PcieControl(pr.Device):

    def __init__(self,index=0):
        pr.Device.__init__(self,name=f'PcieControl[{index}]')

        self._dataMap = rogue.hardware.axi.AxiMemMap(f'/dev/datagpu_{index}')

        self.add(AxiPcieDevel.InterCardTest.Fpga(memBase=self._dataMap))


#!/usr/bin/env python3
import pyrogue as pr
import AxiPcieDevel.InterCardTest

class InterCardRoot(pr.Root):

    def __init__(self,pollEn=True):
        pr.Root.__init__(self,name='InterCardRoot',description='Tester', pollEn=pollEn)

        for i in range(1):
            self.add(AxiPcieDevel.InterCardTest.PcieControl(index=i))


#!/usr/bin/env python3
import pyrogue as pr
import AxiPcieDevelApp.InterCardTest

class InterCardRoot(pr.Root):

    def __init__(self):
        pr.Root.__init__(self,name='InterCardRoot',description='Tester', pollEn=True)

        for i in range(1):
            self.add(AxiPcieDevelApp.InterCardTest.PcieControl(index=i))


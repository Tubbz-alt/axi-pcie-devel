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

with InterCardRoot(pollEn=False) as root:
    print("Value = {}".format(root.PcieControl[0].Fpga.AxiPcieCore.AxiVersion.FpgaVersion.getDisp()))

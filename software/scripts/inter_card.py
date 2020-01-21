#!/usr/bin/env python3

import pyrogue

pyrogue.addLibraryPath('../../firmware/submodules/axi-pcie-core/python')
pyrogue.addLibraryPath('../../firmware/submodules/surf/python')
pyrogue.addLibraryPath('../../firmware/python')
pyrogue.addLibraryPath('../python')

import pyrogue.pydm
import pyrogue.gui
import rogue

from AxiPcieDevelApp.InterCardTest import InterCardRoot

#rogue.Logging.setFilter('pyrogue.prbs.rx',rogue.Logging.Debug)
#rogue.Logging.setLevel(rogue.Logging.Debug)

with InterCardRoot() as root:

    pyrogue.pydm.runPyDM(root=root)
    #pyrogue.gui.runGui(root=root)
    #pyrogue.waitCntrlC()



file(GLOB 2DX_AUTO 2dx_automator.py)
file(GLOB MC_AUTO motioncorrect_gui.py)
file(GLOB MC_SPLIT MC_splitter.py)
file(GLOB MC_PLOT driftplotter.py)
file(GLOB CR_PLOT crystalplotter.py)
file(GLOB PY_FILES *.py)

file(GLOB PY_RES_FILES *.py)
list(REMOVE_ITEM PY_RES_FILES ${2DX_AUTO})
list(REMOVE_ITEM PY_RES_FILES ${MC_AUTO})
list(REMOVE_ITEM PY_RES_FILES ${MC_SPLIT})
list(REMOVE_ITEM PY_RES_FILES ${MC_PLOT})
list(REMOVE_ITEM PY_RES_FILES ${CR_PLOT})

file(GLOB CONFIG_FILES default_configs/*.cfg)

install(FILES ${PY_FILES} DESTINATION 2dx_automator)

install(FILES ${PY_RES_FILES} DESTINATION bin)
install(PROGRAMS ${2DX_AUTO} DESTINATION bin RENAME 2dx_automator)
install(PROGRAMS ${MC_AUTO} DESTINATION bin RENAME MC_automator)
install(PROGRAMS ${MC_SPLIT} DESTINATION bin RENAME MC_splitter)
install(PROGRAMS ${MC_PLOT} DESTINATION bin RENAME driftplotter.py)
install(PROGRAMS ${CR_PLOT} DESTINATION bin RENAME crystalplotter.py)

install(FILES ${CONFIG_FILES} DESTINATION bin/default_configs)

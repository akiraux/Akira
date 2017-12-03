# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.alecaddd.akira.desktop DESTINATION ${DATADIR}/applications/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/16x16/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/16x16/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/24x24/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/24x24/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/32x32/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/32x32/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/48x48/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/48x48/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/64x64/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/64x64/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/128x128/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/128x128/apps/)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/assets/icons/128x128/com.github.alecaddd.akira.svg
        DESTINATION ${DATADIR}/icons/hicolor/scalable/apps/)

# install our .appdata.xml file so AppCenter will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/com.github.alecaddd.akira.appdata.xml DESTINATION ${DATADIR}/metainfo/)
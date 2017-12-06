# project name
project (com.github.alecaddd.akira)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.8)

# enable testing
enable_testing (true)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/com.github.alecaddd.akira")

set (EXEC_NAME "com.github.alecaddd.akira")
set (RELEASE_NAME "Akira")
set (VERSION "0.0.1")
set (VERSION_INFO "The Linux Design Tool")

# disable C compiler warnings
add_definitions(-w)

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite glib-2.0 gee-0.8 gobject-2.0 libxml-2.0 gtksourceview-3.0)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.23.2" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Main.vala
    src/Application.vala
    src/Window.vala

    src/Widgets/MainWindow.vala
    src/Widgets/MainCanvas.vala
    src/Widgets/HeaderBar.vala
    src/Widgets/StatusBar.vala
    src/Widgets/LeftSideBar.vala
    src/Widgets/RightSideBar.vala

    src/Services/Settings.vala
    src/Services/Shortcuts.vala

    src/config.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    granite
    glib-2.0
    gee-0.8
    gobject-2.0
    libxml-2.0
    gtksourceview-3.0
OPTIONS
    -g
    --thread
    --target-glib=2.38
)

include (gresource)
glib_compile_resources(GLIB_RESOURCES_ICONS SOURCE /data/assets.gresource.xml)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_ICONS})

# uninstall target
configure_file (
    "${CMAKE_SOURCE_DIR}/cmake/Uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake"
    IMMEDIATE @ONLY)
configure_file (
    ${CMAKE_SOURCE_DIR}/src/config.vala.cmake 
    ${CMAKE_SOURCE_DIR}/src/config.vala)

add_custom_target (uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/Uninstall.cmake)

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# Translation files
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")

add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (schemas)
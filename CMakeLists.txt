# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required (VERSION 2.6)
cmake_policy (VERSION 2.6)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

project (wingpanel)

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/wingpanel")
set (GETTEXT_PACKAGE "wingpanel")
set (RELEASE_NAME "A super sexy space-saving top panel.")
set (VERSION "0.3.0")
set (VERSION_INFO "Testing")
set (CMAKE_C_FLAGS "-ggdb")

# Set dependencies
set (WINGPANEL_DEPS "gobject-2.0;glib-2.0;gio-2.0;gee-1.0;gdk-x11-3.0;x11;gtk+-3.0;granite")

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${WINGPANEL_DEPS})
pkg_check_modules (THREADS REQUIRED gthread-2.0)
pkg_check_modules (INDICATOR REQUIRED indicator3-0.4)

# Files

file (GLOB stylesheets "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*.css")
file (GLOB desktop_entry "${CMAKE_CURRENT_SOURCE_DIR}/data/wingpanel.desktop")
file (GLOB icon "${CMAKE_CURRENT_SOURCE_DIR}/data/wingpanel.svg")

# Get the Indicator Directory

execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} indicator3-0.4 --variable=indicatordir OUTPUT_VARIABLE current_indicatordir OUTPUT_STRIP_TRAILING_WHITESPACE)
set (INDICATORDIR ${current_indicatordir})

# Configure file

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)


find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.12.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/WingpanelApp.vala
    src/Settings.vala
    src/Utils.vala
    src/Widgets/Panel.vala
    src/Widgets/AppsButton.vala
    src/Services/WingpanelObjectEntry.vala
    src/Services/IndicatorFileModel.vala
PACKAGES
	${WINGPANEL_DEPS}
CUSTOM_VAPIS
    vapi/config.vapi
    vapi/indicator.vapi
    vapi/indicators-gtk.vapi
OPTIONS
	--thread
    -g
)

add_definitions (${DEPS_CFLAGS} ${THREADS_CFLAGS} ${INDICATOR_CFLAGS} -include config.h)
link_libraries (${DEPS_LIBRARIES} ${THREADS_LIBRARIES} ${INDICATOR_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS} ${THREADS_LIBRARY_DIRS} ${INDICATOR_LIBRARY_DIRS})

add_executable (wingpanel ${VALA_C})

# Installation
install (TARGETS wingpanel RUNTIME DESTINATION bin)
install (FILES ${stylesheets} DESTINATION ${PKGDATADIR}/style)
install (FILES ${desktop_entry} DESTINATION ${DATADIR}/applications)
install (FILES ${icon} DESTINATION ${DATADIR}/icons/hicolor/scalable/apps)

# GSettings Schema
include (GSettings)
add_schema ("org.pantheon.desktop.wingpanel.gschema.xml")

# Translations
add_subdirectory (po)

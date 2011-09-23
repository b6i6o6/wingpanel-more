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

# Files

file (GLOB stylesheets "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*.css")
file (GLOB desktop_entry "${CMAKE_CURRENT_SOURCE_DIR}/data/wingpanel.desktop")

# Indicators

execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} indicator3-0.4 --variable indicatordir OUTPUT_VARIABLE _indicatordir OUTPUT_STRIP_TRAILING_WHITESPACE)
set (INDICATORDIR "${_indicatordir}")

# Configure file

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)

# Slingshot

set (WINGPANEL_DEPS "gobject-2.0;glib-2.0;gio-2.0;gee-1.0;gdk-x11-3.0;x11;gtk+-3.0;granite")

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${WINGPANEL_DEPS})
pkg_check_modules (INDICATOR REQUIRED indicator3-0.4)

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.12.0" MINIMUM)

include (ValaPrecompile)
vala_precompile (VALA_C
    src/WingpanelApp.vala
    src/Panel.vala
    src/Settings.vala
    src/WingpanelObjectEntry.vala
    src/IndicatorFileModel.vala
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

add_definitions (${DEPS_CFLAGS} ${INDICATOR_CFLAGS} -include config.h)
link_libraries (${DEPS_LIBRARIES} ${INDICATOR_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS} ${INDICATOR_LIBRARY_DIRS})

add_executable (wingpanel ${VALA_C})

# Installation
install (TARGETS wingpanel RUNTIME DESTINATION bin)
install (FILES ${stylesheets} DESTINATION ${PKGDATADIR}/style)
install (FILES ${desktop_entry} DESTINATION ${DATADIR}/applications)

# GSettings Schema
include (GSettings)
add_schema ("org.elementary.wingpanel.gschema.xml")

# Translations
# add_subdirectory (po)

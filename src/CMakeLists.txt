# Vala stuff
find_package(Vala REQUIRED)
# pkgconfig, real C code
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED gtk+-3.0 glib-2.0 gio-2.0 gee-1.0 indicator3-0.4 x11 gdk-x11-3.0)

include(ValaVersion)
ensure_vala_version("0.12" MINIMUM)
include(ValaPrecompile)

execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} indicator3-0.4 --variable indicatordir OUTPUT_VARIABLE _indicatordir OUTPUT_STRIP_TRAILING_WHITESPACE)

# Base bits

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/wingpanel")
set (GETTEXT_PACKAGE "wingpanel")
set (RELEASE_NAME "A super sexy space-saving top panel.")
set (VERSION "0.2.0")
set (VERSION_INFO "Release")

set (INDICATORDIR "${_indicatordir}")
#set (INDICATORDIR "grrrrrrrr")

#include_directories(${CMAKE_CURRENT_BINARY_DIR}/../vapi)
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CFLAGS
	${DEPS_CFLAGS} ${DEPS_CFLAGS_OTHER}
)
set(LIB_PATHS
	${DEPS_LIBRARY_DIRS}
)
link_directories(${LIB_PATHS})
add_definitions(${CFLAGS})

vala_precompile(VALA_C
    wingpanel-panel.vala
    wingpanel-indicator-file-model.vala
    wingpanel-object-entry.vala
    log.vala
    cardapio.vala
PACKAGES
    gtk+-3.0
    glib-2.0
    gio-2.0
    gee-1.0
    x11
    gdk-x11-3.0
OPTIONS
    --thread
CUSTOM_VAPIS
    ${CMAKE_CURRENT_SOURCE_DIR}/../vapi/config.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/../vapi/indicator.vapi
    ${CMAKE_CURRENT_SOURCE_DIR}/../vapi/indicators-gtk.vapi
    )

add_executable(wingpanel
    ${VALA_C} )

target_link_libraries(wingpanel ${DEPS_LIBRARIES})

configure_file(config.h.cmake ${CMAKE_CURRENT_BINARY_DIR}/config.h)
install(TARGETS wingpanel RUNTIME DESTINATION bin)

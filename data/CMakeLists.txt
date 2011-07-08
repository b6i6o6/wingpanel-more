set (PKGDATADIR "${CMAKE_INSTALL_PREFIX}/share/wingpanel")

install (FILES wingpanel.desktop DESTINATION share/applications)
install (FILES gtk-theme-style.css wingpanel-hud-style.css DESTINATION ${PKGDATADIR})

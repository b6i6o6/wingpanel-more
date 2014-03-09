// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2013 Wingpanel Developers
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

namespace Wingpanel.Services {
    struct ColorInformation
    {
        double average_red;
        double average_green;
        double average_blue;
        double mean;
        double variance;
    }

    [DBus (name = "org.pantheon.gala")]
    interface GalaDBus : Object {
        public signal void background_changed ();
        public async abstract ColorInformation get_background_color_information (int monitor,
            int x, int y, int width, int height) throws IOError;
    }

    public class BackgroundManager : Object {
        public static const double MIN_ALPHA = 0.7;

        const int HEIGHT = 50;
        const double MIN_VARIANCE = 50;
        const double MIN_LUM = 25;

        /**
         * Emitted when the background changed. It supplies the alpha value that
         * can be used with this wallpaper while maintining legibility
         */
        public signal void update_background_alpha (double legible_alpha_value);
        
        public Services.Settings settings { get; construct set; }
        public Gdk.Screen screen { get; construct set; }

        GalaDBus? gala_dbus = null;
        
        public BackgroundManager (Services.Settings settings, Gdk.Screen screen) {
            Object (settings: settings, screen: screen);
        }

        construct {
            try {
                gala_dbus = Bus.get_proxy_sync (BusType.SESSION, "org.pantheon.gala", 
                    "/org/pantheon/gala");

                gala_dbus.background_changed.connect (background_changed);

                background_changed ();
            } catch (Error e) {
                gala_dbus = null;
                warning ("Auto-adjustment of background opacity not available, " +
                    "connecting to gala dbus failed: %s", e.message);
            }
        }

        private void background_changed ()
        {
            if (settings.auto_adjust_alpha) {
                calculate_alpha.begin ((obj, res) => {
                    var alpha = calculate_alpha.end (res);
                    update_background_alpha (alpha);
                });
            }
        }
        
        private async double calculate_alpha () {
            double alpha = 0;
            Gdk.Rectangle monitor_geometry;
            ColorInformation? color_info = null;

            var primary = screen.get_primary_monitor ();
            screen.get_monitor_geometry (primary, out monitor_geometry);

            try {
                color_info = yield gala_dbus.get_background_color_information (
                                           primary,                // monitor index
                                           0,                      // x of reference rect
                                           0,                      // y of rect
                                           monitor_geometry.width, // width of rect
                                           HEIGHT);                // height of rect
            } catch (Error e) {
                warning (e.message);
                alpha = MIN_ALPHA;
            }

            if (color_info != null
                && (color_info.mean > MIN_LUM
                || color_info.variance > MIN_VARIANCE))
                alpha = MIN_ALPHA;
            
            return alpha;
        }
    }
}

// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2011-2012 Wingpanel Developers
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
//

using Gtk;
using Gdk;
using Cairo;

namespace Wingpanel.Widgets {

    public class AppsButton : EventBox {

        private Label app_label;

        construct {

            can_focus = true;
        }

        public AppsButton () {

            app_label = new Label ("<b>%s</b>".printf(_("Applications")));
            app_label.use_markup = true;

            add (Utils.set_padding (app_label, 0, 14, 0, 14));

            /*get_style_context ().add_class ("menubar");*/
            get_style_context ().add_class ("composited-indicator");
            app_label.get_style_context ().add_class ("wingpanel-app-button");

            this.button_press_event.connect (launch_launcher);

            Wingpanel.app.settings.changed.connect(on_settings_update);

            this.show.connect(on_settings_update);
        }

        private void on_settings_update () {
            if (this.visible && !(Wingpanel.app.settings.show_launcher)) {
                this.hide();
            }
            if (!(this.visible) && Wingpanel.app.settings.show_launcher) {
                this.show();
            }
        }

        private bool launch_launcher (Gtk.Widget widget, Gdk.EventButton event) {

            debug ("Starting launcher!");

            var flags = GLib.SpawnFlags.SEARCH_PATH |
                    GLib.SpawnFlags.DO_NOT_REAP_CHILD |
                    GLib.SpawnFlags.STDOUT_TO_DEV_NULL;

            GLib.Pid process_id;
            
            // Parse Arguments
            string[] argvp = null;
            try {
                GLib.Shell.parse_argv (Wingpanel.app.settings.default_launcher, out argvp);
            }
            catch (GLib.ShellError error) {
                warning ("Not passing any args to %s : %s", Wingpanel.app.settings.default_launcher, error.message);
                argvp = {Wingpanel.app.settings.default_launcher, null}; // fix value in case it's corrupted
            }
            // Check if the programm is actually there
            string? launcher = Environment.find_program_in_path (argvp[0]);
            if (launcher != null) {
                // Spawn process asynchronously
                try {
                    GLib.Process.spawn_async (null, argvp, null, flags, null, out process_id);
                }
                catch (GLib.Error err) {
                    warning (err.message);
                    return false;
                }
            } else {
                Granite.Services.System.open_uri ("file:///usr/share/applications");
            }
            
            return true;
        
        }

    }

}

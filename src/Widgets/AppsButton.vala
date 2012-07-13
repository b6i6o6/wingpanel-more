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

namespace Wingpanel.Widgets {

    public class AppsButton : IndicatorButton {

        private bool _active = false;
        public bool active {
            get {
                return _active;
            }
            set {
                _active = value;
                update_state_flags ();
            }
        }

        private Gtk.Label app_label;
        private AppLauncherService? launcher_service = null;

        public AppsButton () {
            this.can_focus = true;

            app_label = new Gtk.Label ("<b>%s</b>".printf (_("Applications")));
            app_label.use_markup = true;
            app_label.get_style_context().add_class (INDICATOR_BUTTON_STYLE_CLASS);

            app_label.halign = Gtk.Align.CENTER;
            app_label.margin_left = app_label.margin_right = 6;
            this.add (app_label);

            this.active = false;

            launcher_service = new AppLauncherService ();
            launcher_service.launcher_state_changed.connect (on_launcher_state_changed);

            this.button_press_event.connect ( () => {
                launcher_service.launch_launcher ();
                return false;
            });
        }

        private void on_launcher_state_changed (bool visible) {
            debug ("Launcher visibility changed to %s", visible.to_string ());
            this.active = visible;
        }

        /**
         * Make sure the menuitem appears to be selected even if the focus moves
         * to the client launcher app being displayed.
         */

        public override void state_flags_changed (Gtk.StateFlags flags) {
            update_state_flags ();
        }

        private void update_state_flags () {
            const Gtk.StateFlags ACTIVE_FLAGS = Gtk.StateFlags.PRELIGHT;

            if (this.active)
                set_state_flags (ACTIVE_FLAGS, true);
            else
                unset_state_flags (ACTIVE_FLAGS);
        }
    }

}
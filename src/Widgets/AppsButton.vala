// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2011 Wingpanel Developers
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

            app_label = new Label (_("<b>Applications</b>"));
            app_label.use_markup = true;

            add (Utils.set_padding (app_label, 0, 14, 0, 14));

            get_style_context ().add_class ("menubar");
            get_style_context ().add_class ("gnome-panel-menu-bar");
            get_style_context ().add_class ("wingpanel-app-button");

        }

    }

}

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
using Granite;

namespace Wingpanel {

    public class WingpanelApp : Granite.Application {

        private Panel panel = null;

        public Settings settings { get; private set; default = null; }
        public CssProvider provider { get; private set; default = null; }

        construct {

            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;
            
            program_name = "Wingpanel";
		    exec_name = "wingpanel";
		    app_copyright = "GPLv3";
		    app_icon = "";
		    app_launcher = "";
            application_id = "net.launchpad.wingpanel";
		    main_url = "https://launchpad.net/wingpanel";
		    bug_url = "https://bugs.launchpad.net/wingpanel";
		    help_url = "https://answers.launchpad.net/wingpanel";
		    translate_url = "https://translations.launchpad.net/wingpanel";

		    about_authors = {"Giulio Collura <random.cpp@gmail.com>"};
		    about_artists = {"Daniel Foré <bunny@go-docky.com>"};

        }

        public WingpanelApp () {

            debug ("In wingpanel");

            settings = new Settings ();
            provider = new CssProvider ();

            try {
                provider.load_from_path (Build.PKGDATADIR + "/style/default.css");
            } catch (Error e) {
                warning ("Error: %s\n", e.message);
            }

            DEBUG = false;

        }

        protected override void activate () {

            debug ("Activating");

            if (get_windows () == null) {
                panel = new Panel (this);
                panel.show_all ();
            } else {
                panel.show_all ();
            }
        
        }

        public static int main (string[] args) {

            return new WingpanelApp ().run (args);

        }

    }

}

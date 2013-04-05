// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2011-2012 Wingpanel Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE.  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program.  If not, see <http://www.gnu.org/licenses/>

  END LICENSE
***/

using Gtk;
using Granite;

namespace Wingpanel {

    public WingpanelApp app;
    
    public class WingpanelApp : Granite.Application {

        private Panel panel = null;

        public Settings settings { get; private set; default = null; }

        construct {
            build_data_dir = Build.DATADIR;
            build_pkg_data_dir = Build.PKGDATADIR;
            build_release_name = Build.RELEASE_NAME;
            build_version = Build.VERSION;
            build_version_info = Build.VERSION_INFO;

            program_name = "Wingpanel";
            exec_name = "wingpanel";
            application_id = "net.launchpad.wingpanel";
        }

        public WingpanelApp () {
            settings = new Settings ();
            DEBUG = false;
        }

        protected override void activate () {
            debug ("Activating");

            if (get_windows () == null)
                panel = new Panel (this);

            panel.show_all ();
        }

        public static int main (string[] args) {
            Wingpanel.app = new WingpanelApp ();
            return Wingpanel.app.run (args);
        }

    }

}

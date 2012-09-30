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

using Granite.Services;

namespace Wingpanel {

    public class Settings : Granite.Services.Settings {

        public string[] blacklist { get; set; }
        public bool show_launcher { get; set; }
        public string default_launcher { get; set; }

        public Settings () {
            base ("org.pantheon.desktop.wingpanel");
        }

    }

}

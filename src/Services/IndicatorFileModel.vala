// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/***
  BEGIN LICENSE

  Copyright (C) 2010-2012 Canonical Ltd
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

  Authored by canonical.com
***/

namespace Wingpanel {

    public class IndicatorsFileModel : Object, IndicatorModel {
        private Gee.HashMap<GLib.Object, string> indicator_map;
        private Gee.ArrayList<GLib.Object> indicator_list;

        private Settings settings;

        public IndicatorsFileModel (Settings settings) {
            this.settings = settings;

            string skip_list;

            indicator_map = new Gee.HashMap<GLib.Object, string> ();
            indicator_list = new Gee.ArrayList<GLib.Object> ();

            // Indicators we don't want to load
            skip_list = Environment.get_variable ("UNITY_PANEL_INDICATORS_SKIP");

            if (skip_list == null)
                skip_list = "";

            if (skip_list == "all") {
                warning ("Skipping all indicator loading");
                return;
            }

            foreach (string blocked_indicator in settings.blacklist) {
                skip_list += "," + blocked_indicator;
                debug ("Blacklisting %s", blocked_indicator);
            }

            debug ("Blacklisted Indicators: %s", skip_list);

            debug ( "Indicatordir: %s", Build.INDICATORDIR);

            var dir = File.new_for_path (Build.INDICATORDIR);

            try {
                var enumerator = dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
                var indicators_to_load = new Gee.ArrayList<string> ();

                FileInfo file_info;

                while ((file_info = enumerator.next_file (null)) != null) {
                    string leaf = file_info.get_name ();

                    if (leaf in skip_list) {
                        warning ("SKIP LOADING: %s", leaf);
                        continue;
                    }

                    if (leaf.has_suffix (".so")) {
                        indicators_to_load.add (leaf);
                        debug ("LOADING: %s", leaf);
                    }
                }

                foreach (string leaf in indicators_to_load)
                    load_indicator (dir.get_path () + "/" + leaf, leaf);
            } catch (Error err) {
                error ("Unable to read indicators: %s\n", err.message);
            }
        }

        public Gee.ArrayList<GLib.Object> get_indicators () {
            return indicator_list;
        }

        public string get_indicator_name (Indicator.Object o) {
            return indicator_map[o];
        }

        private void load_indicator (string filename, string leaf) {
            Indicator.Object o;

            o = new Indicator.Object.from_file (filename);

            if (o is Indicator.Object) {
                this.indicator_map[o] = leaf;
                indicator_list.add (o);
            } else {
                error ("Unable to load %s\n", filename);
            }
        }
    }
}

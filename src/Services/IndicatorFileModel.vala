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

using Gee;

namespace Wingpanel {

    public abstract class IndicatorsModel : GLib.Object {
        public abstract Gee.ArrayList<Indicator.Object> get_indicators ();
        public abstract string get_indicator_name (Indicator.Object o);
    }

    public class IndicatorsFileModel : IndicatorsModel {
        public static HashMap<string, int> indicator_order = null;
        public HashMap<GLib.Object, string> indicator_map;
        public ArrayList<GLib.Object> indicator_list;

        private Settings settings;

        public IndicatorsFileModel (Settings settings) {
            this.settings = settings;

            string skip_list;

            //indicator_map = new Gee.HashMap<Indicator.Object, string> ();
            indicator_map = new Gee.HashMap<GLib.Object, string> ();
            indicator_order = new Gee.HashMap<string, int> ();
            indicator_list = new Gee.ArrayList<GLib.Object> ();

            /* Static order of indicators. We always want the session indicators
             * to be on the far right end of the panel. That is why it the session
             * indicator is the last one set in indicator_order.
             */
            //indicator_order.set ("libappmenu.so", 7);
            indicator_order.set ("libapplication.so", 6);
            indicator_order.set ("libnetworkmenu.so", 5);
            indicator_order.set ("libsoundmenu.so", 4);
            indicator_order.set ("libmessaging.so", 3);
            indicator_order.set ("libpower.so", 2);
            indicator_order.set ("libsession.so", 1);

            /* Indicators we don't want to load */
            skip_list = Environment.get_variable ("UNITY_PANEL_INDICATORS_SKIP");
            if (skip_list == null)
                skip_list = "";

            if (skip_list == "all") {
                log ("wingpanel", LogLevelFlags.LEVEL_WARNING, "Skipping all indicator loading");
                return;
            }

            /* Don't load appmenu-gtk */
            foreach(string blocked_indicator in settings.blacklist) {
                skip_list += "," + blocked_indicator;
                log("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Blacklisting %s", blocked_indicator);
            }

            log ("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Blacklisted Indicators: %s", skip_list);

            /* We need to look for icons in an specific location */
            //Gtk.IconTheme.get_default ().append_search_path (Wingpanel.Config.INDICATORICONSDIR);

            log ("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Indicatordir: %s", Build.INDICATORDIR);
            File dir = File.new_for_path (Build.INDICATORDIR);
            try {
                var e = dir.enumerate_children (FILE_ATTRIBUTE_STANDARD_NAME, 0, null);
                ArrayList<string> sos = new ArrayList<string> ();

                FileInfo file_info;
                while ((file_info = e.next_file (null)) != null) {
                    string leaf = file_info.get_name ();

                    if (leaf in skip_list) {
                        log("wingpanel", LogLevelFlags.LEVEL_WARNING, "SKIP LOADING: %s", leaf);
                        continue;
                    }

                    if (leaf.has_suffix (".so")) {
                        sos.add (leaf);
                        log("wingpanel", LogLevelFlags.LEVEL_DEBUG, "LOADING: %s", leaf);
                    }
                }

                /* Order the so's before we load them */
                sos.sort ((CompareFunc)indicator_sort_func);

                foreach (string leaf in sos) {
                    try {
                        this.load_indicator (dir.get_path() + "/" + leaf, leaf);
                    } catch (Error error) {
                        log("wingpanel", LogLevelFlags.LEVEL_ERROR, "Unable to read indicator \"%s\": %s\n", leaf, error.message);
                    }
                }
            }
            catch (Error error) {
                log("wingpanel",LogLevelFlags.LEVEL_ERROR, "Unable to read indicators: %s\n", error.message);
            }
        }

        public static int indicator_sort_func (string a, string b) {
            return indicator_order[a] - indicator_order[b];
        }

        private void load_indicator (string filename, string leaf) {
            Indicator.Object o;

            o = new Indicator.Object.from_file (filename);

            if (o is Indicator.Object) {
                this.indicator_map[o] = leaf;
                indicator_list.add (o);
            } else {
                log("wingpanel", LogLevelFlags.LEVEL_ERROR, "Unable to load %s\n", filename);
            }
        }

        //public override ArrayList<Indicator.Object> get_indicators ()
        public override ArrayList<GLib.Object> get_indicators () {
            return indicator_list;
        }

        public override string get_indicator_name (Indicator.Object o) {
            return indicator_map[o];
        }
    }
}

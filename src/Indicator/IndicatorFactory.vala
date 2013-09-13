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

public class Wingpanel.Backend.IndicatorFactory : Object, IndicatorLoader {
    private const string NG_INDICATOR_FILE_DIR = "/usr/share/unity/indicators";
    private Gee.Collection<IndicatorIface> indicators;
    private string[] settings_blacklist;

    public IndicatorFactory (string[] settings_blacklist) {
        this.settings_blacklist = settings_blacklist;
    }

    public Gee.Collection<IndicatorIface> get_indicators () {
        if (indicators == null) {
            indicators = new Gee.LinkedList<IndicatorIface> ();
            load_indicators ();
        }

        return indicators.read_only_view;
    }

    private void load_indicators () {
        // Indicators we don't want to load
        string skip_list = Environment.get_variable ("UNITY_PANEL_INDICATORS_SKIP") ?? "";

        if (skip_list == "all") {
            warning ("Skipping all indicator loading");
            return;
        }

        foreach (string blocked_indicator in settings_blacklist)
            skip_list += "," + blocked_indicator;

        debug ("Blacklisted Indicators: %s", skip_list);

        // Legacy indicator libraries
        var legacy_indicator_dir = File.new_for_path (Build.INDICATORDIR);
        load_indicators_from_directory (legacy_indicator_dir, true, skip_list);

        // Ng indicators
        var ng_indicator_dir = File.new_for_path (NG_INDICATOR_FILE_DIR);
        load_indicators_from_directory (ng_indicator_dir, false, skip_list);
    }

    private void load_indicators_from_directory (File dir, bool legacy_libs_only, string skip_list) {
        try {
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME,
                                                     FileQueryInfoFlags.NONE, null);
            FileInfo file_info;
            while ((file_info = enumerator.next_file (null)) != null) {
                Indicator.Object indicator = null;
                string name = file_info.get_name ();

                if (name in skip_list)
                    continue;

                if (legacy_libs_only) {
                    if (!name.has_suffix (".so"))
                        continue;

                    debug ("Loading Indicator Library: %s", name);
                    indicator = new Indicator.Object.from_file (dir.get_child (name).get_path ());
                } else {
                    debug ("Loading Indicator File: %s", name);
                    indicator = new Indicator.Ng.for_profile (dir.get_child (name).get_path (), "desktop");
                }

                if (indicator != null)
                    indicators.add (new IndicatorObject (indicator, name));
                else
                    critical ("Unable to load %s: invalid object.", name);
            }
        } catch (Error err) {
            warning ("Unable to read indicators: %s", err.message);
        }
    }
}

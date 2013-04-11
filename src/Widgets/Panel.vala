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

namespace Wingpanel {

    public class Panel : BasePanel {
        private Gtk.Box container;
        private Gtk.Box left_wrapper;
        private Gtk.Box right_wrapper;

        private IndicatorMenubar menubar;
        private MenuBar clock;
        private MenuBar apps_menubar;

        private IndicatorFactory indicator_factory;

        public Panel (WingpanelApp app, Settings settings, IndicatorFactory indicator_factory) {
            set_application (app as Gtk.Application);

            this.indicator_factory = indicator_factory;

            container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            left_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            right_wrapper = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            container.set_homogeneous (false);
            left_wrapper.set_homogeneous (false);
            right_wrapper.set_homogeneous (false);

            add (container);

            var style_context = get_style_context ();
            style_context.add_class (StyleClass.PANEL);
            style_context.add_class (Gtk.STYLE_CLASS_MENUBAR);

            // Add default widgets
            add_defaults (settings);

            load_indicators ();
        }

        private void load_indicators () {
            var indicators = indicator_factory.get_indicators ();

            foreach (var indicator in indicators)
                load_indicator (indicator);
        }

        private void load_indicator (IndicatorIface indicator) {
            var entries = indicator.get_entries ();

            foreach (var entry in entries)
                create_entry (entry);

            indicator.entry_added.connect (create_entry);
            indicator.entry_removed.connect (delete_entry);
        }

        private void create_entry (IndicatorWidget entry) {
            if (entry.get_indicator ().get_name () == "libdatetime.so")
                clock.prepend (entry);
            else
                menubar.insert_sorted (entry);
        }

        private void delete_entry (IndicatorWidget entry) {
            var parent = entry.parent;
            parent.remove (entry);
        }

        private void add_defaults (Settings settings) {
            // Add Apps button
            apps_menubar = new MenuBar ();
            var apps_button = new Widgets.AppsButton (settings);
            apps_menubar.append (apps_button);

            left_wrapper.pack_start (apps_menubar, false, true, 0);

            container.pack_start (left_wrapper);

            clock = new MenuBar ();
            container.pack_start (clock, false, false, 0);

            // Menubar for storing indicators
            menubar = new IndicatorMenubar ();

            right_wrapper.pack_end (menubar, false, false, 0);
            container.pack_end (right_wrapper);

            var gpr = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            gpr.add_widget (left_wrapper);
            gpr.add_widget (right_wrapper);
        }
    }
}

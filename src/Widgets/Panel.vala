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

        private IndicatorModel indicator_model;
        private Gee.HashMap<string, Gtk.MenuItem> menuhash;

        private WingpanelApp app;
        private Settings settings;

        public Panel (WingpanelApp app) {
            this.app = app;
            settings = app.settings;
            indicator_model = app.indicator_model;

            set_application (app as Gtk.Application);

            menuhash = new Gee.HashMap<string, Gtk.MenuItem> ();

            // HBox container
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
            add_defaults ();

            var indicators_list = indicator_model.get_indicators ();

            foreach (Indicator.Object o in indicators_list)
                 load_indicator (o);
        }

        private void create_entry (Indicator.ObjectEntry entry, Indicator.Object object) {
            // delete_entry (entry, object);
            IndicatorWidget menuitem = new IndicatorObjectEntry (indicator_model, entry, object);

            string indicator_name = menuitem.get_indicator_name ();
            menuhash.set (indicator_name, menuitem);

            if (indicator_name == "libdatetime.so") // load libdatetime in center
                clock.prepend (menuitem);
            else
                menubar.insert_sorted (menuitem);
        }

        private void delete_entry (Indicator.ObjectEntry entry, Indicator.Object object) {
            if (menuhash.has_key(indicator_model.get_indicator_name (object))) {
                /* FIXME: some indicators like libapplication.so can have multiple entries
                 * (i.e. menuitems). This code assumes that there's only one entry per
                 * indicator. That's what entry is for, and it is passed along to the callback.
                 */
                var menuitem = menuhash[indicator_model.get_indicator_name (object)];
                this.menubar.remove (menuitem);
            }
        }

        private void on_entry_added (Indicator.Object object, Indicator.ObjectEntry entry) {
            create_entry (entry, object);
        }

        private void on_entry_removed (Indicator.Object object, Indicator.ObjectEntry entry) {
            delete_entry (entry, object);
        }

        public void load_indicator (Indicator.Object indicator) {
            if (indicator is Indicator.Object) {
                indicator.entry_added.connect (on_entry_added);
                indicator.entry_removed.connect (on_entry_removed);
                indicator.ref();

                GLib.List<unowned Indicator.ObjectEntry> list = indicator.get_entries ();
                list.foreach ((entry) => create_entry (entry, indicator));

                message ("Loaded indicator %s", indicator_model.get_indicator_name (indicator));
            } else {
                warning ("Unable to load %s", indicator_model.get_indicator_name (indicator));
            }
        }

        private void add_defaults () {
            // Add Apps button
            apps_menubar = new MenuBar ();
            apps_menubar.append (new Widgets.AppsButton (settings));

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

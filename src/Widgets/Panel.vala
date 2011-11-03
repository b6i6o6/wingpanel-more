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

namespace Wingpanel {

    public enum Struts {
        LEFT,
        RIGHT,
        TOP,
        BOTTOM,
        LEFT_START,
        LEFT_END,
        RIGHT_START,
        RIGHT_END,
        TOP_START,
        TOP_END,
        BOTTOM_START,
        BOTTOM_END,
        N_VALUES
    }

    private class Shadow : Granite.Widgets.CompositedWindow {

        private MenuBar menubar;

        public Shadow () {

            menubar = new MenuBar ();

            skip_taskbar_hint = true; // no taskbar
            height_request = 24;
            menubar.get_style_context ().add_class ("shadow");
            set_type_hint (WindowTypeHint.DESKTOP);

        }

        protected override bool draw (Context cr) {

            Allocation size;
            get_allocation (out size);
            
            int border = 0;

            var ctx = menubar.get_style_context ();
            render_background (ctx, cr,
                               size.x - border, size.y - border, 
                               size.width + 2 * border, size.height + 2 * border);

            return true;

        }

    }

    public class Panel : Gtk.Window {

        public const int panel_height = 24;
        public const int stroke_width = 0;
        public uint animation_timer = 0;
        public int panel_displacement = -panel_height;

        private HBox container;
        private HBox left_wrapper;
        private HBox right_wrapper;
        private MenuBar menubar;
        private MenuBar clock;

        private Shadow shadow;

        private IndicatorsModel model;
        private Gee.HashMap<string, Gtk.MenuItem> menuhash;
        private Gdk.Rectangle monitor_dimensions;

        private WingpanelApp app;

        public Panel (WingpanelApp app) {

            this.app = app;
            set_application (app as Gtk.Application);

            //Window properties
            skip_taskbar_hint = true; // no taskbar
            decorated = false; // no window decoration
            app_paintable = true;
            set_visual (get_screen ().get_rgba_visual ());

            shadow = new Shadow ();
            shadow.move (0, panel_height);

            panel_resize (false);
            /* update the panel size on screen size or monitor changes */
            screen.size_changed.connect (() => {
                panel_resize (true);
            });
            screen.monitors_changed.connect (() => {
                panel_resize (true);
            });

            menuhash = new Gee.HashMap<string, Gtk.MenuItem> ();

            // Window properties
            set_type_hint (WindowTypeHint.DOCK);
            move (0, panel_displacement);
            get_style_context ().add_provider_for_screen (get_screen (), app.provider, 600);

            // HBox container
            container = new HBox (false, 0);
            left_wrapper = new HBox (false, 0);
            right_wrapper = new HBox (false, 0);
            resizable = false;

            add (container);

            // Add default widgets
            add_defaults ();

            model = IndicatorsModel.get_default ();
            var indicators_list = model.get_indicators ();

            foreach (Indicator.Object o in indicators_list) {
                 load_indicator (o);
            }

            // Signals
            realize.connect (() => { set_struts ();});
            destroy.connect (Gtk.main_quit);


        }

        private void panel_resize (bool redraw)  {

            screen.get_monitor_geometry (this.screen.get_primary_monitor(), out this.monitor_dimensions);
            set_size_request (monitor_dimensions.width, -1);
            shadow.set_size_request (monitor_dimensions.width, 24);

            set_struts ();
            if (redraw)
                queue_draw ();
        }

        private void create_entry (Indicator.ObjectEntry entry,
                                   Indicator.Object      object) {

            //delete_entry(entry, object);
            Gtk.MenuItem menuitem = new IndicatorObjectEntry (entry, object);
            menuhash[model.get_indicator_name(object)] = menuitem;

            if (model.get_indicator_name(object) == "libdatetime.so") { // load libdatetime in center
                /* Bold clock label font */
                var font = new Pango.FontDescription ();
                font.set_weight (Pango.Weight.HEAVY);
                var box = menuitem.get_child () as Gtk.Container;
                box.get_children ().nth_data (0).modify_font (font);
                clock.prepend(menuitem);
            } else {
                menubar.prepend (menuitem);
            }
        
        }

        private void delete_entry (Indicator.ObjectEntry entry,
                                   Indicator.Object     object) {

            if (menuhash.has_key(model.get_indicator_name(object))) {

                var menuitem = menuhash[model.get_indicator_name(object)];
                this.menubar.remove (menuitem);

            }
        }

        private void on_entry_added (Indicator.Object      object,
                                     Indicator.ObjectEntry entry) {

            create_entry (entry, object);
        }

        private void on_entry_removed (Indicator.Object      object,
                                      Indicator.ObjectEntry entry) {

            delete_entry (entry, object);
        }

        public void load_indicator (Indicator.Object indicator) {

            if (indicator is Indicator.Object) {
                indicator.entry_added.connect (this.on_entry_added);
                indicator.entry_removed.connect (this.on_entry_removed);
                indicator.ref();

                unowned GLib.List<Indicator.ObjectEntry> list = indicator.get_entries ();

                for (int i = 0; i < list.length (); i++) {
                    unowned Indicator.ObjectEntry entry = (Indicator.ObjectEntry) list.nth_data (i);
                    this.create_entry (entry, indicator);
                }
                message ("Loaded indicator %s\n", model.get_indicator_name(indicator));
            } else {
                //Log.printf(Log.Level.ERROR, "Unable to load %s\n", model.get_indicator_name(indicator));
            }
        }

        private void add_defaults () {

            // Apps button
            var apps = new Widgets.AppsButton ();
            apps.button_press_event.connect (launch_launcher);

            left_wrapper.pack_start (apps, false, true, 0);
            container.pack_start (left_wrapper);

            clock = new Gtk.MenuBar ();
            clock.can_focus = true;
            clock.border_width = 0;
            clock.get_style_context ().add_class ("gnome-panel-menu-bar");
            container.pack_start (clock, false, false, 0);

            // Menubar for storing indicators
            menubar = new Gtk.MenuBar ();
            menubar.can_focus = true;
            menubar.border_width = 0;
            menubar.get_style_context ().add_class ("gnome-panel-menu-bar");
            
            right_wrapper.pack_end (menubar, false, false, 0);
            container.pack_end (right_wrapper);

            get_style_context ().add_class ("menubar");
            get_style_context ().add_class ("gnome-panel-menu-bar");
            
            SizeGroup gpr = new SizeGroup (SizeGroupMode.HORIZONTAL);
            gpr.add_widget (left_wrapper);
            gpr.add_widget (right_wrapper);

        }

        private bool launch_launcher (Gtk.Widget widget, Gdk.EventButton event) {

            debug ("Starting launcher!");
            try {
                string? launcher = Environment.find_program_in_path (app.settings.default_launcher);
                if (launcher != null)
                    GLib.Process.spawn_command_line_async (launcher);
            } catch {
                try {
                    Gtk.show_uri (get_screen (), "file:///usr/share/applications",
                                 Gtk.get_current_event_time ());
                } catch {
                    warning ("Failed to open launcher");
                }
            }
            return true;
        }

        protected override bool draw (Context cr) {

            Allocation size;
            get_allocation (out size);

            int border = 0;
            var ctx = menubar.get_style_context ();
            render_background (ctx, cr,
                               size.x - border, size.y - border, 
                               size.width + 2 * border, size.height + 2 * border);

            // Slide in
            if (animation_timer == 0) {
                animation_timer = GLib.Timeout.add (250/panel_height, () => {
                    if (panel_displacement >= 0 ) {
                        shadow.show_all ();
                        return false;
                    } else {
                        panel_displacement += 1;
                        move (0, panel_displacement);
                        return true;
                    }
                });
            }
            propagate_draw (container, cr);

            return true;
        }

        private void set_struts () {

            if (!get_realized ()) {
                return;
            }

            int x, y;
            this.get_position (out x, out y);

            // since uchar is 8 bits in vala but the struts are 32 bits
            // we have to allocate 4 times as much and do bit-masking
            ulong[] struts = new ulong [Struts.N_VALUES];

            struts [Struts.TOP] = this.panel_height;
            struts [Struts.TOP_START] = monitor_dimensions.x;
            struts [Struts.TOP_END] = monitor_dimensions.x + monitor_dimensions.width - 1;

            var first_struts = new ulong [Struts.BOTTOM + 1];
            for (var i = 0; i < first_struts.length; i++)
                first_struts [i] = struts [i];

            //amtest
            //var display = x11_drawable_get_xdisplay (get_window ());
            unowned X.Display display = X11Display.get_xdisplay (get_window ().get_display ());
            //var xid = x11_drawable_get_xid (get_window ());
            var xid = X11Window.get_xid (get_window ());
            //var xid = get_xid (get_window ());

            display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
                                  32, X.PropMode.Replace, (uchar[])struts, struts.length);
            display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL,
                                  32, X.PropMode.Replace, (uchar[])first_struts, first_struts.length);
        }
    }
}

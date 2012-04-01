// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2011-2012 Wingpanel Developers
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

using Granite;
using Granite.Services;

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
            //skip_pager_hint = true;
            menubar.get_style_context ().add_class ("shadow");
            set_type_hint (WindowTypeHint.DROPDOWN_MENU);
            set_keep_below (true);
            stick ();

        }

        protected override bool draw (Context cr) {

            Allocation size;
            get_allocation (out size);
            
            var ctx = menubar.get_style_context ();
            render_background (ctx, cr, size.x, size.y, 
                               size.width, size.height);

            return true;

        }

    }

    public class Panel : Gtk.Window {
        private const int shadow_size = 4;

        private int panel_height = 24;
        private int panel_x;
        private int panel_y;
        private int panel_width;
        private uint animation_timer = 0;
        private int panel_displacement = -40;

        private HBox container;
        private HBox left_wrapper;
        private HBox right_wrapper;
        private MenuBar menubar;
        private MenuBar clock;

        private Shadow shadow;
        private IndicatorsModel model;
        private Gee.HashMap<string, Gtk.MenuItem> menuhash;

        private WingpanelApp app;

        public Panel (WingpanelApp app) {
            //TODO: Clean Up Code and add the this reference where used
            this.app = app;
            set_application (app as Gtk.Application);

            //Window properties
            skip_taskbar_hint = true; // no taskbar
            decorated = false; // no window decoration
            app_paintable = true;
            set_visual (get_screen ().get_rgba_visual ());
            set_type_hint (WindowTypeHint.DOCK);
            get_style_context ().add_provider_for_screen (this.get_screen (), app.provider, 600);

            shadow = new Shadow ();

            panel_resize (false);
            /* update the panel size on screen size or monitor changes */
            screen.size_changed.connect (() => {
                panel_resize (true);
            });
            screen.monitors_changed.connect (() => {
                panel_resize (true);
            });

            menuhash = new Gee.HashMap<string, Gtk.MenuItem> ();

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
            realize.connect (() => { panel_resize(false);});
            destroy.connect (Gtk.main_quit);

        }

        private void panel_resize (bool redraw)  {

            Gdk.Rectangle monitor_dimensions;

            screen.get_monitor_geometry (this.screen.get_primary_monitor(), out monitor_dimensions);
            
            this.panel_x     = monitor_dimensions.x;
            this.panel_y     = monitor_dimensions.y;
            this.panel_width = monitor_dimensions.width;

            this.move (panel_x, panel_y + panel_displacement);
            shadow.move (panel_x, panel_y + panel_height + panel_displacement);

            this.set_size_request (this.panel_width, -1);
            shadow.set_size_request (this.panel_width, this.shadow_size);

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
                message ("Loaded indicator %s", model.get_indicator_name(indicator));
            } else {
                warning ("Unable to load %s", model.get_indicator_name(indicator));
            }
        }

        private void add_defaults () {

            // Only show Apps button if enabled in the settings
            if(this.app.settings.show_launcher) {
                var apps = new Widgets.AppsButton ();
                apps.button_press_event.connect (launch_launcher);

                left_wrapper.pack_start (apps, false, true, 0);
            }
            container.pack_start (left_wrapper);

            clock = new Gtk.MenuBar ();
            clock.can_focus = true;
            clock.border_width = 0;
            clock.get_style_context ().add_class ("composited-indicator");
            container.pack_start (clock, false, false, 0);

            // Menubar for storing indicators
            menubar = new Gtk.MenuBar ();
            menubar.can_focus = true;
            menubar.border_width = 0;
            menubar.get_style_context ().add_class ("composited-indicator");
            
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
        
            string? launcher = Environment.find_program_in_path (app.settings.default_launcher);
            if (launcher != null)
                System.execute_command (launcher);
            else
                System.open_uri ("file:///usr/share/applications");

            return true;
        
        }

        protected override bool draw (Context cr) {

            Allocation size;
            this.get_allocation (out size);

            if(this.panel_height != size.height) {
                this.panel_height = size.height;
                warning("Panel Height: "+size.height.to_string());
                shadow.move (this.panel_x, this.panel_y + this.panel_height + this.panel_displacement);
                set_struts();
            }

            var ctx = menubar.get_style_context ();
            render_background (ctx, cr, size.x, size.y, 
                               size.width, size.height);

            // Slide in
            if (animation_timer == 0) {
                this.panel_displacement = -this.panel_height;

                animation_timer = GLib.Timeout.add (300/this.panel_height, () => {
                    if (this.panel_displacement >= 0 ) {
                        return false;
                    } else {
                        this.panel_displacement += 1;
                        this.move (this.panel_x, this.panel_y + this.panel_displacement);
                        shadow.move (this.panel_x, this.panel_y + this.panel_height + this.panel_displacement);
                        return true;
                    }
                });
            }
            propagate_draw (container, cr);

            if (!shadow.visible)
                shadow.show_all ();

            return true;
        }

        private void set_struts () {

            if (!get_realized()) {
                return;
            }

            // since uchar is 8 bits in vala but the struts are 32 bits
            // we have to allocate 4 times as much and do bit-masking
            var struts = new ulong [Struts.N_VALUES];

            struts [Struts.TOP]         = this.panel_height + this.panel_y;
            struts [Struts.TOP_START]   = this.panel_x;
            struts [Struts.TOP_END]     = this.panel_x + this.panel_width;

            var first_struts = new ulong [Struts.BOTTOM + 1];
            for (var i = 0; i < first_struts.length; i++) {
                first_struts [i] = struts [i];
            }

            unowned X.Display display = X11Display.get_xdisplay(get_display());
            var xid = X11Window.get_xid(get_window());

            display.change_property (xid, display.intern_atom ("_NET_WM_STRUT_PARTIAL", false), X.XA_CARDINAL,
                                  32, X.PropMode.Replace, (uchar[]) struts, struts.length);
            display.change_property (xid, display.intern_atom ("_NET_WM_STRUT", false), X.XA_CARDINAL,
                                  32, X.PropMode.Replace, (uchar[]) first_struts, first_struts.length);
        }
    }
}

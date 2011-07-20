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

    public static WingpanelApp app;

    public class WingpanelApp : Gtk.Application {

        public Gtk.CssProvider provider = null;
        public bool use_gtk_theme = false;
        private GLib.Settings settings;
        private Panel panel;

        construct {
            application_id = "org.elementary.Wingpanel";
            flags = GLib.ApplicationFlags.IS_SERVICE;
        }

        protected override void startup () 
        {
            log("wingpanel", LogLevelFlags.LEVEL_INFO, "Welcome to Wingpanel");
            log("wingpanel", LogLevelFlags.LEVEL_INFO, "Version: %s", "0.1");
            log("wingpanel", LogLevelFlags.LEVEL_INFO, "Report any issues/bugs you might find to lp:wingpanel");
            settings = new GLib.Settings ("desktop.pantheon.wingpanel");
            use_gtk_theme = settings.get_boolean ("use-gtk-theme");
            settings.changed.connect (key_changed);

            define_style ();
            panel = new Panel ();
            panel.show_all ();

            Gtk.main ();
        }

        private void define_style () {
            provider = new Gtk.CssProvider();
            
            try {
                if (!use_gtk_theme)
                    provider.load_from_path(Build.PKGDATADIR + "/wingpanel-hud-style.css");
                else
                    provider.load_from_path(Build.PKGDATADIR + "/gtk-theme-style.css");
            } catch (Error e) {
                stderr.printf("Error: %s\n", e.message);
            }
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(),
                                                     provider, 600);
        }

        private void key_changed (string key) {
            if (key == "use-gtk-theme") {
                use_gtk_theme = settings.get_boolean ("use-gtk-theme");
                if (provider != null)
                    Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default(), provider);
                define_style ();
                panel.update_use_gtk_theme ();
            }
        }

    }

    //public class Panel : ElementaryWidgets.CompositedWindow {
    public class Panel : Gtk.Window {

        public const int panel_height = 24;
        public const int stroke_width = 4;
        public uint animation_timer = 0;
        public int panel_displacement = (-1) * panel_height;

        private Gtk.HBox container;
        private Gtk.HBox left_wrapper;
        private Gtk.HBox right_wrapper;
        private Gtk.MenuBar menubar;
        private Gtk.MenuBar clock;

        private Gtk.StyleContext ctx_apps_label;
        private Gtk.StyleContext ctx_clock;
        private Gtk.StyleContext ctx_menubar;

        private IndicatorsModel model;
        private Gee.HashMap<string, Gtk.MenuItem> menuhash;
        private Cardapio.dbus cardapio;
        private Gdk.Rectangle monitor_dimensions;

        public Panel () {
            //Window properties
            skip_taskbar_hint = true; // no taskbar
            decorated = false; // no window decoration
            app_paintable = true;

            if (!app.use_gtk_theme)
                set_visual (screen.get_rgba_visual());
            //set_opacity (0.8);

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
            set_type_hint (Gdk.WindowTypeHint.DOCK);
            move (0, panel_displacement);

            // HBox container
            container = new Gtk.HBox(false, 0);
            left_wrapper = new Gtk.HBox(false, 0);
            right_wrapper = new Gtk.HBox(false, 0);
            resizable = false;

            add (container);

            // Add default widgets
            add_defaults();

            model = IndicatorsModel.get_default ();
            var indicators_list = model.get_indicators ();

            foreach (Indicator.Object o in indicators_list)
            {
                 load_indicator(o);
            }

            // Signals
            realize.connect (() => { set_struts();});
            destroy.connect (Gtk.main_quit);

            //Check if Carpadio is installed
            try {
                cardapio = Bus.get_proxy_sync (BusType.SESSION, "org.varal.Cardapio",
                                                  "/org/varal/Cardapio");
            //} catch (IOError e) {
            //    GLib.log("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Error connecting to Cardapio!");
            } catch {
                GLib.log("wingpanel", LogLevelFlags.LEVEL_CRITICAL, "Cardapio not installed!");
            }
        }

        private void panel_resize (bool redraw) 
        {
                screen.get_monitor_geometry(this.screen.get_primary_monitor(), out this.monitor_dimensions);
                set_size_request (monitor_dimensions.width, -1);
                set_struts ();
                if (redraw)
                    queue_draw ();
        }

        private void create_entry (Indicator.ObjectEntry entry,
                                   Indicator.Object      object)
        {
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

        private void delete_entry(Indicator.ObjectEntry entry,
                                   Indicator.Object     object)
        {
            if (menuhash.has_key(model.get_indicator_name(object)))
            {
                var menuitem = menuhash[model.get_indicator_name(object)];
                this.menubar.remove (menuitem);
            }
        }

        private void on_entry_added (Indicator.Object      object,
                                     Indicator.ObjectEntry entry)
        {
            create_entry (entry, object);
        }

        private void on_entry_removed(Indicator.Object      object,
                                      Indicator.ObjectEntry entry)
        {
            delete_entry(entry, object);
        }

        public void load_indicator(Indicator.Object indicator) {
            if (indicator is Indicator.Object)
            {
                indicator.entry_added.connect (this.on_entry_added);
                indicator.entry_removed.connect (this.on_entry_removed);
                indicator.ref();

                unowned GLib.List<Indicator.ObjectEntry> list = indicator.get_entries ();

                for (int i = 0; i < list.length (); i++)
                {
                    unowned Indicator.ObjectEntry entry = (Indicator.ObjectEntry) list.nth_data (i);
                    this.create_entry (entry, indicator);
                }
                stdout.printf("Loaded indicator %s\n", model.get_indicator_name(indicator));
            } else {
                //Log.printf(Log.Level.ERROR, "Unable to load %s\n", model.get_indicator_name(indicator));
            }
        }

        private void add_defaults() {
            // Apps button
            var apps = new Gtk.EventBox();
            apps.set_visible_window (false);
            var apps_label = new Gtk.Label("<span weight='heavy' size='9500'>Apps</span>");
            
            ctx_apps_label = apps_label.get_style_context ();
            ctx_apps_label.add_class ("gnome-panel-menu-bar");
            /* FIXME:Ambiance got a missing context (missing text color), 
               we have to fallback to menubar */
            ctx_apps_label.add_class ("menubar");
            if (app.use_gtk_theme)
                ctx_apps_label.add_class ("gnome-panel-menu-bar");
            ctx_apps_label.add_class ("wingpanel-menubar");

            apps_label.use_markup = true;
            apps.add(apps_label);
            apps.button_press_event.connect(launch_launcher);

            left_wrapper.pack_start(apps, false, true, 5);
            container.pack_start(left_wrapper);

            clock = new Gtk.MenuBar ();
            clock.can_focus = true;
            clock.border_width = 0;
            ctx_clock = clock.get_style_context ();
            if (app.use_gtk_theme)
                ctx_clock.add_class ("gnome-panel-menu-bar");
            ctx_clock.add_class ("wingpanel-menubar");
            container.pack_start(clock, false, false, 0);

            // Menubar for storing indicators
            menubar = new Gtk.MenuBar ();
            menubar.can_focus = true;
            menubar.border_width = 0;
            //menubar.set_name ("indicator-applet-menubar");
            ctx_menubar = menubar.get_style_context ();
            if (app.use_gtk_theme)
               ctx_menubar.add_class ("gnome-panel-menu-bar");
            ctx_menubar.add_class ("wingpanel-menubar");
            
            get_style_context ().add_class ("wingpanel-menubar");

            right_wrapper.pack_end(menubar, false, false, 0);
            container.pack_start(right_wrapper);
            
            SizeGroup gpr = new SizeGroup(SizeGroupMode.HORIZONTAL);
            gpr.add_widget (left_wrapper);
            gpr.add_widget (right_wrapper);

        }

        public void update_use_gtk_theme () {
            /* Add and remove class styles */
            if (!app.use_gtk_theme) {
                set_visual (screen.get_rgba_visual());
                ctx_apps_label.remove_class ("gnome-panel-menu-bar");
                ctx_clock.remove_class ("gnome-panel-menu-bar");
                ctx_menubar.remove_class ("gnome-panel-menu-bar");
            } else {
                set_visual (null);
                ctx_apps_label.add_class ("gnome-panel-menu-bar");
                ctx_clock.add_class ("gnome-panel-menu-bar");
                ctx_menubar.add_class ("gnome-panel-menu-bar");
            }
                
            /* make sure to remove the style before readding it, order matter */
            ctx_apps_label.remove_class ("wingpanel-menubar");
            ctx_clock.remove_class ("wingpanel-menubar");
            ctx_menubar.remove_class ("wingpanel-menubar");
            
            ctx_apps_label.add_class ("wingpanel-menubar");
            ctx_clock.add_class ("wingpanel-menubar");
            ctx_menubar.add_class ("wingpanel-menubar");
                
            clock.reset_style ();
            menubar.reset_style ();
        }

        private bool launch_launcher(Gtk.Widget widget, Gdk.EventButton event) {
            GLib.log("wingpanel",LogLevelFlags.LEVEL_DEBUG, "Starting launcher!");
            try {
                string? slingshot = Environment.find_program_in_path("slingshot");
                if (slingshot != null)
                    GLib.Process.spawn_command_line_async(slingshot);
                else
                    cardapio.show_hide_near_point(0,0,false,false);
            } catch {
                try {
                    Gtk.show_uri(get_screen (), "file:///usr/share/applications",
                                 Gtk.get_current_event_time ());
                } catch {
                    GLib.critical("Failed to open launcher");
                }
            }
            return true;
        }

        protected override bool draw (Context cr) {

            Gtk.Allocation size;
            get_allocation(out size);

            // Draw shadow
            /*var linear_shadow = new Cairo.Pattern.linear(size.x, size.y + this.panel_height, size.x, size.y + this.panel_height + this.stroke_width);
            linear_shadow.add_color_stop_rgba(0.0,  0.0, 0.0, 0.0, 0.4);
            linear_shadow.add_color_stop_rgba(0.8,  0.0, 0.0, 0.0, 0.1);
            linear_shadow.add_color_stop_rgba(1.0,  0.0, 0.0, 0.0, 0.0);
            context.set_source(linear_shadow);
            context.fill();*/

            if (app.use_gtk_theme) {
                int border = 0;
                var ctx = menubar.get_style_context ();
                render_background (ctx, cr,
                                   size.x - border, size.y - border, 
                                   size.width + 2 * border, size.height + 2 * border);
            }

            // Slide in
            if (animation_timer == 0) {
                animation_timer = GLib.Timeout.add (250/panel_height, () => {
                    if (panel_displacement >= 0 ) {
                           return false;
                    } else {
                        panel_displacement += 1;
                        move(0, panel_displacement);
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

    static int main (string[] args) {
        GLib.Log.set_default_handler(Log.log_handler);

        Gtk.init (ref args);

        app = new WingpanelApp ();
        app.run (args);

        return 0;
    }
}


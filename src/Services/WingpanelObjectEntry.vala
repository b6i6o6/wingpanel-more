using Gdk;

namespace  Wingpanel 
{
    public class IndicatorObjectEntry: Gtk.MenuItem
    {
        Indicator.Object object;
        unowned Indicator.ObjectEntry entry;

        public IndicatorObjectEntry (Indicator.ObjectEntry entry, Indicator.Object iobject)
        {
            object = iobject;
            this.entry = entry;
            
            IndicatorsModel model = IndicatorsModel.get_default ();

            Gtk.HBox box = new Gtk.HBox (false, 0);
            box.spacing = 2;
            if (entry.image != null && entry.image is Gtk.Image) {
                GLib.log("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Indicator: %s has attribute image", model.get_indicator_name(object));
                box.pack_start (entry.image, false, false, 0);
            }
            if (entry.label != null && entry.label is Gtk.Label) {
                GLib.log("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Indicator: %s has attribute label", model.get_indicator_name(object));
                box.pack_end (entry.label, false, false, 0);
		entry.label.get_style_context().add_class("wingpanel-indicator-button");
            }
            add (box);
            box.show ();
            
            
            if (entry.menu != null)
                set_submenu (entry.menu);
            show ();
            scroll_event.connect (on_scroll_event);
            
            /**/
            var buffer = new Granite.Drawing.BufferSurface (100, 100);
            
            entry.menu.get_parent ().app_paintable = true;
            entry.menu.get_parent ().set_visual (Gdk.Screen.get_default ().get_rgba_visual ());
            
            var w = -1; var h = -1;
            var arrow_height = 10; var arrow_width = 20;var x = 10.5;var y = 10.5; var radius = 5;
            entry.menu.get_parent ().size_allocate.connect ( (ctx) => {
                if (w == this.get_parent ().get_allocated_width () && 
                    h == this.get_parent ().get_allocated_height ())
                    return;
                
                w  = entry.menu.get_parent ().get_allocated_width ();
                h = entry.menu.get_parent ().get_allocated_height ();
                
                buffer = new Granite.Drawing.BufferSurface (w, h);
                
                Granite.Drawing.Utilities.cairo_rounded_rectangle (buffer.context, x, y + arrow_height,
                                                                   w-20, h - 20 - arrow_height, radius);
                
                //get some nice pos for the arrow
                var list = (this.get_parent () as Gtk.Container).get_children ();
                list.reverse ();
                var i = list.index (this);
                var offs = (w-50)-i*22;
                if (offs < arrow_width || list.length () < 2) offs = 60;
                
                // Draw arrow
                buffer.context.move_to (offs, y + arrow_height);
                buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
                buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
                buffer.context.close_path ();
                
                buffer.context.set_source_rgba (0, 0, 0, 0.5);
                buffer.context.fill_preserve ();
                buffer.exponential_blur (6);
                
                buffer.context.set_line_width (1);
                buffer.context.set_source_rgba (0, 0, 0, 0.9);
                buffer.context.stroke_preserve ();
                
                buffer.context.set_source_rgb (0.98, 0.98, 0.98);
                buffer.context.fill ();
            });
            entry.menu.get_parent ().draw.connect ( (ctx) => {
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.rectangle (0, 0, w, h);
                ctx.set_source_rgba (0, 0, 0, 0);
                ctx.fill ();
                
                ctx.set_source_surface (buffer.surface, 0, 0);
                ctx.paint ();
                return false;
            });
            
            entry.menu.margin_top = 25;
            entry.menu.margin_bottom = 20;
            /*entry.menu.margin_left = 10;
            entry.menu.margin_right = 9; 
            FIXME => This is what we want to get, but to solve spacing issues we do this:*/
            entry.menu.get_children ().foreach ( (c) => {
                c.margin_left = 10;
                c.margin_right = 9;
            });
            
            
            var transp_css = new Gtk.CssProvider ();
            try {
                transp_css.load_from_data ("
                    * {
                        background-color:@transparent;
                        border-color:@transparent;
                        -unico-inner-stroke-width: 0;
                    }", -1);
            } catch (Error e) { warning (e.message); }
            entry.menu.get_style_context ().add_provider (transp_css, 20000);
            
        }

        private bool on_scroll_event (EventScroll event)
        {
            //Signal.emit_by_name (object, "scroll", 1, event.direction);
            object.entry_scrolled (entry, 1, (Indicator.ScrollDirection)event.direction);
            
            return false;
        }

    }
}

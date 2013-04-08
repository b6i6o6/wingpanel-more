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

using Gdk;

namespace  Wingpanel 
{
    public class IndicatorObjectEntry: IndicatorButton {
        private Indicator.Object object;
        private unowned Indicator.ObjectEntry entry;
        
        // used for drawing
        private Gtk.Window menu;
        private Granite.Drawing.BufferSurface buffer;
        private int w = -1;
        private int h = -1;
        private int arrow_height = 10;
        private int arrow_width = 20;
        private double x = 10.5;
        private double y = 10.5;
        private int radius = 5;

        private const string MENU_STYLESHEET = """
            .menu {
                background-color:@transparent;
                border-color:@transparent;
                -unico-inner-stroke-width: 0;
             }
             .popover_bg {
               background-color:#fff;
             }
         """;

        public IndicatorObjectEntry (IndicatorsModel model, Indicator.ObjectEntry entry, Indicator.Object iobject) {
            object = iobject;
            this.entry = entry;

            if (entry.image != null && entry.image is Gtk.Image) {
                debug ("Indicator: %s has attribute image", model.get_indicator_name (object));
                set_widget (WidgetSlot.IMAGE, entry.image);
            }

            if (entry.label != null && entry.label is Gtk.Label) {
                debug ("Indicator: %s has attribute label", model.get_indicator_name (object));
                set_widget (WidgetSlot.LABEL, entry.label);
            }

            show ();

            if (entry.menu == null)
                return;

            set_submenu (entry.menu);

            scroll_event.connect (on_scroll_event);

            buffer = new Granite.Drawing.BufferSurface (100, 100);

            entry.menu.get_parent ().app_paintable = true;
            entry.menu.get_parent ().set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            entry.menu.get_parent ().size_allocate.connect (() => {
                /*entry.menu.margin_left = 10;
                entry.menu.margin_right = 9;
                FIXME => This is what we want to get, but to solve spacing issues we do this:*/
                entry.menu.get_children ().foreach ((c) => {
                    c.margin_left = 10;
                    c.margin_right = 9;
                }); //make sure it is always right
            });

            entry.menu.get_parent ().draw.connect ((ctx) => {
                var new_w  = entry.menu.get_parent ().get_allocated_width ();
                var new_h = entry.menu.get_parent ().get_allocated_height ();
                if (new_w != w || new_h != h) {
                    w = new_w;
                    h = new_h;

                    buffer = new Granite.Drawing.BufferSurface (w, h);
                    cairo_popover (w, h);

                    var cr = buffer.context;

                    //shadow
                    cr.set_source_rgba (0, 0, 0, 0.5);
                    cr.fill_preserve ();
                    buffer.exponential_blur (6);
                    cr.clip ();

                    //background
                    menu.get_style_context ().render_background (cr, 0, 0, w, h);
                    cr.reset_clip ();

                    //border
                    cairo_popover (w, h);
                    cr.set_operator (Cairo.Operator.SOURCE);
                    cr.set_line_width (1);
                    Gdk.cairo_set_source_rgba (cr, menu.get_style_context ().get_border_color (Gtk.StateFlags.NORMAL));
                    cr.stroke ();
                }

                //clear surface to transparent
                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.set_source_rgba (0, 0, 0, 0);
                ctx.paint ();

                //now paint our buffer on
                ctx.set_source_surface (buffer.surface, 0, 0);
                ctx.paint ();
                
                return false;
            });

            entry.menu.margin_top = 28;
            entry.menu.margin_bottom = 18;

            Granite.Widgets.Utils.set_theming (entry.menu, MENU_STYLESHEET, null,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            menu = new Granite.Widgets.PopOver ();

            Granite.Widgets.Utils.set_theming (menu, MENU_STYLESHEET,
                                               Granite.StyleClass.POPOVER_BG,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        void cairo_popover (int w, int h) {
            w = w - 20;
            h = h - 20;

            // Get some nice pos for the arrow
            var offs = 30;
            int p_x;
            int w_x;
            Gtk.Allocation alloc;
            this.get_window ().get_origin (out p_x, null);
            this.get_allocation (out alloc);

            entry.menu.get_window ().get_origin (out w_x, null);

            offs = (p_x + alloc.x) - w_x + this.get_allocated_width () / 4;
            if (offs + 50 > (w + 20))
                offs = (w + 20) - 15 - arrow_width;
            if (offs < 17)
                offs = 17;

            buffer.context.arc (x + radius, y + arrow_height + radius, radius, Math.PI, Math.PI * 1.5);
            buffer.context.line_to (offs, y + arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
            buffer.context.arc (x + w - radius, y + arrow_height + radius, radius, Math.PI * 1.5, Math.PI * 2.0);

            buffer.context.arc (x + w - radius, y + h - radius, radius, 0, Math.PI * 0.5);
            buffer.context.arc (x + radius, y + h - radius, radius, Math.PI * 0.5, Math.PI);
            
            buffer.context.close_path ();
        }

        private bool on_scroll_event (EventScroll event) {
            //Signal.emit_by_name (object, "scroll", 1, event.direction);
            object.entry_scrolled (entry, 1, (Indicator.ScrollDirection) event.direction);

            return false;
        }

    }
}

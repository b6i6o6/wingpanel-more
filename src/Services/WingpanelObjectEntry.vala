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
    public class IndicatorObjectEntry: Widgets.IndicatorButton
    {
        Indicator.Object object;
        unowned Indicator.ObjectEntry entry;

        public IndicatorObjectEntry (Indicator.ObjectEntry entry, Indicator.Object iobject) {
            object = iobject;
            this.entry = entry;

            IndicatorsModel model = IndicatorsModel.get_default ();

            Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.set_homogeneous (false);
            box.spacing = 2;

            if (entry.image != null && entry.image is Gtk.Image) {
                log ("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Indicator: %s has attribute image", model.get_indicator_name(object));
                box.pack_start (entry.image, false, false, 0);
            }

            if (entry.label != null && entry.label is Gtk.Label) {
                log ("wingpanel", LogLevelFlags.LEVEL_DEBUG, "Indicator: %s has attribute label", model.get_indicator_name (object));
                box.pack_end (entry.label, false, false, 0);
                entry.label.get_style_context().add_class(INDICATOR_BUTTON_STYLE_CLASS);
            }

            add (box);
            box.show ();

            if (entry.menu != null)
                set_submenu (entry.menu);
            show ();
            scroll_event.connect (on_scroll_event);

            var buffer = new Granite.Drawing.BufferSurface (100, 100);

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

            var w = -1;
            var h = -1;
            var arrow_height = 10;
            var arrow_width = 20;
            var x = 10.5;
            var y = 10.5;
            var radius = 5;

            entry.menu.get_parent ().draw.connect ((ctx) => {
                w  = entry.menu.get_parent ().get_allocated_width ();
                h = entry.menu.get_parent ().get_allocated_height ();

                buffer = new Granite.Drawing.BufferSurface (w, h);

                Granite.Drawing.Utilities.cairo_rounded_rectangle (buffer.context, x, y + arrow_height,
                                                                   w - 20, h - 20 - arrow_height, radius);

                /* Get some nice pos for the arrow */
                var offs = 30;
                int p_x;
                int w_x;
                Gtk.Allocation alloc;
                this.get_window ().get_origin (out p_x, null);
                this.get_allocation (out alloc);

                entry.menu.get_window ().get_origin (out w_x, null);

                offs = (p_x + alloc.x) - w_x + this.get_allocated_width () / 4;
                if (offs + 50 > w)
                    offs = w - 15 - arrow_width;
                if (offs < 17)
                    offs = 17;

                // Draw arrow
                buffer.context.move_to (offs, y + arrow_height);
                buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
                buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
                buffer.context.close_path ();

                buffer.context.set_source_rgba (0, 0, 0, 0.5);
                buffer.context.fill_preserve ();
                buffer.exponential_blur (6);

                buffer.context.set_line_width (1);
                buffer.context.set_source_rgba (0, 0, 0, 0.4);
                buffer.context.stroke_preserve ();
                buffer.context.save ();
                buffer.context.clip ();

                var cr = new Gtk.StyleContext ();
                cr.set_path (entry.menu.get_path ());
                Gtk.render_background (cr, buffer.context, 0, 0, entry.menu.get_allocated_width (), entry.menu.get_allocated_height ());
                buffer.context.restore ();

                ctx.set_operator (Cairo.Operator.SOURCE);
                ctx.rectangle (0, 0, w, h);
                ctx.set_source_rgba (0, 0, 0, 0);
                ctx.fill ();

                ctx.set_source_surface (buffer.surface, 0, 0);
                ctx.paint ();
                return false;
            });

            entry.menu.margin_top = 28;
            entry.menu.margin_bottom = 18;

            var transp_css = new Gtk.CssProvider ();
            try {
                transp_css.load_from_data (""" * {
                           background-color:@transparent;
                           border-color:@transparent;
                           -unico-inner-stroke-width: 0;
                           }""", -1);
            } catch (Error e) {
                warning (e.message);
            }

            entry.menu.get_style_context ().add_provider (transp_css, 20000);
        }

        private bool on_scroll_event (EventScroll event) {
            //Signal.emit_by_name (object, "scroll", 1, event.direction);
            object.entry_scrolled (entry, 1, (Indicator.ScrollDirection) event.direction);

            return false;
        }

    }
}

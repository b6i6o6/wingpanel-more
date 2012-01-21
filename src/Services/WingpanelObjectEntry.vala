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
        }

        private bool on_scroll_event (EventScroll event)
        {
            //Signal.emit_by_name (object, "scroll", 1, event.direction);
            object.entry_scrolled (entry, 1, (Indicator.ScrollDirection)event.direction);
            
            return false;
        }

    }
}

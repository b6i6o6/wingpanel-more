namespace Cardapio {
    [DBus (name = "org.varal.Cardapio")]
    interface dbus : GLib.Object {
        [DBus (name = "show_hide")]
        public abstract void show_hide() throws GLib.IOError;
        [DBus (name = "show_hide_near_mouse")]
        public abstract void show_hide_near_mouse() throws GLib.IOError;
        [DBus (name = "show_hide_near_point")]
        public abstract void show_hide_near_point(int32 x, int32 y, bool force_anchor_right, bool force_anchor_bottom) throws GLib.IOError;
    }
}

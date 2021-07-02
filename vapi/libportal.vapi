/*
 * libportal vapi
 * This is only the vapi for color picking
 * */

[CCode (cheader_filename = "libportal/portal-gtk3.h")]
namespace Xdp {
    public class Portal : GLib.Object {
        public Portal ();

        public async void
        pick_color (Parent parent, GLib.Cancellable? cancelable = null);
        
        public GLib.Variant 
        pick_color_finish (GLib.AsyncResult result) throws GLib.Error;
    }

    [Compact]
    [CCode (cname = "XdpParent", free_function = "xdp_parent_free", has_type_id = false)]
    public class Parent {
        public Gtk.Window object;

        [CCode (cname = "xdp_parent_new_gtk")]
        public Parent (Gtk.Window window);
    }
}

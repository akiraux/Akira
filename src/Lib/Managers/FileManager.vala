/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alberto Fanjul <albertofanjul@gmail.com>
*/

using Akira;
using Akira.Lib;
using Akira.Layouts.Partials;

public class Akira.Lib.Managers.FileManager: Object {

    public weak Window window { get; construct; }
    private GLib.File? file;
    public weak Canvas canvas {
       get {
          return window.main_window.main_canvas.canvas;
       }
    }
    public weak Artboard artboard {
       get {
          return window.main_window.right_sidebar.layers_panel.artboard;
       }
    }

    public FileManager (Window window) {
       Object(
          window: window
       );
    }

    public void open_file () {
        var open_dialog = new Gtk.FileChooserDialog ("Open file",
                                                     this as Gtk.Window,
                                                     Gtk.FileChooserAction.OPEN,
                                                     Gtk.Stock.CANCEL,
                                                     Gtk.ResponseType.CANCEL,
                                                     Gtk.Stock.OPEN,
                                                     Gtk.ResponseType.ACCEPT);
        add_filters (open_dialog);
        open_dialog.local_only = false; //allow for uri
        open_dialog.set_modal (true);
        open_dialog.response.connect (open_response_cb);
        open_dialog.show ();
    }

    private void open_response_cb (Gtk.Dialog dialog, int response_id) {
        var open_dialog = dialog as Gtk.FileChooserDialog;

        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                file = open_dialog.get_file();

                uint8[] file_contents;

                try {
                    file.load_contents (null, out file_contents, null);
                    Json.Parser parser = new Json.Parser ();
                    parser.load_from_data ((string) file_contents);

                    //Register names to be disoverable by name
                    Type? type_rect = typeof (Akira.Lib.Models.CanvasRect);
                    Type? type_ellipse = typeof (Akira.Lib.Models.CanvasEllipse);
                    Type? type_text = typeof (Akira.Lib.Models.CanvasText);

                    //Clean existing items
                    var root_item = canvas.get_root_item ();
                    while (root_item.get_n_children () > 0) {
                        Goo.CanvasItem item = root_item.get_child(0);
                        var layer = item.get_data<Akira.Layouts.Partials.Layer?> ("layer");
                        artboard.container.remove (layer);
                        item.remove ();
                    }

                    Json.Node node = parser.get_root ();
                    var root_object_node = node.get_object ();
                    Json.Array array = root_object_node.get_member ("items").get_array ();
                    foreach (unowned Json.Node node_item in array.get_elements ()) {
                        var object_node = node_item.get_object ();
                        load_item (object_node);
                    }
                    var scale = root_object_node.get_double_member ("scale");
                    canvas.set_scale (scale);
                    //TODO: listen to scale on canvas to change the zoom_button
                    window.headerbar.zoom.zoom_default_button.label = "%.0f%%".printf (scale * 100);

                    info ("opened: %s\n", (open_dialog.get_filename ()));
                }
                catch (GLib.Error err) {
                    error ("%s\n", err.message);
                }

                break;

            case Gtk.ResponseType.CANCEL:
                info ("cancelled: FileChooserAction.OPEN\n");
                break;
        }
        dialog.destroy ();
    }

    private void load_item (Json.Object object_node) {
        string type = object_node.get_string_member ("type");
        var object_node_item = object_node.get_member ("item");
        Goo.CanvasItem item = Json.gobject_deserialize (Type.from_name (type), object_node_item) as Goo.CanvasItem;
        if (item != null) {
            item.set("parent", canvas.get_root_item ());
            var object_node_transform = object_node.get_member ("transform").get_object ();
            var transform = Cairo.Matrix.identity ();
            transform.xx = object_node_transform.get_double_member ("xx");
            transform.xy = object_node_transform.get_double_member ("xy");
            transform.yx = object_node_transform.get_double_member ("yx");
            transform.yy = object_node_transform.get_double_member ("yy");
            transform.x0 = object_node_transform.get_double_member ("x0");
            transform.y0 = object_node_transform.get_double_member ("y0");
            item.set_transform (transform);
            add_artboard_layer (item, type.replace ("AkiraLibModelsCanvas", ""));
        }
    }

    private void add_artboard_layer (Goo.CanvasItem item, string type) {
        if (type == "Rect") {
            type = "Rectangle";
        } else if (type == "Ellipse") {
            type = "Circle";
        } else if (type == "Text") {
            type = "Text";
        }
        var layer = new Akira.Layouts.Partials.Layer (window, artboard, (Goo.CanvasItemSimple)item,
            type, "shape-" + type.down () + "-symbolic", false);
        item.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
        artboard.container.add (layer);
        artboard.show_all ();
    }

    public void save_file () {
        if (file != null) {
            save_to_file ();
        }
        else {
            save_as ();
        }
    }

    public void save_as () {
        var save_dialog = new Gtk.FileChooserDialog ("Save canvas",
                                                     this as Gtk.Window,
                                                     Gtk.FileChooserAction.SAVE,
                                                     Gtk.Stock.CANCEL,
                                                     Gtk.ResponseType.CANCEL,
                                                     Gtk.Stock.SAVE,
                                                     Gtk.ResponseType.ACCEPT);

        save_dialog.set_do_overwrite_confirmation (true);
        add_filters (save_dialog);
        save_dialog.set_modal (true);
        if (file != null) {
            try {
                (save_dialog as Gtk.FileChooser).set_file (file);
            }
            catch (GLib.Error error) {
                info ("%s\n", error.message);
            }
        }
        save_dialog.response.connect (save_as_response_cb);
        save_dialog.show ();
    }

    private void add_filters (Gtk.FileChooser chooser) {
        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.add_pattern ("*.akira");
        filter.set_filter_name ("Akira files");
        chooser.add_filter(filter);
        filter = new Gtk.FileFilter ();
        filter.add_pattern ("*");
        filter.set_filter_name ("All files");
        chooser.add_filter(filter);
    }

    private void save_as_response_cb (Gtk.Dialog dialog, int response_id) {
        var save_dialog = dialog as Gtk.FileChooserDialog;

        switch (response_id) {
            case Gtk.ResponseType.ACCEPT:
                var save_file = save_dialog.get_file();
                var path = save_file.get_path ();
                if (path.has_suffix (".akira")) {
                   file = save_file;
                } else {
                   file = File.new_for_path (path + ".akira");
                }
                this.save_to_file ();
                break;
            default:
                break;
        }
            dialog.destroy ();
    }

    void save_to_file () {
        var root_item = canvas.get_root_item ();

        Json.Builder builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("version");
        //TODO: Deal with old versions
        //1.0 objects are pure Goo.CanvasItems
        builder.add_string_value ("2.0");

        builder.set_member_name ("scale");
        builder.add_double_value (canvas.get_scale ());

        builder.set_member_name ("items");
        builder.begin_array ();
        for (int i = 0; i < root_item.get_n_children (); i++) {
           Goo.CanvasItem item = root_item.get_child(i);
           if (item.get_data<bool>("ignore")) {
               continue;
           }
           Json.Node node = Json.gobject_serialize (item);
           builder.begin_object ();
           builder.set_member_name ("type");
           builder.add_string_value (item.get_type ().name ());
           builder.set_member_name ("item");
           builder.add_value (node);
           var transform = Cairo.Matrix.identity ();
           item.get_transform (out transform);
           builder.set_member_name ("transform");
           builder.begin_object ();
           builder.set_member_name("xx");
           builder.add_double_value(transform.xx);
           builder.set_member_name("yx");
           builder.add_double_value(transform.yx);
           builder.set_member_name("xy");
           builder.add_double_value(transform.xy);
           builder.set_member_name("yy");
           builder.add_double_value(transform.yy);
           builder.set_member_name("x0");
           builder.add_double_value(transform.x0);
           builder.set_member_name("y0");
           builder.add_double_value(transform.y0);
           builder.end_object ();
           builder.end_object ();
        }
        builder.end_array ();

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.pretty = true;
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        string current_contents = generator.to_data (null);
        try {
                file.replace_contents (current_contents.data, null, false,
                                       GLib.FileCreateFlags.NONE, null, null);

                info ("saved: %s\n", file.get_path ());
        }
        catch (GLib.Error err) {
            error ("%s\n", err.message);
        }
    }

}

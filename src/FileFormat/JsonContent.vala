/*
 * Copyright (c) 2020 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.FileFormat.JsonContent : Object {
    public weak Akira.Window window { get; construct; }

    private Akira.Lib.Canvas canvas;
    private Json.Generator generator;
    private Json.Builder builder;

    public JsonContent (Akira.Window window) {
        Object (window: window);
    }

    construct {
        generator = new Json.Generator ();
        generator.pretty = true;

        builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("version");
        builder.add_string_value (Constants.VERSION);

        canvas = window.main_window.main_canvas.canvas;
        builder.set_member_name ("scale");
        builder.add_double_value (canvas.get_scale ());
    }

    public async void save_content () {
        // Convert Artboards to JSON.
        if (window.items_manager.artboards.length () > 0) {
            yield save_artboards ();
        }
        //  for (int i = 0; i < canvas.get_root_item ().get_n_children (); i++) {
        //     Goo.CanvasItem item = canvas.get_root_item ().get_child (i);
        //     if (item.get_data<bool> ("ignore")) {
        //         continue;
        //     }
        //     Json.Node node = Json.gobject_serialize (item);
        //     builder.begin_object ();
        //     builder.set_member_name ("type");
        //     builder.add_string_value (item.get_type ().name ());
        //     builder.set_member_name ("item");
        //     builder.add_value (node);
        //     var transform = Cairo.Matrix.identity ();
        //     item.get_transform (out transform);
        //     builder.set_member_name ("transform");
        //     builder.begin_object ();
        //     builder.set_member_name ("xx");
        //     builder.add_double_value (transform.xx);
        //     builder.set_member_name ("yx");
        //     builder.add_double_value (transform.yx);
        //     builder.set_member_name ("xy");
        //     builder.add_double_value (transform.xy);
        //     builder.set_member_name ("yy");
        //     builder.add_double_value (transform.yy);
        //     builder.set_member_name ("x0");
        //     builder.add_double_value (transform.x0);
        //     builder.set_member_name ("y0");
        //     builder.add_double_value (transform.y0);
        //     builder.end_object ();
        //     builder.end_object ();
        //  }
        //  builder.end_array ();
    }

    private async void save_artboards () {
        builder.set_member_name ("artboards");
        builder.begin_array ();

        foreach (var artboard in window.items_manager.artboards) {
            var item = new JsonObject (artboard);
            //  Json.Node node = Json.gobject_serialize (item);
            //  builder.begin_object ();
            //  builder.set_member_name ("artboard");
            //  builder.add_value (node);
            //  builder.end_object ();
        }

        builder.end_array ();
    }

    public string finalize_content () {
        builder.end_object ();

        Json.Node root = builder.get_root ();
        generator.set_root (root);

        return generator.to_data (null);
    }
}

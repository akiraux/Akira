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

        canvas = window.main_window.main_canvas.canvas;
    }

    public void save_content () {
        // Save the current version of Akira.
        builder.set_member_name ("version");
        builder.add_string_value (Constants.VERSION);

        // Save the current Canvas status.
        builder.set_member_name ("scale");
        builder.add_double_value (canvas.get_scale ());
        builder.set_member_name ("hadjustment");
        builder.add_double_value (window.main_window.main_canvas.main_scroll.hadjustment.value);
        builder.set_member_name ("vadjustment");
        builder.add_double_value (window.main_window.main_canvas.main_scroll.vadjustment.value);

        // Convert Artboards to JSON.
        if (window.items_manager.artboards.get_n_items () > 0) {
            save_artboards ();
        }

        // Convert Items to JSON.
        if (window.items_manager.free_items.get_n_items () > 0) {
            save_items ();
        }
    }

    private void save_artboards () {
        builder.set_member_name ("artboards");
        builder.begin_array ();

        foreach (var artboard in window.items_manager.artboards) {
            var item = new JsonObject (artboard);
            builder.begin_object ();
            builder.set_member_name ("artboard");
            builder.add_value (item.get_node ());
            builder.end_object ();
        }

        builder.end_array ();
    }

    private void save_items () {
        builder.set_member_name ("items");
        builder.begin_array ();

        foreach (var _item in window.items_manager.free_items) {
            var item = new JsonObject (_item);
            builder.begin_object ();
            builder.set_member_name ("item");
            builder.add_value (item.get_node ());
            builder.end_object ();
        }

        // Save all the items inside this Artboard.
        foreach (var artboard in window.items_manager.artboards) {
            foreach (var _item in artboard.items) {
                var child_item = new JsonObject (_item);
                builder.begin_object ();
                builder.set_member_name ("item");
                builder.add_value (child_item.get_node ());
                builder.end_object ();
            }
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

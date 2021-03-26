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

public class Akira.FileFormat.JsonSerializer {

    /*
     * Converts the world (window, and canvas item information) to a Json.Node.
     * Use this and json_to_string to save Akira's file state.
     */
    public static Json.Node world_to_json_node (Akira.Window window, bool items_only = false) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        if (!items_only) {
            serialize_window_state (window, ref builder);
        }

        // Convert Artboards to JSON.
        serialize_artboards (window, ref builder);

        // Convert Items to JSON.
        serialize_items (window, ref builder);

        builder.end_object ();

        return builder.get_root ();
    }

    /*
     * Converts a Json.Node to a string
     */
    public static string json_to_string (Json.Node node, bool pretty) {
        var generator = new Json.Generator ();
        generator.pretty = pretty;
        generator.set_root (node);
        return generator.to_data (null);
    }

    /*
     * Serialize window states to the builder.
     */
    public static void serialize_window_state ( Akira.Window window, ref Json.Builder builder) {
        // Save the current version of Akira.
        builder.set_member_name ("version");
        builder.add_string_value (Constants.VERSION);

        // Save the current Canvas status.
        builder.set_member_name ("scale");
        builder.add_double_value (window.main_window.main_canvas.canvas.get_scale ());
        builder.set_member_name ("hadjustment");
        builder.add_double_value (window.main_window.main_canvas.main_scroll.hadjustment.value);
        builder.set_member_name ("vadjustment");
        builder.add_double_value (window.main_window.main_canvas.main_scroll.vadjustment.value);
    }

    /*
     * Serialize canvas artboards to the builder.
     */
    public static void serialize_artboards ( Akira.Window window, ref Json.Builder builder) {
        builder.set_member_name ("artboards");
        builder.begin_array ();

        foreach (var artboard in window.items_manager.artboards) {
            builder.begin_object ();
            builder.set_member_name ("artboard");
            builder.add_value (JsonItemSerializer.serialize_item (artboard));
            builder.end_object ();
        }

        builder.end_array ();
    }

    /*
     * Serialize canvas items to the builder.
     */
    public static void serialize_items ( Akira.Window window, ref Json.Builder builder) {
        builder.set_member_name ("items");
        builder.begin_array ();

        foreach (var _item in window.items_manager.free_items) {
            builder.begin_object ();
            builder.set_member_name ("item");
            builder.add_value (JsonItemSerializer.serialize_item (_item));
            builder.end_object ();
        }

        // Save all the items inside this Artboard.
        foreach (var artboard in window.items_manager.artboards) {
            foreach (var _item in artboard.items) {
                builder.begin_object ();
                builder.set_member_name ("item");
                builder.add_value (JsonItemSerializer.serialize_item (_item));
                builder.end_object ();
            }
        }

        builder.end_array ();
    }
}

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

public class Akira.FileFormat.JsonLoader : Object {
    public weak Akira.Window window { get; construct; }
    public Json.Object obj { get; construct; }

    public JsonLoader (Akira.Window window, Json.Object obj) {
        Object (
            window: window,
            obj: obj
        );
    }

    construct {
        load_content ();
    }

    public void load_content () {
        // Load saved Artboards.
        if (obj.get_member ("artboards") != null) {
            Json.Array artboards = obj.get_member ("artboards").get_array ();
            foreach (unowned Json.Node node in artboards.get_elements ()) {
                var object = node.get_object ();
                load_artboard (object);
            }
        }

        // Load saved Items.
        if (obj.get_member ("items") != null) {
            Json.Array items = obj.get_member ("items").get_array ();
            foreach (unowned Json.Node node in items.get_elements ()) {
                var object = node.get_object ();
                load_item (object);
            }
        }

        window.event_bus.set_scale (obj.get_double_member ("scale"));
        window.main_window.main_canvas.main_scroll.hadjustment.value = obj.get_double_member ("hadjustment");
        window.main_window.main_canvas.main_scroll.vadjustment.value = obj.get_double_member ("vadjustment");
    }

    private void load_artboard (Json.Object obj) {
        var artboard = obj.get_member ("artboard").get_object ();
        if (artboard != null) {
            window.items_manager.load_artboard (artboard);
        }
    }

    private void load_item (Json.Object obj) {
        var item = obj.get_member ("item").get_object ();
        if (item != null) {
            window.items_manager.load_item (item);
        }
    }
}

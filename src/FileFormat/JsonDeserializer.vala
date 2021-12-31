/*
 * Copyright (c) 2020-2021 Alecaddd (https://alecaddd.com)
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

public class Akira.FileFormat.JsonDeserializer {
    /*
     * Deserialize a Json.Node and apply it to the current world state.
     * This deserializes a node, which is symmetric with the output of JsonSerializer.
     */
    public static void json_node_to_world (Json.Node node, Akira.Window window, bool items_only = false) {
        var obj = node.get_object ();
        if (obj != null) {
            json_object_to_world (obj, window, items_only);
        }
    }

    /*
     * Deserialize a Json.Node and apply it to the current world state.
     */
    public static void json_object_to_world (Json.Object obj, Akira.Window window, bool items_only = false) {
        var view_canvas = window.main_window.main_view_canvas.canvas;

        // Se the canvas to simulate a click + holding state to avoid triggering
        // redrawing methods connected to that state.
        view_canvas.holding = true;


        if (!items_only) {
            load_window_states (window, obj);
        }

        deserialize_model (window.main_window.main_view_canvas.canvas, obj);

        // Reset the holding state at the end of it.
        view_canvas.holding = false;
    }

    /*
     * Deserialize window states and apply them to the window.
     */
    private static void load_window_states (Akira.Window window, Json.Object obj) {
        window.event_bus.adjust_zoom (obj.get_double_member ("scale"), true, null);
        window.main_window.main_view_canvas.main_scroll.hadjustment.value = obj.get_double_member ("hadjustment");
        window.main_window.main_view_canvas.main_scroll.vadjustment.value = obj.get_double_member ("vadjustment");
    }

    /*
     * Deserialize the model.
     */
    private static void deserialize_model (Lib.ViewCanvas view_canvas, Json.Object obj) {
        var roots = obj.get_member ("roots");
        if (roots == null) {
            // bad file
            assert (false);
            return;
        }

        foreach (unowned Json.Node root in roots.get_array ().get_elements ()) {
            deserialize_node (view_canvas, root.get_object (), Lib.Items.Model.ORIGIN_ID);
        }

        view_canvas.items_manager.compile_model ();
    }

    /*
     * Deserialize a specific node, recursive.
     */
    private static void deserialize_node (Lib.ViewCanvas view_canvas, Json.Object node_obj, int group_id) {
        if (!node_obj.has_member ("type")) {
            assert (false);
            return;
        }

        int new_id = -1;
        var type = node_obj.get_string_member ("type");

        var components_json = node_obj.get_member ("components");
        var components = Lib.Components.Components.deserialize (components_json);

        Lib.Items.ModelInstance? new_inst = null;
        if (type == "rect") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypeRect ());
        } else if (type == "ellipse") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypeEllipse ());
        } else if (type == "group") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypeGroup ());
        } else if (type == "artboard") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypeArtboard ());
        } else if (type == "path") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypePath ());
        } else if (type == "text") {
            new_inst = new Lib.Items.ModelInstance (-1, new Lib.Items.ModelTypeText ());
        }
        else {
            // Unknown type
            assert (false);
            return;
        }

        new_inst.components = components;

        new_id = view_canvas.items_manager.add_item_to_group (group_id, new_inst, true);

        var children = node_obj.get_member ("children");
        if (children != null) {
            foreach (unowned Json.Node child in children.get_array ().get_elements ()) {
                deserialize_node (view_canvas, child.get_object (), new_id);
            }
        }
    }
}

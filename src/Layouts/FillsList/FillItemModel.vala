/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Simple Object to be handled by the FillsListBoxModel and to give easy access
 * the fill component of the Lib.Items.ModelNode.
 */
public class Akira.Layouts.FillsList.FillItemModel : GLib.Object {
    private unowned Akira.Lib.ViewCanvas _view_canvas;

    private Lib.Items.ModelInstance _cached_instance;

    private int id;

    public Gdk.RGBA color {
        get {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            return fill.color;
        }
        set {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            if (fill.color == value) {
                return;
            }

            update_color (value, is_color_hidden);
        }
    }

    public double alpha {
        get {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            return fill.color.alpha;
        }
        set {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            if (fill.color.alpha == value) {
                return;
            }

            var new_color = fill.color;
            new_color.alpha = value;

            update_color (new_color, is_color_hidden);
        }
    }

    public bool is_color_hidden {
        get {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            return fill.is_color_hidden;
        }
        set {
            var fill = _cached_instance.components.fills.fill_from_id (id);
            if (fill.is_color_hidden == value) {
                return;
            }

            update_color (color, value);
        }
    }

    private void update_color (Gdk.RGBA color, bool hidden) {
        unowned var im = _view_canvas.items_manager;
        var node = im.item_model.node_from_id (_cached_instance.id);
        assert (node != null);

        var new_color = Lib.Components.Color.from_rgba (color, hidden);
        node.instance.components.fills.replace (Lib.Components.Fills.Fill (id, new_color));
        im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_FILL);
        im.compile_model ();
    }

    public FillItemModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode node, int fill_id) {
        update_node (node, fill_id);
        _view_canvas = view_canvas;
    }

    private void update_node (Lib.Items.ModelNode new_node, int fill_id) {
        _cached_instance = new_node.instance;
        this.id = fill_id;
    }
}

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
 * Simple Object to be handled by the BordersListBoxModel and to give easy access
 * the border component of the Lib.Items.ModelNode.
 */
public class Akira.Layouts.BordersList.BorderItemModel : Models.ColorModel {
    private unowned Lib.ViewCanvas _view_canvas;

    //  private Lib.Items.ModelInstance _cached_instance;

    public int border_id;

    public override void on_value_changed () {
        if (block_signal > 0) {
            return;
        }

        unowned var im = _view_canvas.items_manager;
        var node = im.item_model.node_from_id (_cached_instance.id);
        assert (node != null);

        var new_pattern = pattern.copy ();
        var new_borders = node.instance.components.borders.copy ();
        var new_border = new_borders.border_from_id (border_id).with_replaced_pattern (new_pattern);
        new_borders.replace (new_border);
        node.instance.components.borders = new_borders;

        im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_BORDER);
        im.compile_model ();
    }

    public override void delete () {
        unowned var im = _view_canvas.items_manager;
        var node = im.item_model.node_from_id (_cached_instance.id);
        assert (node != null);

        var new_borders = node.instance.components.borders.copy ();
        new_borders.remove (border_id);
        node.instance.components.borders = new_borders;

        im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_BORDER);
        im.compile_model ();
    }

    public BorderItemModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode node, int border_id) {
        update_node (node, border_id);
        _view_canvas = view_canvas;
    }

    private void update_node (Lib.Items.ModelNode new_node, int border_id) {
        _cached_instance = new_node.instance;
        this.border_id = border_id;

        var blocker = new SignalBlocker (this);
        (blocker);

        var border = _cached_instance.components.borders.border_from_id (border_id);
        active_pattern_type = border.active_pattern;

        solid_pattern = border.solid_pattern;
        linear_pattern = border.linear_pattern;
        radial_pattern = border.radial_pattern;

        hidden = border.hidden;
    }
}

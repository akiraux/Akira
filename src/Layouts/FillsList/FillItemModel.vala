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
public class Akira.Layouts.FillsList.FillItemModel : Models.ColorModel {
    private unowned Akira.Lib.ViewCanvas _view_canvas;

    private Lib.Items.ModelInstance _cached_instance;

    public int fill_id;

    public override void on_value_changed () {
        if (block_signal > 0) {
            return;
        }

        unowned var im = _view_canvas.items_manager;
        var node = im.item_model.node_from_id (_cached_instance.id);
        assert (node != null);

        var new_pattern = pattern.copy ();
        var new_fills = node.instance.components.fills.copy ();
        new_fills.replace (Lib.Components.Fills.Fill (fill_id, new_pattern));
        node.instance.components.fills = new_fills;

        im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_FILL);
        im.compile_model ();
    }

    public override void delete () {
        unowned var im = _view_canvas.items_manager;
        var node = im.item_model.node_from_id (_cached_instance.id);
        assert (node != null);

        var new_fills = node.instance.components.fills.copy ();
        new_fills.remove (fill_id);
        node.instance.components.fills = new_fills;

        im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_FILL);
        im.compile_model ();
    }

    public FillItemModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode node, int fill_id) {
        update_node (node, fill_id);
        _view_canvas = view_canvas;
    }

    private void update_node (Lib.Items.ModelNode new_node, int fill_id) {
        _cached_instance = new_node.instance;
        this.fill_id = fill_id;

        var blocker = new SignalBlocker (this);
        (blocker);

        var fill = _cached_instance.components.fills.fill_from_id (fill_id);
        active_pattern_type = fill.active_pattern;
        
        solid_pattern = fill.solid_pattern;
        linear_pattern = fill.linear_pattern;
        radial_pattern = fill.radial_pattern;
        
        hidden = fill.hidden;
    }
}

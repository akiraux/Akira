/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

using Akira.Lib;

public class Akira.LibModelTests : Akira.TestSuite {
    public LibModelTests () {
        this.add_test ("origin_splice_extripate", this.origin_splice_extripate);
        this.add_test ("origin_move", this.origin_move);
        this.add_test ("nested_ops", this.nested_ops);
    }

    public override void setup () {}

    public override void teardown () {}

    void compare_instances (
        Items.Model model,
        int group_id, GLib.Array<int?> expected_items,
        GLib.Array<int?> expected_item_parents
    ) {
        assert (model.group_map.has_key (group_id));
        assert (model.group_nodes.has_key (group_id));
        assert (expected_items.length == expected_item_parents.length);

        var parent_group = model.group_nodes[group_id];

        for (var i = 0; i < expected_items.length; ++i) {
            var expected_id = expected_items.index (i);
            var child = parent_group.children.index (i);

            assert (parent_group.instance.children[i] == expected_id);
            assert (child.id == expected_id);
            assert (child.instance.id == expected_id);
            assert (child.parent.instance.id == group_id);
        }
    }

    public void origin_splice_extripate () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();

        // bad target parent
        assert (-1 == model.splice_new_item (0, 1, Items.ModelInstance.dummy_item ()));
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        var candidate = Items.ModelInstance.dummy_item ();

        // splice item at zero location in empty origin
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 0, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        expected_items.append_val (Items.Model.ITEM_START_ID + 1);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // splice item after the previous one in the origin
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 1, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        expected_items.append_val (Items.Model.ITEM_START_ID + 2);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // splice item at zero location in non-empty origin
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 0, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        expected_items.insert_val (0, Items.Model.ITEM_START_ID + 3);
        expected_item_parents.insert_val (0, Items.Model.ORIGIN_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // invalid parent to extripate
        assert (-1 == model.extripate (-1, 3, true));
        assert (-1 == model.extripate (Items.Model.ITEM_START_ID + 2, 3, true));
        assert (-1 == model.extripate (Items.Model.ORIGIN_ID, 3, true));
        assert (-1 == model.extripate (Items.Model.ORIGIN_ID, 4, true));

        // extripate second item in origin
        assert (0 == model.extripate (Items.Model.ORIGIN_ID, 1, true));
        expected_items.remove_index (1);
        expected_item_parents.remove_index (1);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // extripate second item in origin
        assert (0 == model.extripate (Items.Model.ORIGIN_ID, 1, true));
        expected_items.remove_index (1);
        expected_item_parents.remove_index (1);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);
    }

    public void origin_move () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();

        var candidate = Items.ModelInstance.dummy_item ();

        expected_items.append_val (Items.Model.ITEM_START_ID + 1);
        expected_items.append_val (Items.Model.ITEM_START_ID + 2);
        expected_items.append_val (Items.Model.ITEM_START_ID + 3);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 0, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 1, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 2, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // self move -- do nothing;
        assert (0 == model.move_items (Items.Model.ORIGIN_ID, 0, 0, 1, true));

        // moves that don't change the topology -- do nothing;
        assert (0 == model.move_items (Items.Model.ORIGIN_ID, 0, 0, -1, true));
        assert (0 == model.move_items (Items.Model.ORIGIN_ID, 0, 0, 0, true));
        assert (0 == model.move_items (Items.Model.ORIGIN_ID, 0, 2, 2, true));

        // invalid moves -- do nothing
        assert (-1 == model.move_items (Items.Model.ORIGIN_ID, 4, 0, 1, true));
        assert (-1 == model.move_items (Items.Model.ORIGIN_ID, 2, 0, 4, true));
        assert (-1 == model.move_items (Items.Model.ORIGIN_ID, 3, 0, 1, true));
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 0, 2, 1, true));
        expected_items.data[0] = (Items.Model.ITEM_START_ID + 2);
        expected_items.data[1] = (Items.Model.ITEM_START_ID + 3);
        expected_items.data[2] = (Items.Model.ITEM_START_ID + 1);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 0, 2, 1, true));
        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 0, 2, 1, true));
        expected_items.data[0] = (Items.Model.ITEM_START_ID + 1);
        expected_items.data[1] = (Items.Model.ITEM_START_ID + 2);
        expected_items.data[2] = (Items.Model.ITEM_START_ID + 3);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        // prepare for more complicated rotations
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 3, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 4, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 5, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        expected_items.append_val (Items.Model.ITEM_START_ID + 4);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_items.append_val (Items.Model.ITEM_START_ID + 5);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_items.append_val (Items.Model.ITEM_START_ID + 6);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 0, 2, 3, true));
        expected_items.data[0] = (Items.Model.ITEM_START_ID + 4);
        expected_items.data[1] = (Items.Model.ITEM_START_ID + 5);
        expected_items.data[2] = (Items.Model.ITEM_START_ID + 1);
        expected_items.data[3] = (Items.Model.ITEM_START_ID + 2);
        expected_items.data[4] = (Items.Model.ITEM_START_ID + 3);
        expected_items.data[5] = (Items.Model.ITEM_START_ID + 6);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 2, 0, 3, true));
        expected_items.data[0] = (Items.Model.ITEM_START_ID + 1);
        expected_items.data[1] = (Items.Model.ITEM_START_ID + 2);
        expected_items.data[2] = (Items.Model.ITEM_START_ID + 3);
        expected_items.data[3] = (Items.Model.ITEM_START_ID + 4);
        expected_items.data[4] = (Items.Model.ITEM_START_ID + 5);
        expected_items.data[5] = (Items.Model.ITEM_START_ID + 6);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.ORIGIN_ID, 2, 3, 3, true));
        expected_items.data[0] = (Items.Model.ITEM_START_ID + 1);
        expected_items.data[1] = (Items.Model.ITEM_START_ID + 2);
        expected_items.data[2] = (Items.Model.ITEM_START_ID + 6);
        expected_items.data[3] = (Items.Model.ITEM_START_ID + 3);
        expected_items.data[4] = (Items.Model.ITEM_START_ID + 4);
        expected_items.data[5] = (Items.Model.ITEM_START_ID + 5);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);
    }

    public void nested_ops () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();

        var nested_items = new GLib.Array<int?> ();
        var nested_item_parents = new GLib.Array<int?> ();

        var nested_items2 = new GLib.Array<int?> ();
        var nested_item_parents2 = new GLib.Array<int?> ();

        var candidate = Items.ModelInstance.dummy_item ();
        var group_candidate = Items.ModelInstance.dummy_group ();

        expected_items.append_val (Items.Model.ITEM_START_ID + 1);
        expected_items.append_val (Items.Model.ITEM_START_ID + 2);
        expected_items.append_val (Items.Model.ITEM_START_ID + 3);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);

        // Three roots
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 0, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 1, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (Items.Model.ORIGIN_ID, 2, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        expected_items.insert_val (2, Items.Model.GROUP_START_ID + 1);
        expected_item_parents.append_val (Items.Model.ORIGIN_ID);

        assert (model.splice_new_item (
            Items.Model.ORIGIN_ID, 2, group_candidate.clone ()) >= Items.Model.GROUP_START_ID);

        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        nested_items.append_val (Items.Model.ITEM_START_ID + 4);
        nested_items.append_val (Items.Model.ITEM_START_ID + 5);
        nested_items.append_val (Items.Model.ITEM_START_ID + 6);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);

        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 0, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 1, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 2, candidate.clone ()) >= Items.Model.ITEM_START_ID);

        compare_instances (model, Items.Model.GROUP_START_ID + 1, nested_items, nested_item_parents);

        nested_items.remove_index (1);
        nested_item_parents.remove_index (1);
        assert (0 == model.extripate (Items.Model.GROUP_START_ID + 1, 1, true));

        compare_instances (model, Items.Model.GROUP_START_ID + 1, nested_items, nested_item_parents);

        nested_items.append_val (Items.Model.ITEM_START_ID + 7);
        nested_items.append_val (Items.Model.ITEM_START_ID + 8);
        nested_items.append_val (Items.Model.ITEM_START_ID + 9);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 2, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 3, candidate.clone ()) >= Items.Model.ITEM_START_ID);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 4, candidate.clone ()) >= Items.Model.ITEM_START_ID);

        compare_instances (model, Items.Model.GROUP_START_ID + 1, nested_items, nested_item_parents);

        assert (1 == model.move_items (Items.Model.GROUP_START_ID + 1, 2, 0, 2, true));
        nested_items.data[0] = (Items.Model.ITEM_START_ID + 7);
        nested_items.data[1] = (Items.Model.ITEM_START_ID + 8);
        nested_items.data[2] = (Items.Model.ITEM_START_ID + 4);
        nested_items.data[3] = (Items.Model.ITEM_START_ID + 6);
        nested_items.data[4] = (Items.Model.ITEM_START_ID + 9);
        compare_instances (model, Items.Model.GROUP_START_ID + 1, nested_items, nested_item_parents);

        nested_items.append_val (Items.Model.GROUP_START_ID + 2);
        nested_item_parents.append_val (Items.Model.GROUP_START_ID + 1);
        assert (model.splice_new_item (
            Items.Model.GROUP_START_ID + 1, 1, group_candidate.clone ()) >= Items.Model.GROUP_START_ID);

        nested_items2.append_val (Items.Model.ITEM_START_ID + 10);
        nested_items2.append_val (Items.Model.ITEM_START_ID + 11);
        nested_items2.append_val (Items.Model.ITEM_START_ID + 12);
        nested_item_parents2.append_val (Items.Model.GROUP_START_ID + 2);
        nested_item_parents2.append_val (Items.Model.GROUP_START_ID + 2);
        nested_item_parents2.append_val (Items.Model.GROUP_START_ID + 2);
        assert (model.append_new_item (
            Items.Model.GROUP_START_ID + 2, candidate.clone ()) >= Items.Model.GROUP_START_ID);
        assert (model.append_new_item (
            Items.Model.GROUP_START_ID + 2, candidate.clone ()) >= Items.Model.GROUP_START_ID);
        assert (model.append_new_item (
            Items.Model.GROUP_START_ID + 2, candidate.clone ()) >= Items.Model.GROUP_START_ID);
        compare_instances (model, Items.Model.GROUP_START_ID + 2, nested_items2, nested_item_parents2);

        expected_items.remove_index (2);
        expected_item_parents.remove_index (2);
        assert (0 >= model.remove (Items.Model.GROUP_START_ID + 1, true));
        compare_instances (model, Items.Model.ORIGIN_ID, expected_items, expected_item_parents);

        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 7) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 8) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 4) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 6) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 9) == null);
        assert (model.instance_from_id (Items.Model.GROUP_START_ID + 1) == null);
        assert (model.instance_from_id (Items.Model.GROUP_START_ID + 2) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 10) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 11) == null);
        assert (model.instance_from_id (Items.Model.ITEM_START_ID + 12) == null);

        assert (model.node_from_id (Items.Model.ITEM_START_ID + 7) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 8) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 4) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 6) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 9) == null);
        assert (model.node_from_id (Items.Model.GROUP_START_ID + 1) == null);
        assert (model.node_from_id (Items.Model.GROUP_START_ID + 2) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 10) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 11) == null);
        assert (model.node_from_id (Items.Model.ITEM_START_ID + 12) == null);
    }
}

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

using Akira.Lib2;

public class Akira.Lib2ModelTests : Akira.TestSuite {
    public Lib2ModelTests () {
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
        assert (model.group_map.has_key(group_id));
        assert (model.group_nodes.has_key(group_id));
        assert (expected_items.length == expected_item_parents.length);
    
        var parent_group = model.group_nodes[group_id];
    
        for (var i = 0; i < expected_items.length; ++i) {
            var expected_id = expected_items.index(i);
            var child = parent_group.children.index(i);
    
            assert(parent_group.instance.children[i] == expected_id);
            assert(child.id == expected_id);
            assert(child.instance.id == expected_id);
            assert(child.parent.instance.id == group_id);
        }
    }

    public void origin_splice_extripate () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();
    
        // bad target parent
        assert (-1 == model.splice_new_item (0, 1, new Items.ModelItem.dummy_item ()));
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        var candidate = new Items.ModelItem.dummy_item ();
    
        // splice item at zero location in empty origin
        assert (model.splice_new_item (Items.Model.origin_id, 0, candidate.clone ()) >= Items.Model.item_start_id);
        expected_items.append_val (Items.Model.item_start_id + 1);
        expected_item_parents.append_val (Items.Model.origin_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    
        // splice item after the previous one in the origin
        assert (model.splice_new_item (Items.Model.origin_id, 1, candidate.clone ()) >= Items.Model.item_start_id);
        expected_items.append_val (Items.Model.item_start_id + 2);
        expected_item_parents.append_val (Items.Model.origin_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    
        // splice item at zero location in non-empty origin
        assert (model.splice_new_item (Items.Model.origin_id, 0, candidate.clone ()) >= Items.Model.item_start_id);
        expected_items.insert_val (0, Items.Model.item_start_id + 3);
        expected_item_parents.insert_val (0, Items.Model.origin_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    
        // invalid parent to extripate
        assert (-1 == model.extripate (-1, 3, true));
        assert (-1 == model.extripate (Items.Model.item_start_id + 2, 3, true));
        assert (-1 == model.extripate (Items.Model.origin_id, 3, true));
        assert (-1 == model.extripate (Items.Model.origin_id, 4, true));
    
        // extripate second item in origin
        assert (0 == model.extripate (Items.Model.origin_id, 1, true));
        expected_items.remove_index (1);
        expected_item_parents.remove_index (1);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    
        // extripate second item in origin
        assert (0 == model.extripate (Items.Model.origin_id, 1, true));
        expected_items.remove_index (1);
        expected_item_parents.remove_index (1);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    }

    public void origin_move () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();

        var candidate = new Items.ModelItem.dummy_item ();
    
        expected_items.append_val (Items.Model.item_start_id + 1);
        expected_items.append_val (Items.Model.item_start_id + 2);
        expected_items.append_val (Items.Model.item_start_id + 3);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_item_parents.append_val (Items.Model.origin_id);
        assert (model.splice_new_item (Items.Model.origin_id, 0, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 1, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 2, candidate.clone ()) >= Items.Model.item_start_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    
        // self move -- do nothing;
        assert (0 == model.move_items (Items.Model.origin_id, 0, 0, 1, true));

        // moves that don't change the topology -- do nothing;
        assert (0 == model.move_items (Items.Model.origin_id, 0, 0, -1, true));
        assert (0 == model.move_items (Items.Model.origin_id, 0, 0, 0, true));
        assert (0 == model.move_items (Items.Model.origin_id, 0, 2, 2, true));

        // invalid moves -- do nothing
        assert (-1 == model.move_items (Items.Model.origin_id, 4, 0, 1, true));
        assert (-1 == model.move_items (Items.Model.origin_id, 2, 0, 4, true));
        assert (-1 == model.move_items (Items.Model.origin_id, 3, 0, 1, true));
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.origin_id, 0, 2, 1, true));
        expected_items.data[0] = (Items.Model.item_start_id + 2);
        expected_items.data[1] = (Items.Model.item_start_id + 3);
        expected_items.data[2] = (Items.Model.item_start_id + 1);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.origin_id, 0, 2, 1, true));
        assert (1 == model.move_items (Items.Model.origin_id, 0, 2, 1, true));
        expected_items.data[0] = (Items.Model.item_start_id + 1);
        expected_items.data[1] = (Items.Model.item_start_id + 2);
        expected_items.data[2] = (Items.Model.item_start_id + 3);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        // prepare for more complicated rotations
        assert (model.splice_new_item (Items.Model.origin_id, 3, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 4, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 5, candidate.clone ()) >= Items.Model.item_start_id);
        expected_items.append_val (Items.Model.item_start_id + 4);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_items.append_val (Items.Model.item_start_id + 5);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_items.append_val (Items.Model.item_start_id + 6);
        expected_item_parents.append_val (Items.Model.origin_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.origin_id, 0, 2, 3, true));
        expected_items.data[0] = (Items.Model.item_start_id + 4);
        expected_items.data[1] = (Items.Model.item_start_id + 5);
        expected_items.data[2] = (Items.Model.item_start_id + 1);
        expected_items.data[3] = (Items.Model.item_start_id + 2);
        expected_items.data[4] = (Items.Model.item_start_id + 3);
        expected_items.data[5] = (Items.Model.item_start_id + 6);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.origin_id, 2, 0, 3, true));
        expected_items.data[0] = (Items.Model.item_start_id + 1);
        expected_items.data[1] = (Items.Model.item_start_id + 2);
        expected_items.data[2] = (Items.Model.item_start_id + 3);
        expected_items.data[3] = (Items.Model.item_start_id + 4);
        expected_items.data[4] = (Items.Model.item_start_id + 5);
        expected_items.data[5] = (Items.Model.item_start_id + 6);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (1 == model.move_items (Items.Model.origin_id, 2, 3, 3, true));
        expected_items.data[0] = (Items.Model.item_start_id + 1);
        expected_items.data[1] = (Items.Model.item_start_id + 2);
        expected_items.data[2] = (Items.Model.item_start_id + 6);
        expected_items.data[3] = (Items.Model.item_start_id + 3);
        expected_items.data[4] = (Items.Model.item_start_id + 4);
        expected_items.data[5] = (Items.Model.item_start_id + 5);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);
    }

    public void nested_ops () {
        var model = new Items.Model ();
        var expected_items = new GLib.Array<int?> ();
        var expected_item_parents = new GLib.Array<int?> ();

        var nested_items = new GLib.Array<int?> ();
        var nested_item_parents = new GLib.Array<int?> ();

        var nested_items2 = new GLib.Array<int?> ();
        var nested_item_parents2 = new GLib.Array<int?> ();

        var candidate = new Items.ModelItem.dummy_item ();
        var group_candidate = new Items.ModelItem.dummy_group ();
    
        expected_items.append_val (Items.Model.item_start_id + 1);
        expected_items.append_val (Items.Model.item_start_id + 2);
        expected_items.append_val (Items.Model.item_start_id + 3);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_item_parents.append_val (Items.Model.origin_id);
        expected_item_parents.append_val (Items.Model.origin_id);
        assert (model.splice_new_item (Items.Model.origin_id, 0, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 1, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.origin_id, 2, candidate.clone ()) >= Items.Model.item_start_id);
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        expected_items.insert_val (2, Items.Model.group_start_id + 1);
        expected_item_parents.append_val (Items.Model.origin_id);
        assert (model.splice_new_item (Items.Model.origin_id, 2, group_candidate.clone ()) >= Items.Model.group_start_id);

        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        nested_items.append_val (Items.Model.item_start_id + 4);
        nested_items.append_val (Items.Model.item_start_id + 5);
        nested_items.append_val (Items.Model.item_start_id + 6);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);

        assert (model.splice_new_item (Items.Model.group_start_id + 1, 0, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 1, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 2, candidate.clone ()) >= Items.Model.item_start_id);

        compare_instances (model, Items.Model.group_start_id + 1, nested_items, nested_item_parents);

        nested_items.remove_index (1);
        nested_item_parents.remove_index (1);
        assert (0 == model.extripate (Items.Model.group_start_id + 1, 1, true));

        compare_instances (model, Items.Model.group_start_id + 1, nested_items, nested_item_parents);

        nested_items.append_val (Items.Model.item_start_id + 7);
        nested_items.append_val (Items.Model.item_start_id + 8);
        nested_items.append_val (Items.Model.item_start_id + 9);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 2, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 3, candidate.clone ()) >= Items.Model.item_start_id);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 4, candidate.clone ()) >= Items.Model.item_start_id);

        compare_instances (model, Items.Model.group_start_id + 1, nested_items, nested_item_parents);

        assert (1 == model.move_items (Items.Model.group_start_id + 1, 2, 0, 2, true));
        nested_items.data[0] = (Items.Model.item_start_id + 7);
        nested_items.data[1] = (Items.Model.item_start_id + 8);
        nested_items.data[2] = (Items.Model.item_start_id + 4);
        nested_items.data[3] = (Items.Model.item_start_id + 6);
        nested_items.data[4] = (Items.Model.item_start_id + 9);
        compare_instances (model, Items.Model.group_start_id + 1, nested_items, nested_item_parents);

        nested_items.append_val (Items.Model.group_start_id + 2);
        nested_item_parents.append_val (Items.Model.group_start_id + 1);
        assert (model.splice_new_item (Items.Model.group_start_id + 1, 1, group_candidate.clone ()) >= Items.Model.group_start_id);

        nested_items2.append_val (Items.Model.item_start_id + 10);
        nested_items2.append_val (Items.Model.item_start_id + 11);
        nested_items2.append_val (Items.Model.item_start_id + 12);
        nested_item_parents2.append_val (Items.Model.group_start_id + 2);
        nested_item_parents2.append_val (Items.Model.group_start_id + 2);
        nested_item_parents2.append_val (Items.Model.group_start_id + 2);
        assert (model.append_new_item (Items.Model.group_start_id + 2, candidate.clone ()) >= Items.Model.group_start_id);
        assert (model.append_new_item (Items.Model.group_start_id + 2, candidate.clone ()) >= Items.Model.group_start_id);
        assert (model.append_new_item (Items.Model.group_start_id + 2, candidate.clone ()) >= Items.Model.group_start_id);
        compare_instances (model, Items.Model.group_start_id + 2, nested_items2, nested_item_parents2);

        expected_items.remove_index (2);
        expected_item_parents.remove_index (2);
        assert (0 >= model.remove (Items.Model.group_start_id + 1, true));
        compare_instances (model, Items.Model.origin_id, expected_items, expected_item_parents);

        assert (model.instance_from_id (Items.Model.item_start_id + 7) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 8) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 4) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 6) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 9) == null);
        assert (model.instance_from_id (Items.Model.group_start_id + 1) == null);
        assert (model.instance_from_id (Items.Model.group_start_id + 2) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 10) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 11) == null);
        assert (model.instance_from_id (Items.Model.item_start_id + 12) == null);

        assert (model.node_from_id (Items.Model.item_start_id + 7) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 8) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 4) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 6) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 9) == null);
        assert (model.node_from_id (Items.Model.group_start_id + 1) == null);
        assert (model.node_from_id (Items.Model.group_start_id + 2) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 10) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 11) == null);
        assert (model.node_from_id (Items.Model.item_start_id + 12) == null);
    }
}

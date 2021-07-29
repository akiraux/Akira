/*
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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

/*
 * Utility to handle some model operations
 */
 public class Akira.Utils.ModelUtil : Object {

    public delegate void OnSubtreeCloned (int id);

    /*
     * Clones an instance with `source_id` from a source model, into a target model into a specific
     * group with id `tagret_group_id`.
     * Cloning is recursive, so all dependencies are copied over.
     * Return 0 on success.
     */
     public static int clone_from_model (
         Lib2.Items.Model source_model,
         int source_id,
         Lib2.Items.Model target_model,
         int target_group_id,
         OnSubtreeCloned? on_subtree_cloned = null
    ) {
        var target_node = target_model.node_from_id (target_group_id);
        if (target_node == null || !target_node.instance.is_group ()) {
            return -1;
        }

        var source_node = source_model.node_from_id (source_id);
        if (source_node == null) {
            return -1;
        }

        var new_id = recursive_clone (source_node, target_node, target_model);

        if (new_id >= Lib2.Items.Model.group_start_id && on_subtree_cloned != null) {
            on_subtree_cloned (new_id);
        }

        return 0;
    }

    private static int recursive_clone (
        Lib2.Items.ModelNode source_node,
        Lib2.Items.ModelNode target_node,
        Lib2.Items.Model target_model
    ) {
        var new_id = target_model.append_new_item (target_node.id, source_node.instance.item.clone ());

        if (source_node.instance.is_group ()) {
            foreach (var child in source_node.children.data) {
                recursive_clone (child, target_model.node_from_id (new_id), target_model);
            }
        }

        return new_id;
    }
 }
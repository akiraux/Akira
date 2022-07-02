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
        Lib.Items.Model source_model,
        Gee.Map.Entry<Lib.Items.PositionKey, int> source,
        Lib.Items.Model target_model,
        int target_group_id
    ) {
        var target_node = target_model.node_from_id (target_group_id);
        if (target_node == null || !target_node.instance.is_group) {
            return -1;
        }

        var source_node = source_model.node_from_id (source.value);
        if (source_node == null) {
            return -1;
        }

        source_node.pos_in_parent = source.key.pos_in_parent;
        recursive_clone (source_node, target_node, target_model);

        return 0;
    }

    /*
     * Pastes an instance with `source_id` from the copy model, into a target model into a specific
     * group with id `tagret_group_id`.
     * If the `in_place` is true, the cloned node is appended above the source node.
     * TODO: If the `in_place` is false, we should paste the node at the center of the viewport.
     * Cloning is recursive, so all dependencies are copied over.
     * Return 0 on success.
     */
    public static int paste_from_model (
        Lib.Items.Model source_model,
        int source_id,
        Lib.Items.Model target_model,
        int target_group_id,
        OnSubtreeCloned on_subtree_cloned,
        bool in_place = false
    ) {
        var target_node = target_model.node_from_id (target_group_id);
        if (target_node == null || !target_node.instance.is_group) {
            return -1;
        }

        var source_node = source_model.node_from_id (source_id);
        if (source_node == null) {
            return -1;
        }

        if (!in_place) {
            // Reset the position to -1 to let the cloned node be appended above
            // all available child nodes.
            source_node.pos_in_parent = -1;
        } else {
            // Increase the position by one to let the cloned node be appended
            // above the source node.
            source_node.pos_in_parent += 1;
        }

        var new_id = recursive_clone (source_node, target_node, target_model);
        if (new_id >= Lib.Items.Model.GROUP_START_ID) {
            on_subtree_cloned (new_id);
        }

        return 0;
    }

    private static int recursive_clone (
        Lib.Items.ModelNode source_node,
        Lib.Items.ModelNode target_node,
        Lib.Items.Model target_model
    ) {
        var new_id = target_model.append_new_item (
            target_node.id,
            source_node.instance.clone (false),
            source_node.pos_in_parent
        );

        if (source_node.instance.is_group) {
            foreach (var child in source_node.children.data) {
                recursive_clone (child, target_model.node_from_id (new_id), target_model);
            }
        }

        return new_id;
    }
 }

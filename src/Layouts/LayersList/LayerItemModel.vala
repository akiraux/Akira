/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * Simple Object to be handled by the LayersListBoxModel and to give easy access
 * the attributes of the Lib.Items.ModelInstance.
 */
public class Akira.Layouts.LayersList.LayerItemModel : GLib.Object {
    public int service_uid { get; construct; }
    public unowned Lib.Items.ModelInstance? node;

    public int id {
        get {
            return node.id;
        }
    }
    /*
     * Control the name of the item.
     */
    public string name {
        owned get {
            return node.id.to_string (); // Temporarily use the ID.
        }
    }

    /*
     * Control the hidden/visible state of the item.
     */
    // TODO.

    /*
     * Control the locked/unlocked state of the item.
     */
    public bool locked {
        get {
            return node.components.layer.locked;
        }
    }

    /*
     * Control the selected state of the item.
     */
    public bool selected {
        get {
            return node.components.layer.selected;
        }
    }

    /*
     * If the node type is an Artboard.
     */
    public bool is_artboard {
        get {
            return node.type is Lib.Items.ModelTypeArtboard;
        }
    }

    /*
     * If the node type is a Group.
     */
    public bool is_group {
        get {
            return node.type is Lib.Items.ModelTypeGroup;
        }
    }

    public LayerItemModel (Lib.Items.ModelInstance node, int service_uid) {
        Object (service_uid: service_uid);
        update_node (node);
    }

    private void update_node (Lib.Items.ModelInstance new_node) {
        node = new_node;
    }
}

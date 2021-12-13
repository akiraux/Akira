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
 * the attributes of the Lib.Items.ModelNode.
 */
public class Akira.Layouts.LayersList.LayerItemModel : GLib.Object {
    private unowned Akira.Lib.ViewCanvas _view_canvas;

    public int service_uid { get; construct; }
    private Lib.Items.ModelInstance _cached_instance;

    public int id {
        get {
            return _cached_instance.id;
        }
    }
    /*
     * Control the name of the item.
     */
    public string name {
        owned get {
            return _cached_instance.components.name.name;
        }
        set {
            if (_cached_instance.components.name.name == value) {
                return;
            }

            unowned var im = _view_canvas.items_manager;
            var node = im.item_model.node_from_id (_cached_instance.id);
            assert (node != null);

            node.instance.components.name = new Lib.Components.Name (value, id.to_string ());
            im.item_model.mark_node_name_dirty (node);
            im.compile_model ();
        }
    }

    public string icon {
        get {
            unowned var type = _cached_instance.type;
            if (type is Lib.Items.ModelTypeRect) {
                return "shape-rectangle-symbolic";
            } else if (type is Lib.Items.ModelTypeEllipse) {
                return "shape-circle-symbolic";
            } else if (type is Lib.Items.ModelTypePath) {
                return "segment-curve-symbolic";
            } else if (type is Lib.Items.ModelTypeGroup) {
                return "folder-symbolic";
            }
            return "";
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
            return _cached_instance.components.layer.locked;
        }
    }

    /*
     * Control the selected state of the item.
     */
    public bool selected {
        get {
            return _cached_instance.components.layer.selected;
        }
    }

    /*
     * If the instance type is an Artboard.
     */
    public bool is_artboard {
        get {
            return _cached_instance.type is Lib.Items.ModelTypeArtboard;
        }
    }

    /*
     * If the instance type is a Group.
     */
    public bool is_group {
        get {
            return _cached_instance.type is Lib.Items.ModelTypeGroup;
        }
    }

    public int[] children {
        owned get {
            return _cached_instance.children;
        }
    }

    public int parent_uid {
        get {
            unowned var im = _view_canvas.items_manager;
            var node = im.item_model.node_from_id (_cached_instance.id);
            assert (node != null);

            return node.parent.id;
        }
    }

    public int ancestors_size {
        get {
            unowned var im = _view_canvas.items_manager;
            var node = im.item_model.node_from_id (_cached_instance.id);
            assert (node != null);

            return node.get_ancestors_size ();
        }
    }

    public LayerItemModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode node, int service_uid) {
        Object (service_uid: service_uid);
        update_node (node);
        _view_canvas = view_canvas;
    }

    private void update_node (Lib.Items.ModelNode new_node) {
        _cached_instance = new_node.instance;
    }
}

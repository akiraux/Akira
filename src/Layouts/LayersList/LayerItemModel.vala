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
            im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_NAME);
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
            } else if (type is Lib.Items.ModelTypeText) {
                return "shape-text-symbolic";
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
        set {
            if (_cached_instance.components.layer.locked == value) {
                return;
            }

            // If the layer is being locked we need to remove it from the
            // current selection if needed.
            if (value) {
                unowned var sm = _view_canvas.selection_manager;
                sm.remove_from_selection (id);
                sm.selection_modified_external ();
            }

            unowned var im = _view_canvas.items_manager;
            var node = im.item_model.node_from_id (_cached_instance.id);
            assert (node != null);

            node.instance.components.layer = new Lib.Components.Layer (value);
            // If the layer is a group we need to update the locked state on
            // all of its children.
            if (node.children != null) {
                _view_canvas.window.main_window.set_children_locked (node.get_children_ids (), value);
            }
        }
    }

    /*
     * If the instance type is an Artboard.
     */
    public bool is_artboard {
        get {
            return _cached_instance.is_artboard;
        }
    }

    /*
     * If the instance type is a Group.
     */
    public bool is_group {
        get {
            return _cached_instance.is_group;
        }
    }

    public int[] get_children () {
        return _cached_instance.children;
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

    // Always show child layers when a new artboard or group is created.
    private bool _children_visible = true;
    public bool children_visible {
        get {
            return _children_visible;
        }
        set {
            if (value == _children_visible) {
                return;
            }
            _children_visible = value;

            // No need to update the layers UI if this model is not a group or
            // an artboard.
            if (!is_group && !is_artboard) {
                return;
            }

            var array = new GLib.Array<int> ();
            array.data = get_children ();
            // Trigger the showing or hiding of all child layers.
            if (_children_visible) {
                _view_canvas.window.main_window.add_layers (array);
            } else {
                _view_canvas.window.main_window.remove_layers (array);
            }
        }
    }

    public LayerItemModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode node) {
        update_node (node);
        _view_canvas = view_canvas;
    }

    private void update_node (Lib.Items.ModelNode new_node) {
        _cached_instance = new_node.instance;
    }
}

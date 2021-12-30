
/**
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

/**
 * Utility providing functionality for aligning items
 */
public class Akira.Utils.ItemAlignment : Object {
    /*
     * Direction along which items should align.
     */
    public enum AlignmentDirection {
        RIGHT,
        LEFT,
        TOP,
        BOTTOM,
        VCENTER,
        HCENTER,
    }

    /*
     * Type of alignment algorithm to use for choosing bounds to align to.
     */
    public enum AlignmentType {
        AUTO,
        FIRST_SELECTED,
        LAST_SELECTED,
    }

    /*
     * Align a selection based on a direction and the type of alignment.
     */
    public static void align_selection (
        Lib.Items.NodeSelection selection,
        AlignmentDirection direction,
        AlignmentType type,
        Lib.ViewCanvas view_canvas
    ) {
        if (selection.count () <= 1) {
            return;
        }

        var align_to = Geometry.Rectangle.empty ();
        if (!populate_alignment (selection, type, ref align_to)) {
            return;
        }

        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        unowned var items_manager = view_canvas.items_manager;
        unowned var model = items_manager.item_model;

        bool something_moved = false;
        switch (direction) {
            case Utils.ItemAlignment.AlignmentDirection.LEFT:
                something_moved = align_selection_to_left (selection, align_to.left, model);
                break;
            case Utils.ItemAlignment.AlignmentDirection.RIGHT:
                something_moved = align_selection_to_right (selection, align_to.right, model);
                break;
            case Utils.ItemAlignment.AlignmentDirection.TOP:
                something_moved = align_selection_to_top (selection, align_to.top, model);
                break;
            case Utils.ItemAlignment.AlignmentDirection.BOTTOM:
                something_moved = align_selection_to_bottom (selection, align_to.bottom, model);
                break;
            case Utils.ItemAlignment.AlignmentDirection.VCENTER:
                something_moved = align_selection_to_vcenter (selection, align_to.center_y, model);
                break;
            case Utils.ItemAlignment.AlignmentDirection.HCENTER:
                something_moved = align_selection_to_hcenter (selection, align_to.center_x, model);
                break;
            default:
                break;
        }

        if (something_moved) {
            items_manager.compile_model ();
            view_canvas.window.event_bus.update_snap_decorators ();
        }
    }

    private static bool populate_alignment (
        Lib.Items.NodeSelection selection,
        AlignmentType type,
        ref Geometry.Rectangle align_to
    ) {
        bool found_bound = false;

        switch (type) {
            case AlignmentType.AUTO:
                align_to.left = double.MAX;
                align_to.right = double.MIN;
                align_to.top = double.MAX;
                align_to.bottom = double.MIN;

                foreach (var node in selection.nodes.values) {
                    unowned var bb = node.node.instance.bounding_box;
                    align_to.left = double.min (align_to.left, bb.left);
                    align_to.right = double.max (align_to.right, bb.right);
                    align_to.top = double.min (align_to.top, bb.top);
                    align_to.bottom = double.max (align_to.bottom, bb.bottom);
                    found_bound = true;
                }

                break;
            case AlignmentType.FIRST_SELECTED:
                uint last_sid = uint.MAX;
                foreach (var node in selection.nodes.values) {
                    if (node.sid < last_sid) {
                        align_to = node.node.instance.bounding_box;
                        last_sid = node.sid;
                        found_bound = true;
                    }
                }

                break;
            case AlignmentType.LAST_SELECTED:
                uint last_sid = uint.MIN;
                foreach (var node in selection.nodes.values) {
                    if (node.sid > last_sid) {
                        align_to = node.node.instance.bounding_box;
                        last_sid = node.sid;
                        found_bound = true;
                    }
                }

                break;
            default:
                break;
        }

        return found_bound;
    }

    private static bool align_selection_to_left (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.left;
            if (diff != 0) {
                translate_node (node.node, diff, 0, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    private static bool align_selection_to_right (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.right;
            if (diff != 0) {
                translate_node (node.node, diff, 0, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    private static bool align_selection_to_top (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.top;
            if (diff != 0) {
                translate_node (node.node, 0, diff, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    private static bool align_selection_to_bottom (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.bottom;
            if (diff != 0) {
                translate_node (node.node, 0, diff, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    private static bool align_selection_to_vcenter (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.center_y;
            if (diff != 0) {
                translate_node (node.node, 0, diff, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    private static bool align_selection_to_hcenter (
        Lib.Items.NodeSelection selection,
        double align_to,
        Lib.Items.Model model
    ) {
        bool something_moved = false;
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.center_x;
            if (diff != 0) {
                translate_node (node.node, diff, 0, model);
                something_moved = true;
            }
        }

        return something_moved;
    }

    // Maybe move this and combine with TransformMode's
    private static void translate_node (Lib.Items.ModelNode node, double dx, double dy, Lib.Items.Model model) {
        unowned var inst = node.instance;
        inst.components.center = inst.components.center.translated (dx, dy);

        if (node.children != null && node.children.length > 0) {
            foreach (unowned var child in node.children.data) {
                translate_node (child, dx, dy, model);
            }
        }

        model.mark_node_geometry_dirty (node);
    }
}

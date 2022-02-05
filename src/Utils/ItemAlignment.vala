
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
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
        ANCHOR,
    }

    private class AlignOp {
        public Lib.Items.ModelNode node;
        public double dx;
        public double dy;

        public AlignOp (Lib.Items.ModelNode n, double dx, double dy) {
            this.node = n;
            this.dx = dx;
            this.dy = dy;
        }
    }

    /*
     * Align a selection based on a direction and the type of alignment.
     */
    public static void align_selection (
        Lib.Items.NodeSelection selection,
        AlignmentDirection direction,
        AlignmentType type,
        Lib.Items.ModelNode? anchor,
        Lib.ViewCanvas view_canvas,
        Utils.TrivialDelegate? prep_for_op
    ) {
        if (selection.count () <= 1) {
            return;
        }

        var align_to = Geometry.Rectangle.empty ();
        if (!populate_alignment (selection, type, anchor, ref align_to)) {
            return;
        }

        var blocker = new Lib.Managers.SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (blocker);

        unowned var items_manager = view_canvas.items_manager;
        unowned var model = items_manager.item_model;

        var operations = new Gee.ArrayList<AlignOp> ();

        switch (direction) {
            case Utils.ItemAlignment.AlignmentDirection.LEFT:
                align_selection_to_left (selection, align_to.left, operations);
                break;
            case Utils.ItemAlignment.AlignmentDirection.RIGHT:
                align_selection_to_right (selection, align_to.right, operations);
                break;
            case Utils.ItemAlignment.AlignmentDirection.TOP:
                align_selection_to_top (selection, align_to.top, operations);
                break;
            case Utils.ItemAlignment.AlignmentDirection.BOTTOM:
                align_selection_to_bottom (selection, align_to.bottom, operations);
                break;
            case Utils.ItemAlignment.AlignmentDirection.VCENTER:
                align_selection_to_vcenter (selection, align_to.center_y, operations);
                break;
            case Utils.ItemAlignment.AlignmentDirection.HCENTER:
                align_selection_to_hcenter (selection, align_to.center_x, operations);
                break;
            default:
                break;
        }

        if (operations.size == 0) {
            return;
        }

        if (prep_for_op != null) {
            prep_for_op ();
        }

        foreach (var op in operations) {
            translate_node (op.node, op.dx, op.dy, model);
        }

        items_manager.compile_model ();
        view_canvas.window.event_bus.update_snap_decorators ();
    }

    private static bool populate_alignment (
        Lib.Items.NodeSelection selection,
        AlignmentType type,
        Lib.Items.ModelNode? anchor,
        ref Geometry.Rectangle align_to
    ) {
        bool found_bounds = false;

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
                    found_bounds = true;
                }

                break;
            case AlignmentType.FIRST_SELECTED:
                uint last_sid = uint.MAX;
                foreach (var node in selection.nodes.values) {
                    if (node.sid < last_sid) {
                        align_to = node.node.instance.bounding_box;
                        last_sid = node.sid;
                        found_bounds = true;
                    }
                }

                break;
            case AlignmentType.LAST_SELECTED:
                uint last_sid = uint.MIN;
                foreach (var node in selection.nodes.values) {
                    if (node.sid > last_sid) {
                        align_to = node.node.instance.bounding_box;
                        last_sid = node.sid;
                        found_bounds = true;
                    }
                }

                break;
            case AlignmentType.ANCHOR:
                unowned var bb = anchor.instance.bounding_box;

                align_to.left = bb.left;
                align_to.right = bb.right;
                align_to.top = bb.top;
                align_to.bottom = bb.bottom;
                found_bounds = true;
                break;
            default:
                break;
        }

        return found_bounds;
    }

    private static void align_selection_to_left (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.left;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, diff, 0));
            }
        }
    }

    private static void align_selection_to_right (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.right;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, diff, 0));
            }
        }
    }

    private static void align_selection_to_top (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.top;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, 0, diff));
            }
        }
    }

    private static void align_selection_to_bottom (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.bottom;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, 0, diff));
            }
        }
    }

    private static void align_selection_to_vcenter (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.center_y;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, 0, diff));
            }
        }
    }

    private static void align_selection_to_hcenter (
        Lib.Items.NodeSelection selection,
        double align_to,
        Gee.ArrayList<AlignOp> operations
    ) {
        foreach (var node in selection.nodes.values) {
            unowned var inst = node.node.instance;
            var diff = align_to - inst.bounding_box.center_x;
            if (diff != 0) {
                operations.add (new AlignOp (node.node, diff, 0));
            }
        }
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

        model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_GEOMETRY);
    }
}

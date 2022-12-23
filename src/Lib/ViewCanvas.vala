/**
 * Copyright (c) 2019-2022 Alecaddd (https://alecaddd.com)
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
 *  Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 *  Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.ViewCanvas : ViewLayers.BaseCanvas {
    private const int SIZE = 30;
    public const double MIN_SCALE = 0.02;
    public const double MAX_SCALE = 50.0;
    public unowned Akira.Window window { get; construct; }

    public Geometry.Quad to_draw_1;
    public Geometry.Quad to_draw_2;
    public Geometry.Quad to_draw_3;
    public double debug_point1_x = 0;
    public double debug_point1_y = 0;
    public double debug_point2_x = 0;
    public double debug_point2_y = 0;

    public Lib.Managers.ItemsManager items_manager;
    public Lib.Managers.SelectionManager selection_manager;
    public Lib.Managers.ModeManager mode_manager;
    public Lib.Managers.HoverManager hover_manager;
    public Lib.Managers.NobManager nob_manager;
    public Lib.Managers.SnapManager snap_manager;
    public Lib.Managers.CopyManager copy_manager;
    public Lib.Managers.HistoryManager history_manager;

    private bool is_modifier_pressed (Gdk.ModifierIntent type) {
        Gdk.ModifierType state;
        Gdk.ModifierType mask;

        if (!Gtk.get_current_event_state (out state)) {
            return false;
        }

        mask = get_modifier_mask (type);
        return (state & mask) == mask;
    }

    public bool ctrl_is_pressed {
        get {
            return is_modifier_pressed (Gdk.ModifierIntent.MODIFY_SELECTION);
        }
    }
    public bool shift_is_pressed {
        get {
            return is_modifier_pressed (Gdk.ModifierIntent.EXTEND_SELECTION);
        }
    }
    public bool alt_is_pressed {
        get {
            return is_modifier_pressed (Gdk.ModifierIntent.SHIFT_GROUP);
        }
    }

    public double current_scale = 1.0;

    // RAIIify this?
    public bool holding = false;

    private Utils.Nobs.Nob hovered_nob = Utils.Nobs.Nob.NONE;
    private Gdk.CursorType current_cursor = Gdk.CursorType.ARROW;

    private ViewLayers.ViewLayerGrid grid_layout;

    // Keep track of the initial coords of the press event.
    private double initial_event_x;
    private double initial_event_y;

    // Keep track of a double clicked child item inside a group if we need to
    // enfoce the selection of a specific target.
    private int? enforced_target = null;

    public ViewCanvas (Akira.Window window) {
        Object (
            window: window,
            hadjustment : new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0),
            vadjustment : new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        );

        set_can_focus (true);
    }

    construct {
        events |= Gdk.EventMask.KEY_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
        events |= Gdk.EventMask.SCROLL_MASK;
        events |= Gdk.EventMask.SMOOTH_SCROLL_MASK;
        events |= Gdk.EventMask.TOUCHPAD_GESTURE_MASK;
        events |= Gdk.EventMask.TOUCH_MASK;

        items_manager = new Lib.Managers.ItemsManager (this);
        selection_manager = new Lib.Managers.SelectionManager (this);
        mode_manager = new Lib.Managers.ModeManager (this);
        hover_manager = new Lib.Managers.HoverManager (this);
        nob_manager = new Lib.Managers.NobManager (this);
        snap_manager = new Lib.Managers.SnapManager (this);
        copy_manager = new Lib.Managers.CopyManager (this);
        history_manager = new Lib.Managers.HistoryManager (this);

        grid_layout = new ViewLayers.ViewLayerGrid (
            0,
            0,
            Layouts.MainViewCanvas.CANVAS_SIZE,
            Layouts.MainViewCanvas.CANVAS_SIZE
        );

        grid_layout.add_to_canvas (ViewLayers.ViewLayer.GRID_LAYER_ID, this);
        grid_layout.set_visible (true);

        set_model_to_render (items_manager.item_model);

        window.event_bus.toggle_presentation_mode.connect (on_toggle_presentation_mode);

        window.event_bus.adjust_zoom.connect (trigger_adjust_zoom);

        window.event_bus.set_focus_on_canvas.connect (focus_canvas);
        window.event_bus.insert_item.connect (start_insert_mode);
        window.event_bus.update_snap_decorators.connect (on_update_snap_decorators);

        mode_manager.mode_changed.connect (interaction_mode_changed);
        items_manager.items_removed.connect (on_items_removed);
    }

    public bool block_ui = false;
    private void on_toggle_presentation_mode () {
        block_ui = !block_ui;
    }

    public signal void canvas_moved (double delta_x, double delta_y);
    public signal void canvas_scroll_set_origin (double origin_x, double origin_y);

    public void visible_bounds (
        ref double top,
        ref double left,
        ref double bottom,
        ref double right
    ) {
        top = vadjustment.value / current_scale;
        left = hadjustment.value / current_scale;
        bottom = top + get_allocated_height () / current_scale;
        right = left + get_allocated_width () / current_scale;
    }

    public void start_insert_mode (string insert_item_type) {
        var new_mode = new Akira.Lib.Modes.ItemInsertMode (this, insert_item_type);
        mode_manager.register_mode (new_mode);
    }

    public void interaction_mode_changed () {
        set_cursor_by_interaction_mode ();
    }

    public void set_cursor_by_interaction_mode () {
        hover_manager.remove_hover_effect ();
        Gdk.CursorType? new_cursor = mode_manager.active_cursor_type ();

        if (new_cursor == null) {
            var hover_cursor = Utils.Nobs.cursor_from_nob (hovered_nob);
            new_cursor = (hover_cursor == null) ? Gdk.CursorType.ARROW : hover_cursor;
        }

        if (current_cursor != new_cursor) {
            // debug (@"Changing cursor. $new_cursor");
            set_cursor (new_cursor);
        }
    }

    private void trigger_adjust_zoom (double new_scale, bool absolute, Geometry.Point? reference) {
        var initial_hx = hadjustment.get_value ();
        var initial_hy = vadjustment.get_value ();

        var local_hx = initial_hx / scale;
        var local_hy = initial_hy / scale;

        if (!absolute) {
            // Force the zoom value to 8% if we're currently at a 2% scale in order
            // to go back to 10% and increase from there.
            if (current_scale == MIN_SCALE && new_scale == 0.1) {
                new_scale = 0.08;
            }

            new_scale += current_scale;
        }

        new_scale = Utils.GeometryMath.clamp (new_scale, Lib.ViewCanvas.MIN_SCALE, Lib.ViewCanvas.MAX_SCALE);
        var zoom_diff = scale / new_scale;

        current_scale = new_scale;
        this.scale = new_scale;
        window.event_bus.zoom_changed (new_scale);

        if (reference == null) {
            hadjustment.set_value (local_hx * scale);
            vadjustment.set_value (local_hy * scale);
            return;
        }

        var ref_x = reference.x - initial_hx;
        var ref_y = reference.y - initial_hy;
        var offset_x = ref_x - ref_x * zoom_diff;
        var offset_y = ref_y - ref_y * zoom_diff;
        hadjustment.set_value (local_hx * scale + offset_x);
        vadjustment.set_value (local_hy * scale + offset_y);
    }

    public void focus_canvas () {
        grab_focus ();
    }

    public override bool key_press_event (Gdk.EventKey event) {
        if (mode_manager.key_press_event (event)) {
            return true;
        }

        switch (event.keyval) {
            case Gdk.Key.space:
                mode_manager.start_panning_mode ();
                if (mode_manager.key_press_event (event)) {
                    return true;
                }
                break;

            case Gdk.Key.Up:
            case Gdk.Key.Down:
            case Gdk.Key.Right:
            case Gdk.Key.Left:
                //window.event_bus.move_item_from_canvas (event);
                //window.event_bus.detect_artboard_change ();
                return true;

            case Gdk.Key.g:
                if (ctrl_is_pressed) {
                    items_manager.create_group_from_selection ();
                }
                break;
            default:
                break;
        }

        // TODO: Debuggging features, move this behind a pref.
        //  uint uppercase_keyval = Gdk.keyval_to_upper (event.keyval);
        //  if (uppercase_keyval == Gdk.Key.J) {
        //      window.event_bus.create_model_snapshot ("add debug items");
        //      items_manager.debug_add_rectangles (10000, true);
        //      return true;
        //  }
        //  if (uppercase_keyval == Gdk.Key.G) {
        //      window.event_bus.create_model_snapshot ("add debug group");
        //      items_manager.add_debug_group (300, 300, true);
        //      return true;
        //  }

        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        return mode_manager.key_release_event (event);
    }

    public override bool button_press_event (Gdk.EventButton event) {
        // Temporarily grab the focus when clicking on the canvas. This is a
        // workaround fix for the listbox stealing focus. To be removed.
        focus_canvas ();

        base.button_press_event (event);

        hover_manager.remove_hover_effect ();

        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        // Handle a double click event.
        if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
            handle_double_click_event (event);
            return true;
        }

        // Handle a mouse wheel/middle button press event.
        if (event.button == Gdk.BUTTON_MIDDLE) {
            mode_manager.start_panning_mode ();
            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

        if (mode_manager.button_press_event (event)) {
            return true;
        }

        if (handle_selection_press_event (event)) {
            return true;
        }

        var new_mode = new Lib.Modes.MultiSelectMode (this);
        mode_manager.register_mode (new_mode);

        mode_manager.button_press_event (event);

        return false;
    }

    /*
     * Check if a selection exists, and transform it appropriately, return true if
     * the event should be absorbed.
     */
    private bool handle_selection_press_event (Gdk.EventButton event) {
        // Register the initial click event coordinates.
        initial_event_x = event.x;
        initial_event_y = event.y;

        Lib.Items.ModelNode? target = null;
        var nob_clicked = nob_manager.hit_test (event.x, event.y);

        if (nob_clicked == Utils.Nobs.Nob.NONE) {
            // If no nob is selected, we test for an item.
            target = items_manager.node_at_canvas_position (
                event.x,
                event.y,
                Drawables.Drawable.HitTestType.SELECT
            );

            if (target != null) {
                selection_manager.ensure_correct_target (ref target);

                // Check if the clicked item is not already selected.
                if (!selection_manager.item_selected (target.id)) {
                    // Reset the selection if SHIFT isn't pressed.
                    if (!shift_is_pressed) {
                        selection_manager.reset_selection ();
                    }

                    selection_manager.add_to_selection (target.id);
                    selection_manager.selection_modified_external (true);
                } else if (shift_is_pressed) {
                    // Remove the item fom the current selection if SHIFT is pressed.
                    selection_manager.remove_from_selection (target.id);
                    selection_manager.selection_modified_external (true);
                } else if (ctrl_is_pressed) {
                    // If we already have a selection but CTRL is pressed, we should
                    // reset the selection and allow selecting the targeted element.
                    // AKA, we ignore a group selection.
                    selection_manager.reset_selection ();
                    selection_manager.add_to_selection (target.id);
                    selection_manager.selection_modified_external (true);
                }
            } else if (
                !selection_manager.selection.area ().contains (event.x, event.y) &&
                !selection_manager.selection.is_empty () &&
                !shift_is_pressed
            ) {
                // Selection area was not clicked, so we reset the selection if we have some.
                selection_manager.reset_selection ();
                selection_manager.selection_modified_external (true);
            }
        }

        // Enter transform mode if we have selected items and SHIFT is not pressed.
        if (!selection_manager.is_empty () && !shift_is_pressed) {
            var new_mode = new Lib.Modes.TransformMode (this, nob_clicked, true);
            mode_manager.register_mode (new_mode);

            if (mode_manager.button_press_event (event)) {
                return true;
            }
        }

        return false;
    }

    private void handle_double_click_event (Gdk.EventButton event) {
        enforced_target = null;
        Lib.Items.ModelNode? target = null;
        var nob_clicked = nob_manager.hit_test (event.x, event.y);

        // Bail out if the double click happened on a nob.
        if (nob_clicked != Utils.Nobs.Nob.NONE) {
            return;
        }

        // If no nob is selected, we test for an item.
        target = items_manager.node_at_canvas_position (
            event.x,
            event.y,
            Drawables.Drawable.HitTestType.SELECT
        );

        // Bail out if the double click happened on an empty area.
        if (target == null) {
            return;
        }

        if (target.instance.type is Lib.Items.ModelTypePath) {
            // If path edit mode is already active, propogate the event.
            if (mode_manager.active_mode_type == Modes.AbstractInteractionMode.ModeType.PATH_EDIT) {
                mode_manager.button_press_event (event);
            } else {
                var path_edit_mode = new Lib.Modes.PathEditMode (this, target.instance);
                path_edit_mode.toggle_functionality (false);
                mode_manager.register_mode (path_edit_mode);
            }
            return;
        }

        // If the double click happened on an item that is already selected and
        // all otehr previous conditions are false, check if this item is part
        // of a group and enforce its selection, meaning the user wants to access
        // the group's child nodes.
        if (selection_manager.item_selected (target.id)) {
            var old_target = target;
            target = Utils.ModelUtil.recursive_get_parent_target (target);

            if (target.instance.is_group) {
                enforced_target = old_target.id;
            }
        }
    }

    public override bool button_release_event (Gdk.EventButton event) {
        // Enforce the selection of a specific target if it was registered
        // during the double click event on a group.
        if (enforced_target != null) {
            selection_manager.reset_selection ();
            selection_manager.add_to_selection (enforced_target);
            enforced_target = null;
            if (mode_manager.button_release_event (event)) {
                return true;
            }
        }

        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        // Check if the there's no delta between the pressed and released event
        // and the SHIFT modifier is not pressed. If the SHIFT modifier is pressed
        // we're adding items to the selection so we don't need to do anything else.
        if (
            initial_event_x == event.x &&
            initial_event_y == event.y &&
            !shift_is_pressed
        ) {
            var count = selection_manager.count ();
            var target = items_manager.node_at_canvas_position (
                event.x,
                event.y,
                Drawables.Drawable.HitTestType.SELECT
            );

            // If the click happened on an item, we have multiple selected
            // items, and the clicked items is part of the selection, we need to
            // handle a few scenarios.
            if (
                target != null &&
                selection_manager.item_selected (target.id) &&
                count > 1 &&
                alt_is_pressed &&
                !ctrl_is_pressed
            ) {
                nob_manager.toggle_anchor_point (target.id);
            }

            // If the target is not null, shift is not pressed and the target is
            // not an artboard, check if the item belongs to an artboard which is
            // currently selected, and if so reset the selections and add that item.
            if (
                target != null &&
                !shift_is_pressed &&
                !target.instance.is_artboard
            ) {
                var artboard = Utils.ModelUtil.recursive_get_target_parent_artboard (target);
                if (artboard != null && selection_manager.item_selected (artboard.id)) {
                    selection_manager.reset_selection ();
                    selection_manager.add_to_selection (target.id);
                    selection_manager.selection_modified_external (true);
                }
            }

            // If the target is null and only 1 item is currently selected
            // check if the selected item is an artboard and deselected it if so.
            if (target == null && count == 1) {
                var selected = selection_manager.selection.first_node ();
                if (selected != null && selected.instance.is_artboard) {
                    selection_manager.reset_selection ();
                    selection_manager.selection_modified_external (true);
                }
            }

            // If the click happened on an empty area and we have multiple
            // selected items, deselect them all.
            if (target == null && count > 1) {
                selection_manager.reset_selection ();
                selection_manager.selection_modified_external (true);
            }
        }

        if (mode_manager.button_release_event (event)) {
            return true;
        }

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        event.x = event.x / current_scale;
        event.y = event.y / current_scale;

        if (mode_manager.motion_notify_event (event)) {
            return true;
        }

        var target_nob = nob_manager.hit_test (event.x, event.y);

        if (target_nob != Utils.Nobs.Nob.NONE) {
            hover_manager.remove_hover_effect ();
            if (hovered_nob != target_nob) {
                hovered_nob = target_nob;
                set_cursor_by_interaction_mode ();
            }
            return true;
        } else if (hovered_nob != Utils.Nobs.Nob.NONE) {
            hovered_nob = Utils.Nobs.Nob.NONE;
            set_cursor_by_interaction_mode ();
        }

        hover_manager.on_mouse_over (event.x, event.y);

        return false;
    }

    private void set_cursor (Gdk.CursorType? cursor_type) {
        current_cursor = (cursor_type == null ? Gdk.CursorType.ARROW : cursor_type);
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), current_cursor);
        get_window ().set_cursor (cursor);
    }

    // #TODO temporary
    public override bool draw (Cairo.Context ctx) {
        base.draw (ctx);

        // Draw damage
        //var r = GLib.Random.double_range (0, 1.0);
        //var g = GLib.Random.double_range (0, 1.0);
        //var b = GLib.Random.double_range (0, 1.0);
        //var col = Gdk.RGBA () { red = r, green = g, blue = b, alpha = 0.3};
        //var xadj = hadjustment.value;
        //var yadj = vadjustment.value;

        //var cs = current_scale;

        //ctx.save ();
        //ctx.rectangle (xadj + 0, xadj + 0, xadj + 3000, xadj + 3000);
        //ctx.set_source_rgba (r, g, b, 0.3);
        //ctx.fill ();

        //ctx.restore ();

        //draw_debug_rect (ctx, to_draw_1.bounding_box, Gdk.RGBA () { red = 1.0, green = 0.0, blue = 0.0, alpha = 1.0});
        draw_debug_rotated_rect (ctx, to_draw_1, Gdk.RGBA () { red = 0.0, green = 1.0, blue = 0.5, alpha = 1.0});

        //draw_debug_rect (ctx, to_draw_2.bounding_box, Gdk.RGBA () { red = 5.0, green = 0.0, blue = 0.0, alpha = 1.0});
        draw_debug_rotated_rect (ctx, to_draw_2, Gdk.RGBA () { red = 1.0, green = 0.0, blue = 0.0, alpha = 1.0});

        draw_debug_rotated_rect (ctx, to_draw_3, Gdk.RGBA () { red = 0.0, green = 0.0, blue = 1.0, alpha = 1.0});

        if (debug_point1_x > 0 && debug_point1_y > 0) {
            draw_debug_point (
                ctx,
                debug_point1_x,
                debug_point1_y,
                Gdk.RGBA () { red = 0.0, green = 1.0, blue = 0.5, alpha = 1.0}
            );
        }

        if (debug_point2_x > 0 && debug_point2_y > 0) {
            draw_debug_point (
                ctx,
                debug_point2_x,
                debug_point2_y,
                Gdk.RGBA () { red = 1.0, green = 0.0, blue = 0.0, alpha = 1.0}
            );
        }

        return false;
    }

    public void draw_debug_point (Cairo.Context ctx, double point_x, double point_y, Gdk.RGBA color) {
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        var cs = current_scale;

        ctx.save ();
        point_x *= cs;
        point_y *= cs;

        ctx.move_to (point_x, point_y);
        ctx.arc (point_x - xadj, point_y - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        ctx.fill ();
        ctx.restore ();
    }

    public void draw_debug_rect (Cairo.Context ctx, Geometry.Rectangle rect, Gdk.RGBA color) {
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        var cs = current_scale;

        ctx.save ();
        var top = rect.top * cs;
        var left = rect.left * cs;
        var bottom = rect.bottom * cs;
        var right = rect.right * cs;

        var width = right - left;
        var height = bottom - top;
        ctx.move_to (left - xadj, top - yadj);
        ctx.rel_line_to (width, 0);
        ctx.rel_line_to (0, height);
        ctx.rel_line_to (-width, 0);
        ctx.close_path ();
        ctx.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        ctx.stroke ();

        ctx.restore ();
    }

    public void draw_debug_rotated_rect (Cairo.Context ctx, Geometry.Quad rect, Gdk.RGBA color) {
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        var cs = current_scale;

        var x0 = rect.tl_x * cs - xadj;
        var y0 = rect.tl_y * cs - yadj;
        var x1 = rect.tr_x * cs - xadj;
        var y1 = rect.tr_y * cs - yadj;
        var x2 = rect.bl_x * cs - xadj;
        var y2 = rect.bl_y * cs - yadj;
        var x3 = rect.br_x * cs - xadj;
        var y3 = rect.br_y * cs - yadj;

        ctx.save ();
        ctx.move_to (x0, y0);
        ctx.set_source_rgba (color.red, color.green, color.blue, color.alpha);
        ctx.line_to (x1, y1);
        ctx.line_to (x3, y3);
        ctx.line_to (x2, y2);
        ctx.close_path ();
        ctx.stroke ();
        ctx.restore ();
    }

    public void draw_debug_info (Cairo.Context ctx, Lib.Items.ModelInstance instance) {
        /*
        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        var cs = current_scale;

        ctx.save ();
        var cg = item.components.compiled_geometry;
        var top = cg.bb_top () * cs;
        var left = cg.bb_left () * cs;
        var bottom = cg.bb_bottom () * cs;
        var right = cg.bb_right () * cs;

        var width = right - left;
        var height = bottom - top;
        ctx.move_to (left - xadj, top - yadj);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.rel_line_to (width, 0);
        ctx.rel_line_to (0, height);
        ctx.rel_line_to (-width, 0);
        ctx.close_path ();
        ctx.stroke ();

        ctx.arc (cg.x0 () * cs - xadj, cg.y0 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x1 () * cs - xadj, cg.y1 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x2 () * cs - xadj, cg.y2 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();
        ctx.arc (cg.x3 () * cs - xadj, cg.y3 () * cs - yadj, 5, 0, 2.0 * GLib.Math.PI);
        ctx.fill ();

        ctx.restore ();
        */
    }

    public void draw_debug_selection (Cairo.Context ctx) {
        /*
        if (selection_manager.selection.is_empty ()) {
            return;
        }
        var cs = current_scale;

        var xadj = hadjustment.value;
        var yadj = vadjustment.value;

        double x0 = 0;
        double y0 = 0;
        double x1 = 0;
        double y1 = 0;
        double x2 = 0;
        double y2 = 0;
        double x3 = 0;
        double y3 = 0;
        double rotation = 0;

        selection_manager.selection.coordinates (
            out x0,
            out y0,
            out x1,
            out y1,
            out x2,
            out y2,
            out x3,
            out y3,
            out rotation
        );
        x0 = x0 * cs - xadj;
        y0 = y0 * cs - yadj;
        x1 = x1 * cs - xadj;
        y1 = y1 * cs - yadj;
        x2 = x2 * cs - xadj;
        y2 = y2 * cs - yadj;
        x3 = x3 * cs - xadj;
        y3 = y3 * cs - yadj;

        ctx.save ();
        ctx.move_to (x0, y0);
        ctx.set_source_rgba (1.0, 0.0, 0.0, 1.0);
        ctx.line_to (x1, y1);
        ctx.line_to (x3, y3);
        ctx.line_to (x2, y2);
        ctx.close_path ();
        ctx.stroke ();
        ctx.restore ();
        */
    }

    /*
     * Will update snap decorators if necessary.
     */
    private void on_update_snap_decorators () {
        var extra_context = mode_manager.active_mode_extra_context ();
        if (extra_context is Akira.Lib.Modes.TransformMode.TransformExtraContext) {
            snap_manager.generate_decorators (
                ((Lib.Modes.TransformMode.TransformExtraContext) extra_context).snap_guide_data);
        } else if (snap_manager.is_active ()) {
            snap_manager.reset_decorators ();
        }
    }

    /*
     * Helper method to interact with the layers panel without publicly exposing it.
     */
    private void on_items_removed (GLib.Array<int> ids) {
        window.main_window.remove_layers (ids);
    }
}

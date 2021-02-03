/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

using Akira.Lib.Models;
using Akira.Lib.Managers;

public class Akira.Utils.AffineTransform : Object {
    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const double ROTATION_FIXED_STEP = 15.0;

    private static double temp_rotation = 0.0;
    private static double prev_rotation_difference = 0.0;

    // Private attributes for item Cairo.Matrix.
    private static double old_x;
    private static double old_y;
    private static double old_scale;
    private static double old_rotation;

    private static Goo.CanvasBounds bounds;

    public static HashTable<string, double?> get_position (CanvasItem item) {
        HashTable<string, double?> array = new HashTable<string, double?> (str_hash, str_equal);
        double item_x = item.bounds_manager.x1;
        double item_y = item.bounds_manager.y1;

        if (item.artboard != null) {
            item_x -= item.artboard.bounds.x1;
            item_y -= item.artboard.bounds.y1 + item.artboard.get_label_height ();
        }

        array.insert ("x", item_x);
        array.insert ("y", item_y);
        return array;
    }

    public static void set_position (CanvasItem item, double? x = null, double? y = null) {
        var diff_x = 0.0;
        var diff_y = 0.0;

        if (item.artboard != null) {
            // Account for the different between the current position and the
            // the item's bounds.
            diff_x = item.bounds_manager.x1 - item.artboard.bounds.x1 - item.relative_x;
            diff_y = item.bounds_manager.y1 - item.artboard.bounds.y1
                     - item.artboard.get_label_height () - item.relative_y;

            item.relative_x = x != null ? x - diff_x : item.relative_x;
            item.relative_y = y != null ? y - diff_y : item.relative_y;
            return;
        }

        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        // Account for the item rotation and get the difference between
        // its bounds and matrix coordinates.
        diff_x = item.bounds_manager.x1 - matrix.x0;
        diff_y = item.bounds_manager.y1 - matrix.y0;

        matrix.x0 = x != null ? x - diff_x : matrix.x0;
        matrix.y0 = y != null ? y - diff_y : matrix.y0;

        item.set_transform (matrix);
        item.bounds_manager.update ();
    }

    /**
     * Move the item based on the mouse click and drag event.
     */
    public static void move_from_event (
        CanvasItem item,
        double event_x,
        double event_y,
        ref double initial_event_x,
        ref double initial_event_y,
        ref double moved_x,
        ref double moved_y
    ) {
        // Calculate the delta between the initial point and new mouse location.
        moved_x = event_x - initial_event_x;
        moved_y = event_y - initial_event_y;

        // Fetch the current Cairo.Matrix attributes of the item.
        item.get_simple_transform (out old_x, out old_y, out old_scale, out old_rotation);
        // Update the Cairo.Matrix location based on the delta.
        item.set_simple_transform (old_x + moved_x, old_y + moved_y, old_scale, old_rotation);

        // Reset the initial mouse pointer so we can recalculate the delta on next call.
        initial_event_x = event_x;
        initial_event_y = event_y;
    }

    public static void scale_from_event (
        CanvasItem item,
        NobManager.Nob nob,
        double event_x,
        double event_y,
        ref double initial_event_x,
        ref double initial_event_y,
        ref double delta_x_accumulator,
        ref double delta_y_accumulator,
        double initial_width,
        double initial_height,
        ref double moved_x,
        ref double moved_y
    ) {
        double delta_x = fix_size (event_x - initial_event_x);
        double delta_y = fix_size (event_y - initial_event_y);

        var canvas = item.canvas;

        double item_width = item.get_coords ("width");
        double item_height = item.get_coords ("height");
        double item_x = item.bounds_manager.x1;
        double item_y = item.bounds_manager.y1;

        double new_width = 0;
        double new_height = 0;
        double new_x = 0;
        double new_y = 0;

        switch (nob) {
            case NobManager.Nob.TOP_LEFT:
                new_y = delta_y;
                new_x = delta_x;
                new_height = -delta_y;
                new_width = -delta_x;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref new_y,
                    ref new_height
                );

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref new_x,
                    ref new_width
                );

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_width = new_height * item.size_ratio;
                    new_x = -new_width;
                    new_y = -new_height;
                }
                break;

            case NobManager.Nob.TOP_CENTER:
                new_y = delta_y;
                new_height = -delta_y;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref new_y,
                    ref new_height
                );

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_width = new_height * item.size_ratio;
                    new_x = - (new_width / 2);
                }
                break;

            case NobManager.Nob.TOP_RIGHT:
                new_y = delta_y;
                new_height = -delta_y;
                new_width = delta_x;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref new_y,
                    ref new_height
                );

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref new_width);

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_height = new_width / item.size_ratio;
                    new_y = -new_height;
                }
                break;

            case NobManager.Nob.RIGHT_CENTER:
                new_width = delta_x;

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref new_width);

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_height = new_width / item.size_ratio;
                    new_y = - (new_height / 2);
                }
                break;

            case NobManager.Nob.BOTTOM_RIGHT:
                new_width = delta_x;
                new_height = delta_y;

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref new_width);

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref new_height);

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_height = new_width / item.size_ratio;
                    if (item.size_ratio == 1 && item_width != item_height) {
                        new_height = item_width - item_height;
                    }
                }
                break;

            case NobManager.Nob.BOTTOM_CENTER:
                new_height = delta_y;

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref new_height);

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_width = new_height * item.size_ratio;
                    new_x = - (new_width / 2);
                }
                break;

            case NobManager.Nob.BOTTOM_LEFT:
                new_x = delta_x;
                new_width = -delta_x;
                new_height = delta_y;

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref new_x,
                    ref new_width
                );

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref new_height);

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_width = new_height * item.size_ratio;
                    new_x = -new_width;
                }
                break;

            case NobManager.Nob.LEFT_CENTER:
                new_x = delta_x;
                new_width = -delta_x;

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref new_x,
                    ref new_width
                );

                if (canvas.ctrl_is_pressed || item.size_locked) {
                    new_height = new_width * item.size_ratio;
                    new_y = - (new_height / 2);
                }
                break;
        }

        // Update the initial coordiante to keep getting the correct delta.
        initial_event_x = event_x;
        initial_event_y = event_y;

        // Always translate the item by its axis in order to properly resize it
        // even when rotated.
        item.move (new_x, new_y);
        // Update the item size.
        set_size (item, new_width, new_height);

        // Send the coordiantes variations back to the caller method.
        moved_x = new_x;
        moved_y = new_y;
    }

    // Width size constraints.
    private static void fix_width (
        ref double delta_x,
        ref double event_x,
        ref double item_x,
        ref double item_width,
        ref double new_width
    ) {
        if (fix_size (event_x) < item_x && item_width != 1) {
            // If the mouse event goes beyond the available width of the item
            // super quickly, collapse the size to 1 and maintain the position.
            new_width = -item_width + 1;
        } else if (fix_size (event_x) < item_x) {
            // If the user keeps moving the mouse beyond the available width of the item
            // prevent any size changes.
            new_width = 0;
        } else if (item_width == 1 && delta_x <= 0) {
            // Don't update the size or position if the delta keeps increasing,
            // meaning the user is still moving left.
            new_width = 0;
        }
    }

    // Width size constraints and origin point.
    private static void fix_width_origin (
        ref double delta_x,
        ref double event_x,
        ref double item_x,
        ref double item_width,
        ref double new_x,
        ref double new_width
    ) {
        if (fix_size (event_x) > item_x + item_width && item_width != 1) {
            // If the mouse event goes beyond the available width of the item
            // super quickly, collapse the size to 1 and maintain the position.
            new_x = item_width - 1;
            new_width = -item_width + 1;
        } else if (fix_size (event_x) > item_x + item_width) {
            // If the user keeps moving the mouse beyond the available width of the item
            // prevent any size changes.
            new_x = 0;
            new_width = 0;
        } else if (item_width == 1 && delta_x >= 0) {
            // Don't update the size or position if the delta keeps increasing,
            // meaning the user is still moving right.
            new_x = 0;
            new_width = 0;
        }
    }

    // Height size constraints.
    private static void fix_height (
        ref double delta_y,
        ref double event_y,
        ref double item_y,
        ref double item_height,
        ref double new_height
    ) {
        if (fix_size (event_y) < item_y && item_height != 1) {
            // If the mouse event goes beyond the available height of the item
            // super quickly, collapse the size to 1 and maintain the position.
            new_height = -item_height + 1;
        } else if (fix_size (event_y) < item_y) {
            // If the user keeps moving the mouse beyond the available height of the item
            // prevent any size changes.
            new_height = 0;
        } else if (item_height == 1 && delta_y <= 0) {
            // Don't update the size or position if the delta keeps increasing,
            // meaning the user is still moving down.
            new_height = 0;
        }
    }

    // Height size constraints and origin point.
    private static void fix_height_origin (
        ref double delta_y,
        ref double event_y,
        ref double item_y,
        ref double item_height,
        ref double new_y,
        ref double new_height
    ) {
        if (fix_size (event_y) > item_y + item_height && item_height != 1) {
            // If the mouse event goes beyond the available height of the item
            // super quickly, collapse the size to 1 and maintain the position.
            new_y = item_height - 1;
            new_height = -item_height + 1;
        } else if (fix_size (event_y) > item_y + item_height) {
            // If the user keeps moving the mouse beyond the available height of the item
            // prevent any size changes.
            new_y = 0;
            new_height = 0;
        } else if (item_height == 1 && delta_y >= 0) {
            // Don't update the size or position if the delta keeps increasing,
            // meaning the user is still moving down.
            new_y = 0;
            new_height = 0;
        }
    }

    public static void set_size (Goo.CanvasItem item, double x, double y) {
        double width, height;
        item.get ("width", out width, "height", out height);

        // Prevent accidental negative values.
        if (width + x > 0) {
            item.set ("width", fix_size (width + x));
        }

        if (height + y > 0) {
            item.set ("height", fix_size (height + y));
        }

        // Don't update the bounds manager if a native goocanvas_rect was used,
        // meaning no Akira Models was used and we don't need the bounds.
        if (!(item is Goo.CanvasRect)) {
            var model_item = item as CanvasItem;
            model_item.bounds_manager.update ();
        }
    }

    public static void rotate_from_event (
        CanvasItem item,
        double x,
        double y,
        ref double initial_x,
        ref double initial_y,
        ref double moved_x,
        ref double moved_y
    ) {
        var diff_x = 0.0;
        var diff_y = 0.0;
        var canvas = item.canvas as Akira.Lib.Canvas;

        if (item.artboard != null) {
            canvas.convert_to_item_space (item.artboard, ref x, ref y);
            canvas.convert_to_item_space (item.artboard, ref initial_x, ref initial_y);

            diff_x = item.bounds_manager.x1 - item.artboard.bounds.x1;
            diff_y = item.bounds_manager.y1 - item.artboard.bounds.y1
                     - item.artboard.get_label_height ();

            x -= diff_x;
            y -= diff_y;
            initial_x -= diff_x;
            initial_y -= diff_y;
        } else {
            canvas.convert_to_item_space (item, ref x, ref y);
            canvas.convert_to_item_space (item, ref initial_x, ref initial_y);
        }

        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;
        var do_rotation = true;
        double rotation_amount = 0;

        var start_radians = GLib.Math.atan2 (
            initial_x - center_x,
            center_y - initial_y
        );

        var radians = GLib.Math.atan2 (x - center_x, center_y - y);
        var new_radians = radians - start_radians;

        var rotation = new_radians * (180 / Math.PI) + prev_rotation_difference;

        if (canvas.ctrl_is_pressed) {
            do_rotation = false;
        }

        // Revert the coordinates to the canvas and udpate their references.
        if (item.artboard != null) {
            canvas.convert_from_item_space (item.artboard, ref x, ref y);
            x += diff_x;
            y += diff_y;
        } else {
            canvas.convert_from_item_space (item, ref x, ref y);
        }
        initial_x = x;
        initial_y = y;

        if (canvas.ctrl_is_pressed) {
            // Temporarily sum the current rotation delta to determine when the user
            // surpasses the ROTATION_FIXED_STEP threshold.
            temp_rotation += rotation;

            if (temp_rotation.abs () > ROTATION_FIXED_STEP) {
                do_rotation = true;
                // Reset the temp_rotation to restart the sum count.
                temp_rotation = 0;
            }

            // The rotation amount needs to take into consideration
            // the current rotation in order to anchor the item to truly
            // "fixed" rotation step instead of simply adding ROTATION_FIXED_STEP
            // to the current rotation, which might lead to a situation in which you
            // cannot "reset" item rotation to rounded values (0, 90, 180, ...) without
            // manually resetting the rotation input field in the properties panel
            var current_rotation_int = ((int) fix_size (item.rotation));

            rotation_amount = ROTATION_FIXED_STEP;

            // Strange glitch: when item.rotation == 30.0, the fmod
            // function does not work properly.
            // 30.00000 % 15.00000 != 0 => rotation_amount becomes 0.
            // That's why here is used the int representation of item.rotation.
            if (current_rotation_int % ROTATION_FIXED_STEP != 0) {
                rotation_amount -= GLib.Math.fmod (item.rotation, ROTATION_FIXED_STEP);
            }

            var prev_rotation = rotation;
            rotation = rotation > 0 ? rotation_amount : -rotation_amount;
            prev_rotation_difference = prev_rotation - rotation;
        }

        if (do_rotation) {
            // Cap new_rotation to the [0, 360] range.
            var new_rotation = GLib.Math.fmod (item.rotation + rotation, 360);

            // Store the current X & Y coordinates of the item's bounding box.
            var old_x = item.bounds.x1;
            var old_y = item.bounds.y1;

            // Round rotation in order to avoid sub degree issue.
            set_rotation (item, fix_size (new_rotation));

            // Pass the delta of the item's bounding box coordinates after the rotation.
            moved_x = old_x - item.bounds.x1;
            moved_y = old_y - item.bounds.y1;
        }

        // Reset rotation to prevent infinite rotation loops.
        prev_rotation_difference = 0.0;
    }

    public static void set_rotation (CanvasItem item, double rotation) {
        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;
        var actual_rotation = rotation - item.rotation;

        item.rotate (actual_rotation, center_x, center_y);
        item.rotation += actual_rotation;

        if (item.artboard == null) {
            item.get_bounds (out bounds);
            item.bounds_manager.update ();
        }
    }

    public static void flip_item (CanvasItem item, double sx, double sy) {
        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;
        var transform = item.get_real_transform ();
        double radians = deg_to_rad (item.rotation);

        transform.translate (center_x, center_y);
        transform.rotate (-radians);
        transform.scale (sx, sy);
        transform.rotate (radians);
        transform.translate (-center_x, -center_y);

        item.set_transform (transform);

        if (item.artboard == null) {
            item.bounds_manager.update ();
        }
    }

    public static double fix_size (double size) {
        return GLib.Math.round (size);
    }

    public static double deg_to_rad (double deg) {
        return deg * Math.PI / 180.0;
    }
}

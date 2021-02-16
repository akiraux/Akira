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

using Akira.Lib.Items;
using Akira.Lib.Managers;

public class Akira.Utils.AffineTransform : Object {
    private const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const double ROTATION_FIXED_STEP = 15.0;

    private static double temp_rotation = 0.0;
    private static double prev_rotation_difference = 0.0;

    /**
     * Move the item based on the mouse click and drag event.
     */
    public static void move_from_event (
        CanvasItem item,
        double event_x,
        double event_y,
        ref double initial_event_x,
        ref double initial_event_y
    ) {
        // Calculate the delta between the initial point and new mouse location.
        var delta_x = event_x - initial_event_x;
        var delta_y = event_y - initial_event_y;

        item.translate (delta_x, delta_y);

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
        double initial_height
    ) {
        var canvas = (Lib.Canvas) item.canvas;
        // Convert the coordinates from the canvas to the item so we know the real
        // values even if the item is rotated.
        canvas.convert_to_item_space (item, ref event_x, ref event_y);
        canvas.convert_to_item_space (item, ref initial_event_x, ref initial_event_y);

        double delta_x = fix_size (event_x - initial_event_x);
        double delta_y = fix_size (event_y - initial_event_y);

        double item_width = item.size.width;
        double item_height = item.size.height;
        double item_x = item.bounds.x1;
        double item_y = item.bounds.y1;
        canvas.convert_to_item_space (item, ref item_x, ref item_y);

        double inc_width = 0;
        double inc_height = 0;
        double inc_x = 0;
        double inc_y = 0;

        switch (nob) {
            case NobManager.Nob.TOP_LEFT:
                inc_y = delta_y;
                inc_x = delta_x;
                inc_height = -delta_y;
                inc_width = -delta_x;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref inc_y,
                    ref inc_height
                );

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref inc_x,
                    ref inc_width
                );

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_width = inc_height * item.size.ratio;
                    inc_x = -inc_width;
                    inc_y = -inc_height;
                }
                break;

            case NobManager.Nob.TOP_CENTER:
                inc_y = delta_y;
                inc_height = -delta_y;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref inc_y,
                    ref inc_height
                );

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_width = inc_height * item.size.ratio;
                    inc_x = - (inc_width / 2);
                }
                break;

            case NobManager.Nob.TOP_RIGHT:
                inc_y = delta_y;
                inc_height = -delta_y;
                inc_width = delta_x;

                fix_height_origin (
                    ref delta_y,
                    ref event_y,
                    ref item_y,
                    ref item_height,
                    ref inc_y,
                    ref inc_height
                );

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref inc_width);

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_height = inc_width / item.size.ratio;
                    inc_y = -inc_height;
                }
                break;

            case NobManager.Nob.RIGHT_CENTER:
                inc_width = delta_x;

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref inc_width);

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_height = inc_width / item.size.ratio;
                    inc_y = - (inc_height / 2);
                }
                break;

            case NobManager.Nob.BOTTOM_RIGHT:
                inc_width = delta_x;
                inc_height = delta_y;

                fix_width (ref delta_x, ref event_x, ref item_x, ref item_width, ref inc_width);

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref inc_height);

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_height = inc_width / item.size.ratio;
                    if (item.size.ratio == 1 && item_width != item_height) {
                        inc_height = item_width - item_height;
                    }
                }
                break;

            case NobManager.Nob.BOTTOM_CENTER:
                inc_height = delta_y;

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref inc_height);

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_width = inc_height * item.size.ratio;
                    inc_x = - (inc_width / 2);
                }
                break;

            case NobManager.Nob.BOTTOM_LEFT:
                inc_x = delta_x;
                inc_width = -delta_x;
                inc_height = delta_y;

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref inc_x,
                    ref inc_width
                );

                fix_height (ref delta_y, ref event_y, ref item_y, ref item_height, ref inc_height);

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_width = inc_height * item.size.ratio;
                    inc_x = -inc_width;
                }
                break;

            case NobManager.Nob.LEFT_CENTER:
                inc_x = delta_x;
                inc_width = -delta_x;

                fix_width_origin (
                    ref delta_x,
                    ref event_x,
                    ref item_x,
                    ref item_width,
                    ref inc_x,
                    ref inc_width
                );

                if (canvas.ctrl_is_pressed || item.size.locked) {
                    inc_height = inc_width * item.size.ratio;
                    inc_y = - (inc_height / 2);
                }
                break;
        }

        // Update the initial coordinates to keep getting the correct delta.
        canvas.convert_from_item_space (item, ref event_x, ref event_y);
        initial_event_x = event_x;
        initial_event_y = event_y;

        // Always translate the item by its axis in order to properly resize it
        // even when rotated.
        item.translate (inc_x, inc_y);
        // Update the item size.
        set_size (item, inc_width, inc_height);
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

    public static void rotate_from_event (
        CanvasItem item,
        double x,
        double y,
        ref double initial_x,
        ref double initial_y
    ) {
        var diff_x = 0.0;
        var diff_y = 0.0;
        var canvas = item.canvas as Akira.Lib.Canvas;

        if (item.artboard != null) {
            canvas.convert_to_item_space (item.artboard, ref x, ref y);
            canvas.convert_to_item_space (item.artboard, ref initial_x, ref initial_y);

            diff_x = item.bounds.x1 - item.artboard.bounds.x1;
            diff_y = item.bounds.y1 - item.artboard.bounds.y1;

            x -= diff_x;
            y -= diff_y;
            initial_x -= diff_x;
            initial_y -= diff_y;
        } else {
            item.canvas.convert_to_item_space (item, ref x, ref y);
            item.canvas.convert_to_item_space (item, ref initial_x, ref initial_y);
        }

        var center_x = item.size.width / 2;
        var center_y = item.size.height / 2;
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

        // Revert the coordinates to the canvas and update their references.
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
            var current_rotation_int = ((int) fix_size (item.rotation.rotation));

            rotation_amount = ROTATION_FIXED_STEP;

            // Strange glitch: when item.rotation.rotation == 30.0, the fmod
            // function does not work properly.
            // 30.00000 % 15.00000 != 0 => rotation_amount becomes 0.
            // That's why here is used the int representation of item.rotation.rotation.
            if (current_rotation_int % ROTATION_FIXED_STEP != 0) {
                rotation_amount -= GLib.Math.fmod (item.rotation.rotation, ROTATION_FIXED_STEP);
            }

            var prev_rotation = rotation;
            rotation = rotation > 0 ? rotation_amount : -rotation_amount;
            prev_rotation_difference = prev_rotation - rotation;
        }

        if (do_rotation) {
            // Cap new_rotation to the [0, 360] range.
            var new_rotation = GLib.Math.fmod (item.rotation.rotation + rotation, 360);

            // Round rotation in order to avoid sub degree issue.
            // set_rotation (item, fix_size (new_rotation));
            item.rotation.rotation = fix_size (new_rotation);
        }

        // Reset rotation to prevent infinite rotation loops.
        prev_rotation_difference = 0.0;
    }

    public static void set_size (Lib.Items.CanvasItem item, double x, double y) {
        // double width, height;
        // item.get ("width", out width, "height", out height);

        double new_width = fix_size (item.size.width + x);
        double new_height = fix_size (item.size.height + y);

        // Prevent accidental negative values.
        if (new_width > 0) {
            item.size.width = new_width;
        }

        if (new_height > 0) {
            item.size.height = new_height;
        }
    }

    // public static void set_rotation (CanvasItem item, double rotation) {
    //     var center_x = item.size.width / 2;
    //     var center_y = item.size.height / 2;
    //     var actual_rotation = rotation - item.rotation.rotation;

    //     item.rotate (actual_rotation, center_x, center_y);
    //     item.rotation.rotation += actual_rotation;
    // }

    public static void flip_item (CanvasItem item, double sx, double sy) {
        var center_x = item.size.width / 2;
        var center_y = item.size.height / 2;
        Cairo.Matrix transform;
        item.get_transform (out transform);
        double radians = deg_to_rad (item.rotation.rotation);

        transform.translate (center_x, center_y);
        transform.rotate (-radians);
        transform.scale (sx, sy);
        transform.rotate (radians);
        transform.translate (-center_x, -center_y);

        item.set_transform (transform);
    }

    public static double fix_size (double size) {
        return GLib.Math.round (size);
    }

    public static double deg_to_rad (double deg) {
        return deg * Math.PI / 180.0;
    }
}

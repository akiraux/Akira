/**
 * Copyright (c) 2020-2021 Alecaddd (https://alecaddd.com)
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
    private const bool ALLOW_SCALE_OVERFLOW = false;

    private static double temp_rotation = 0.0;
    private static double prev_rotation_difference = 0.0;

    /**
     * Calculate adjustments necessary for a nob resize operation. All inputs
     * should have already been transformed to the correct space.
     */
    public static void calculate_size_adjustments (
        NobManager.Nob nob,
        double item_width,
        double item_height,
        double delta_x,
        double delta_y,
        double size_ratio,
        bool ratio_locked,
        bool symmetric,
        Cairo.Matrix transform,
        ref double inc_x,
        ref double inc_y,
        ref double inc_width,
        ref double inc_height
    ) {
        double local_x_adj = 0.0;
        double local_y_adj = 0.0;
        double perm_x_adj = 0.0;
        double perm_y_adj = 0.0;
        double perm_w_adj = 0;
        double perm_h_adj = 0;

        nob = correct_nob (
            nob,
            item_width,
            item_height,
            symmetric,
            ref delta_x,
            ref delta_y,
            ref perm_x_adj,
            ref perm_y_adj,
            ref perm_w_adj,
            ref perm_h_adj
        );

        double symmetry_offset_x = 0;
        double symmetry_offset_y = 0;

        // Handle vertical adjustment.
        if (NobManager.is_top_nob (nob)) {
            inc_height = fix_size (-delta_y);
            local_y_adj = -inc_height;

            if (symmetric) {
                inc_height *= 2;
            }

        } else if (NobManager.is_bot_nob (nob)) {
            inc_height = fix_size (inc_height + delta_y);
            if (symmetric) {
                symmetry_offset_y = -delta_y;
                local_y_adj = symmetry_offset_y;
                inc_height += delta_y;
            }
        }

        // Handle horizontal adjustment.
        if (NobManager.is_left_nob (nob)) {
            inc_width = fix_size (inc_width - delta_x);
            local_x_adj = -inc_width;

            if (symmetric) {
                inc_width *= 2;
            }
        } else if (NobManager.is_right_nob (nob)) {
            inc_width = fix_size (delta_x);

            if (symmetric) {
                symmetry_offset_x = -delta_x;
                local_x_adj = symmetry_offset_x;
                inc_width += delta_x;
            }
        }

        if (ratio_locked) {
            item_width += perm_w_adj;
            item_height += perm_h_adj;

            bool pure_v = (nob == NobManager.Nob.TOP_CENTER || nob == NobManager.Nob.BOTTOM_CENTER);
            bool pure_h = (nob == NobManager.Nob.RIGHT_CENTER || nob == NobManager.Nob.LEFT_CENTER);

            if (pure_v || (!pure_h && (item_width + inc_width) / (item_height + inc_height) < size_ratio)) {
                inc_width = fix_size ((inc_height + perm_h_adj) * size_ratio - perm_w_adj);
                if (symmetric) {
                    local_x_adj = -fix_size (inc_width / 2.0);
                } else if (nob == NobManager.Nob.TOP_LEFT || nob == NobManager.Nob.BOTTOM_LEFT) {
                    local_x_adj = -inc_width;
                } else if (pure_v) {
                    local_x_adj = - fix_size (inc_width / 2.0);
                }
            } else if (!pure_v) {
                inc_height = fix_size ((inc_width + perm_w_adj) / size_ratio - perm_h_adj);
                if (symmetric) {
                    local_y_adj = -fix_size (inc_height / 2.0);
                } else if (nob == NobManager.Nob.TOP_LEFT || nob == NobManager.Nob.TOP_RIGHT) {
                        local_y_adj = -inc_height;
                } else if (pure_h) {
                        local_y_adj = - fix_size (inc_height / 2.0);
                }
            }
        }

        apply_transform_to_adjustment (
            transform,
            local_x_adj + perm_x_adj,
            local_y_adj - perm_y_adj,
            ref inc_x,
            ref inc_y
        );

        inc_width += perm_w_adj;
        inc_height += perm_h_adj;
    }

    /**
     * Corrects which nob should be used for scaling depending on the delta change of the drag.
     * The nob will be flipped in the vertical and horizontal directions if needed, and
     * the necessary adjustments to delta_x, delta_y and other adjustments will be populated.
     *
     * h_flip will be true if a horizontal flip is required.
     * v_flip will be true if a vertical flip is required.
     * delta_x and delta_y are the delta positions from the start of the drag to the current position.
     * perm_{x,y}_adj are permanent translation adjustments required on the bounding box.
     * perm_{h,w}_adj are permanent scaling adjustments required on the bounding box.
     * both _adj adjustments are in the items' local coordinates.
     */
    private static NobManager.Nob correct_nob (
        NobManager.Nob nob,
        double item_width,
        double item_height,
        bool symmetric,
        ref double delta_x,
        ref double delta_y,
        ref double perm_x_adj,
        ref double perm_y_adj,
        ref double perm_w_adj,
        ref double perm_h_adj
    ) {
        var height_to_check = symmetric ? item_height / 2.0 : item_height;
        var width_to_check = symmetric ? item_width / 2.0 : item_width;

        if (NobManager.is_top_nob (nob)) {
            if (fix_size (height_to_check - delta_y) == 0) {
                delta_y -= 1;
            } else if (height_to_check - delta_y < 0) {
                delta_y -= height_to_check;
                perm_y_adj = -item_height + (item_height - height_to_check);
                perm_h_adj = -item_height;

                if (nob == NobManager.Nob.TOP_LEFT) {
                    nob = NobManager.Nob.BOTTOM_LEFT;
                } else if (nob == NobManager.Nob.TOP_CENTER) {
                    // Nothing more to do.
                    return NobManager.Nob.BOTTOM_CENTER;
                } else if (nob == NobManager.Nob.TOP_RIGHT) {
                    nob = NobManager.Nob.BOTTOM_RIGHT;
                }
            }
        } else if (NobManager.is_bot_nob (nob)) {
            if (fix_size (height_to_check + delta_y) == 0) {
                delta_y += 1;
            }
            else if (height_to_check + delta_y < 0) {
                delta_y += height_to_check;
                perm_y_adj = - (item_height - height_to_check);
                perm_h_adj = -item_height;
                if (nob == NobManager.Nob.BOTTOM_LEFT) {
                    nob = NobManager.Nob.TOP_LEFT;
                } else if (nob == NobManager.Nob.BOTTOM_CENTER) {
                    // Nothing more to do.
                    return NobManager.Nob.TOP_CENTER;
                } else if (nob == NobManager.Nob.BOTTOM_RIGHT) {
                    nob = NobManager.Nob.TOP_RIGHT;
                }
            }
        }

        if (NobManager.is_left_nob (nob)) {
            if (fix_size (width_to_check - delta_x) == 0) {
                delta_x -= 1;
            } else if (width_to_check - delta_x < 0) {
                delta_x -= width_to_check;
                perm_x_adj = item_width - (item_width - width_to_check);
                perm_w_adj = -item_width;

                if (nob == NobManager.Nob.TOP_LEFT) {
                    nob = NobManager.Nob.TOP_RIGHT;
                } else if (nob == NobManager.Nob.LEFT_CENTER) {
                    nob = NobManager.Nob.RIGHT_CENTER;
                } else if (nob == NobManager.Nob.BOTTOM_LEFT) {
                    nob = NobManager.Nob.BOTTOM_RIGHT;
                }
            }
        } else if (NobManager.is_right_nob (nob)) {
            if (fix_size (width_to_check + delta_x) == 0) {
                delta_x += 1;
            }
            else if (width_to_check + delta_x < 0) {
                delta_x += width_to_check;
                perm_x_adj = (item_width - width_to_check);
                perm_w_adj = -item_width;

                if (nob == NobManager.Nob.TOP_RIGHT) {
                    nob = NobManager.Nob.TOP_LEFT;
                } else if (nob == NobManager.Nob.RIGHT_CENTER) {
                    nob = NobManager.Nob.LEFT_CENTER;
                } else if (nob == NobManager.Nob.BOTTOM_RIGHT) {
                    nob = NobManager.Nob.BOTTOM_LEFT;
                }
            }
        }

        return nob;
    }

    /**
     * Apply transform to a translation adjustment, and adjust the increment with it.
     */
    private static void apply_transform_to_adjustment (
        Cairo.Matrix transform,
        double adj_x,
        double adj_y,
        ref double inc_x,
        ref double inc_y
    ) {
        transform.transform_distance (ref adj_x, ref adj_y);
        inc_x += adj_x;
        inc_y += adj_y;
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

            diff_x = item.transform.x1 - item.artboard.transform.x1;
            diff_y = item.transform.y1 - item.artboard.transform.y1;

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

    public static void adjust_size (Lib.Items.CanvasItem item, double adj_x, double adj_y) {
        var new_width = item.size.width + adj_x;
        var new_height = item.size.height + adj_y;

        // Prevent accidental negative values.
        if (new_width > 0) {
            item.size.width = new_width;
        }

        if (new_height > 0) {
            item.size.height = new_height;
        }
    }

    public static double fix_size (double size) {
        return GLib.Math.round (size);
    }

    public static double deg_to_rad (double deg) {
        return deg * Math.PI / 180.0;
    }
}

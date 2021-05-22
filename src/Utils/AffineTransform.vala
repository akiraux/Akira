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

    /**
     * Calculate adjustments necessary for a nob resize operation. All inputs
     * should have already been transformed to the correct space.
     */
    public static void calculate_size_adjustments (
        Utils.Nobs.Nob nob,
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
        if (Utils.Nobs.is_top_nob (nob)) {
            inc_height = fix_size (-delta_y);
            local_y_adj = -inc_height;

            if (symmetric) {
                inc_height *= 2;
            }
        } else if (Utils.Nobs.is_bot_nob (nob)) {
            inc_height = fix_size (inc_height + delta_y);

            if (symmetric) {
                symmetry_offset_y = -delta_y;
                local_y_adj = symmetry_offset_y;
                inc_height += delta_y;
            }
        }

        // Handle horizontal adjustment.
        if (Utils.Nobs.is_left_nob (nob)) {
            inc_width = fix_size (inc_width - delta_x);
            local_x_adj = -inc_width;

            if (symmetric) {
                inc_width *= 2;
            }
        } else if (Utils.Nobs.is_right_nob (nob)) {
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

            bool pure_v = (nob == Utils.Nobs.Nob.TOP_CENTER || nob == Utils.Nobs.Nob.BOTTOM_CENTER);
            bool pure_h = (nob == Utils.Nobs.Nob.RIGHT_CENTER || nob == Utils.Nobs.Nob.LEFT_CENTER);

            if (pure_v || (!pure_h && (item_width + inc_width) / (item_height + inc_height) < size_ratio)) {
                inc_width = fix_size ((inc_height + perm_h_adj) * size_ratio - perm_w_adj);
                if (symmetric) {
                    local_x_adj = -fix_size (inc_width / 2.0);
                } else if (nob == Utils.Nobs.Nob.TOP_LEFT || nob == Utils.Nobs.Nob.BOTTOM_LEFT) {
                    local_x_adj = -inc_width;
                } else if (pure_v) {
                    local_x_adj = - fix_size (inc_width / 2.0);
                }
            } else if (!pure_v) {
                inc_height = fix_size ((inc_width + perm_w_adj) / size_ratio - perm_h_adj);
                if (symmetric) {
                    local_y_adj = -fix_size (inc_height / 2.0);
                } else if (nob == Utils.Nobs.Nob.TOP_LEFT || nob == Utils.Nobs.Nob.TOP_RIGHT) {
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
     * Calculate adjustments necessary for a nob resize operation. All inputs
     * should have already been transformed to the correct space.
     */
    public static void calculate_size_adjustments2 (
        Utils.Nobs.Nob nob,
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
        if (Utils.Nobs.is_top_nob (nob)) {
            inc_height = -delta_y;
            local_y_adj = -inc_height;

            if (symmetric) {
                inc_height *= 2;
            }
        } else if (Utils.Nobs.is_bot_nob (nob)) {
            inc_height = inc_height + delta_y;

            if (symmetric) {
                symmetry_offset_y = -delta_y;
                local_y_adj = symmetry_offset_y;
                inc_height += delta_y;
            }
        }

        // Handle horizontal adjustment.
        if (Utils.Nobs.is_left_nob (nob)) {
            inc_width = inc_width - delta_x;
            local_x_adj = -inc_width;

            if (symmetric) {
                inc_width *= 2;
            }
        } else if (Utils.Nobs.is_right_nob (nob)) {
            inc_width = delta_x;

            if (symmetric) {
                symmetry_offset_x = -delta_x;
                local_x_adj = symmetry_offset_x;
                inc_width += delta_x;
            }
        }

        if (ratio_locked) {
            item_width += perm_w_adj;
            item_height += perm_h_adj;

            bool pure_v = (nob == Utils.Nobs.Nob.TOP_CENTER || nob == Utils.Nobs.Nob.BOTTOM_CENTER);
            bool pure_h = (nob == Utils.Nobs.Nob.RIGHT_CENTER || nob == Utils.Nobs.Nob.LEFT_CENTER);

            if (pure_v || (!pure_h && (item_width + inc_width) / (item_height + inc_height) < size_ratio)) {
                inc_width = (inc_height + perm_h_adj) * size_ratio - perm_w_adj;
                if (symmetric) {
                    local_x_adj = -inc_width / 2.0;
                } else if (nob == Utils.Nobs.Nob.TOP_LEFT || nob == Utils.Nobs.Nob.BOTTOM_LEFT) {
                    local_x_adj = -inc_width;
                } else if (pure_v) {
                    local_x_adj = - inc_width / 2.0;
                }
            } else if (!pure_v) {
                inc_height = (inc_width + perm_w_adj) / size_ratio - perm_h_adj;
                if (symmetric) {
                    local_y_adj = -inc_height / 2.0;
                } else if (nob == Utils.Nobs.Nob.TOP_LEFT || nob == Utils.Nobs.Nob.TOP_RIGHT) {
                    local_y_adj = -inc_height;
                } else if (pure_h) {
                    local_y_adj = - inc_height / 2.0;
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
    private static Utils.Nobs.Nob correct_nob (
        Utils.Nobs.Nob nob,
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

        if (Utils.Nobs.is_top_nob (nob)) {
            if (fix_size (height_to_check - delta_y) == 0) {
                delta_y -= 1;
            } else if (height_to_check - delta_y < 0) {
                delta_y -= height_to_check;
                perm_y_adj = -item_height + (item_height - height_to_check);
                perm_h_adj = -item_height;

                if (nob == Utils.Nobs.Nob.TOP_LEFT) {
                    nob = Utils.Nobs.Nob.BOTTOM_LEFT;
                } else if (nob == Utils.Nobs.Nob.TOP_CENTER) {
                    // Nothing more to do.
                    return Utils.Nobs.Nob.BOTTOM_CENTER;
                } else if (nob == Utils.Nobs.Nob.TOP_RIGHT) {
                    nob = Utils.Nobs.Nob.BOTTOM_RIGHT;
                }
            }
        } else if (Utils.Nobs.is_bot_nob (nob)) {
            if (fix_size (height_to_check + delta_y) == 0) {
                delta_y += 1;
            } else if (height_to_check + delta_y < 0) {
                delta_y += height_to_check;
                perm_y_adj = - (item_height - height_to_check);
                perm_h_adj = -item_height;
                if (nob == Utils.Nobs.Nob.BOTTOM_LEFT) {
                    nob = Utils.Nobs.Nob.TOP_LEFT;
                } else if (nob == Utils.Nobs.Nob.BOTTOM_CENTER) {
                    // Nothing more to do.
                    return Utils.Nobs.Nob.TOP_CENTER;
                } else if (nob == Utils.Nobs.Nob.BOTTOM_RIGHT) {
                    nob = Utils.Nobs.Nob.TOP_RIGHT;
                }
            }
        }

        if (Utils.Nobs.is_left_nob (nob)) {
            if (fix_size (width_to_check - delta_x) == 0) {
                delta_x -= 1;
            } else if (width_to_check - delta_x < 0) {
                delta_x -= width_to_check;
                perm_x_adj = item_width - (item_width - width_to_check);
                perm_w_adj = -item_width;

                if (nob == Utils.Nobs.Nob.TOP_LEFT) {
                    nob = Utils.Nobs.Nob.TOP_RIGHT;
                } else if (nob == Utils.Nobs.Nob.LEFT_CENTER) {
                    nob = Utils.Nobs.Nob.RIGHT_CENTER;
                } else if (nob == Utils.Nobs.Nob.BOTTOM_LEFT) {
                    nob = Utils.Nobs.Nob.BOTTOM_RIGHT;
                }
            }
        } else if (Utils.Nobs.is_right_nob (nob)) {
            if (fix_size (width_to_check + delta_x) == 0) {
                delta_x += 1;
            } else if (width_to_check + delta_x < 0) {
                delta_x += width_to_check;
                perm_x_adj = (item_width - width_to_check);
                perm_w_adj = -item_width;

                if (nob == Utils.Nobs.Nob.TOP_RIGHT) {
                    nob = Utils.Nobs.Nob.TOP_LEFT;
                } else if (nob == Utils.Nobs.Nob.RIGHT_CENTER) {
                    nob = Utils.Nobs.Nob.LEFT_CENTER;
                } else if (nob == Utils.Nobs.Nob.BOTTOM_RIGHT) {
                    nob = Utils.Nobs.Nob.BOTTOM_LEFT;
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

    /*
     * Rectifies and positions a center and size based on the top-left corner and a starting size.
     */
    public static void geometry_from_top_left (
        double left,
        double top,
        ref double center_x,
        ref double center_y,
        ref double width,
        ref double height
    ) {
        width = fix_size (width);
        height = fix_size (height);

        center_x = fix_size (left) + width / 2.0;
        center_y = fix_size (top) + height / 2.0;
    }

    public static void add_grid_snap_delta (
        double x,
        double y,
        ref double delta_x,
        ref double delta_y
    ) {
        var combined_x = x + delta_x;
        var combined_y = y + delta_y;
        delta_x += fix_size (combined_x) - combined_x;
        delta_y += fix_size (combined_y) - combined_y;
    }
}

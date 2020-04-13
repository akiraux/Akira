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

    public static HashTable<string, double?> get_position (CanvasItem item) {
        HashTable<string, double?> array = new HashTable<string, double?> (str_hash, str_equal);
        double item_x = item.get_coords ("x");
        double item_y = item.get_coords ("y");

        // debug (@"item x: $(item_x) y: $(item_y)");
        // debug (@"Item has artboard: $(item.artboard != null)");

        item.canvas.convert_from_item_space (item, ref item_x, ref item_y);

        if (item.artboard != null) {
          item_x = item.relative_x;
          item_y = item.relative_y;
        }

        array.insert ("x", item_x);
        array.insert ("y", item_y);

        return array;
    }

    public static void set_position (CanvasItem item, double? x = null, double? y = null) {
        if (item.artboard != null) {
          /*
          var artboard_origin_x = 0.0;
          var artboard_origin_y = 0.0;

          item.canvas.convert_from_item_space (item.artboard, ref artboard_origin_x, ref artboard_origin_y);

          // x and y are relative to the artboard containing
          // the items, so we need to take into account the
          // position of the artboard to compute the actual
          // (canvas wise) position of the item
          new_x += x != null ? artboard_origin_x : 0;
          new_y += y != null ? artboard_origin_y : 0;
          */

          var delta_x = x != null ? x - item.relative_x : 0.0;
          var delta_y = y != null ? y - item.relative_y : 0.0;

          item.relative_x = x != null ? x : item.relative_x;
          item.relative_y = y != null ? y : item.relative_y;

          item.translate (delta_x, delta_y);

          return;
        }

        Cairo.Matrix matrix;
        item.get_transform (out matrix);

        double new_x = (x != null) ? x : matrix.x0;
        double new_y = (y != null) ? y : matrix.y0;

        var new_matrix = Cairo.Matrix (matrix.xx, matrix.yx, matrix.xy, matrix.yy, new_x, new_y);
        item.set_transform (new_matrix);
    }

    public static void move_from_event (
        double x,
        double y,
        ref double initial_x,
        ref double initial_y,
        ref double delta_x_accumulator,
        ref double delta_y_accumulator,
        CanvasItem selected_item
    ) {
        double delta_x = GLib.Math.round (x - initial_x);
        double delta_y = GLib.Math.round (y - initial_y);

        delta_x_accumulator += delta_x;
        delta_y_accumulator += delta_y;

        selected_item.move (
            delta_x, delta_y,
            delta_x_accumulator, delta_y_accumulator
        );

        initial_x = x;
        initial_y = y;
    }

    public static void scale_from_event (
        double x,
        double y,
        ref double initial_x,
        ref double initial_y,
        ref double delta_x_accumulator,
        ref double delta_y_accumulator,
        double initial_width,
        double initial_height,
        NobManager.Nob selected_nob,
        CanvasItem selected_item
    ) {
        double delta_x = Math.round (x - initial_x);
        double delta_y = Math.round (y - initial_y);

        var canvas = selected_item.canvas;

        double origin_move_delta_x = 0;
        double origin_move_delta_y = 0;

        double item_width = selected_item.get_coords ("width");
        double item_height = selected_item.get_coords ("height");

        double new_width = -1;
        double new_height = -1;

        switch (selected_nob) {
            case NobManager.Nob.TOP_LEFT:
                new_height = initial_height - delta_y;
                new_width = initial_width - delta_x;
                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.TOP_CENTER:
                new_height = initial_height - delta_y;
                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case NobManager.Nob.TOP_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height - delta_y;
                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case NobManager.Nob.RIGHT_CENTER:
                new_width = initial_width + delta_x;

                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_width > MIN_SIZE) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height + delta_y;

                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_CENTER:
                new_height = initial_height + delta_y;

                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }
                break;

            case NobManager.Nob.BOTTOM_LEFT:
                new_height = initial_height + delta_y;
                new_width = initial_width - delta_x;
                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_height > MIN_SIZE) {
                    new_width = GLib.Math.round (new_height * selected_item.size_ratio);
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.LEFT_CENTER:
                new_width = initial_width - delta_x;
                if ((canvas.ctrl_is_pressed || selected_item.size_locked) && new_width > MIN_SIZE) {
                    new_height = GLib.Math.round (new_width / selected_item.size_ratio);
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;
        }

        origin_move_delta_x = fix_size (origin_move_delta_x);
        origin_move_delta_y = fix_size (origin_move_delta_y);

        new_width = fix_size (new_width);
        new_height = fix_size (new_height);


        if (new_width == MIN_SIZE) {
            origin_move_delta_x = 0.0;
        }

        if (new_height == MIN_SIZE) {
            origin_move_delta_y = 0.0;
        }

        delta_x_accumulator += origin_move_delta_x;
        delta_y_accumulator += origin_move_delta_y;

        selected_item.move (
            origin_move_delta_x,
            origin_move_delta_y,
            delta_x_accumulator,
            delta_y_accumulator
        );

        set_size (new_width, new_height, selected_item);
        /*
           if (new_width < MIN_SIZE) {
           canvas.window.event_bus.flip_item (false);
           return;
           }

           if (new_height < MIN_SIZE) {
           canvas.window.event_bus.flip_item (false, true);
           return;
           }

        // Before translating, recover the original "canvas" position of
        // initial_event, in order to convert it to the "new" translated
        // item space after the transformation has been applied.
        //canvas.convert_from_item_space (selected_item, ref initial_x, ref initial_y);

        // The CanvasItem.move function expects delta to be the difference
        // between current position and the initial movement one,
        // which is not the case for scaling, since the delta
        // is calculated again at each iteration, so the we should
        // update the initial_relative coordinate each time we call
        // move from here
        //selected_item.store_relative_position ();

        //canvas.convert_to_item_space (selected_item, ref initial_x, ref initial_y);
         */
    }

    public static void rotate_from_event (
        double x,
        double y,
        double initial_x,
        double initial_y,
        int initial_rotation,
        CanvasItem selected_item
    ) {
        var canvas = selected_item.canvas as Akira.Lib.Canvas;

        var initial_x_relative = initial_x;
        var initial_y_relative = initial_y;
        var x_relative = x;
        var y_relative = y;

        var initial_width = selected_item.get_coords ("width");
        var initial_height = selected_item.get_coords ("height");

        var center_x = initial_width / 2;
        var center_y = initial_height / 2;
        var do_rotation = true;

        if (selected_item.artboard != null) {
            canvas.convert_to_item_space (selected_item.artboard, ref initial_x_relative, ref initial_y_relative);
            canvas.convert_to_item_space (selected_item.artboard, ref x_relative, ref y_relative);

            center_x += selected_item.relative_x;
            center_y += selected_item.relative_y;
        } else {
            canvas.convert_to_item_space (selected_item, ref initial_x_relative, ref initial_y_relative);
            canvas.convert_to_item_space (selected_item, ref x_relative, ref y_relative);
        }

        var start_radians = GLib.Math.atan2 (
            center_y - initial_y_relative,
            initial_x_relative - center_x
        );

        var radians = GLib.Math.atan2 (center_y - y_relative, x_relative - center_x);
        radians = start_radians - radians;
        var rotation = radians * (180 / Math.PI);

        if (canvas.ctrl_is_pressed) {
            do_rotation = false;
        }

        if (canvas.ctrl_is_pressed) {
            do_rotation = (int) rotation % ROTATION_FIXED_STEP == 0;
        }


        if (do_rotation) {
            // Cap new_rotation to the [0, 360] range
            var new_rotation = (((int) rotation) + initial_rotation + 360) % 360;
            set_rotation (new_rotation, selected_item);
        }
    }

    public static void set_size (double width, double height, Goo.CanvasItem item) {
        if (width != -1) {
            item.set ("width", width);
        }

        if (height != -1) {
            item.set ("height", height);
        }
    }

    public static void set_rotation (double rotation, CanvasItem item) {
        if (item.artboard != null) {
            // Just update item's rotation, the CanvasArtboard paint
            // method is in charge of doing all the necessary transformations
            item.rotation = rotation;
            return;
        }

        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;

        var actual_rotation = rotation - item.rotation;

        item.rotate (actual_rotation, center_x, center_y);

        item.rotation = rotation;
    }

    public static void flip_item (bool clicked, CanvasItem item, double sx, double sy) {
        if (clicked) {
            double x, y, width, height;
            item.get ("x", out x, "y", out y, "width", out width, "height", out height);
            var center_x = x + width / 2;
            var center_y = y + height / 2;

            var transform = Cairo.Matrix.identity ();
            item.get_transform (out transform);
            double radians = item.rotation * (Math.PI / 180);
            transform.translate (center_x, center_y);
            transform.rotate (-radians);
            transform.scale (sx, sy);
            transform.rotate (radians);
            transform.translate (-center_x, -center_y);
            item.set_transform (transform);
            return;
        }

        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);
        transform.scale (sx, sy);
        item.set_transform (transform);
    }

    public static double fix_size (double size) {
        return GLib.Math.round (size);
    }

    public static double deg_to_rad (double deg) {
        return deg * Math.PI / 180.0;
    }

    public static double rad_to_deg (double rad) {
        return rad / Math.PI * 180.0;
    }
}

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

public class Akira.Utils.Nobs : Object {
    public const double ROTATION_LINE_HEIGHT = 40.0;

    /*
    Grabber Pos:
      8
      |
    0 1 2
    7   3
    6 5 4

    // -1 if no nob is grabbed.
    */
    public enum Nob {
        NONE=-1,
        TOP_LEFT,
        TOP_CENTER,
        TOP_RIGHT,
        RIGHT_CENTER,
        BOTTOM_RIGHT,
        BOTTOM_CENTER,
        BOTTOM_LEFT,
        LEFT_CENTER,
        ROTATE,
        ALL
    }

    public class NobData {
        public const double NOB_SIZE = 10;
        public const double LINE_WIDTH = 1;

        public Nob handle_id;
        public double center_x;
        public double center_y;
        public bool active;

        public NobData (Nob id, double center_x, double center_y, bool active) {
            this.handle_id = id;
            this.center_x = center_x;
            this.center_y = center_y;
            this.active = active;
        }

        public NobData copy () {
            return new NobData (handle_id, center_x, center_y, active);
        }
    }

    public class NobSet {
        public NobData[] data;

        public NobSet () {
            data = new NobData[9];
            for (var i = 0; i < 9; i++) {
                data[i] = new NobData ((Nob)i, 0, 0, false);
            }
        }

        public NobSet.clone (NobSet other) {
            data = new NobData[9];
            for (var i = 0; i < 9; i++) {
                data[i] = other.data[i].copy ();
            }
        }

        public bool any_active () {
            foreach (unowned var nob in data) {
                if (nob.active) {
                    return true;
                }
            }

            return false;
        }

        public Nob hit_test (double x, double y, double scale) {
            foreach (unowned var nob in data) {
                if (!nob.active) {
                    continue;
                }

                double xd = nob.center_x - x;
                double yd = nob.center_y - y;
                double dist = GLib.Math.sqrt (xd * xd + yd * yd);
                if (dist <= NobData.NOB_SIZE / scale) {
                    return nob.handle_id;
                }
            }

            return Nob.NONE;
        }

        public Geometry.Rectangle? extents (double scale, bool all) {
            double left = double.MAX;
            double right = double.MIN;
            double top = double.MAX;
            double bottom = double.MIN;

            foreach (unowned var nob in data) {
                if (all || nob.active) {
                    left = double.min (left, nob.center_x);
                    right = double.max (right, nob.center_x);
                    top = double.min (top, nob.center_y);
                    bottom = double.max (bottom, nob.center_y);
                }
            }

            if (left == double.MAX || top == double.MAX) {
                return null;
            }

            double off = NobData.NOB_SIZE / scale;
            return Geometry.Rectangle.with_coordinates (left - off, top - off, right + off, bottom + off);
        }

        public void set_active (bool active) {
            foreach (unowned var nob in data) {
                nob.active = active;
            }
        }
    }

    public static bool is_top_nob (Nob nob) {
        return nob == Nob.TOP_LEFT || nob == Nob.TOP_CENTER || nob == Nob.TOP_RIGHT;
    }

    public static bool is_bot_nob (Nob nob) {
        return nob == Nob.BOTTOM_LEFT || nob == Nob.BOTTOM_CENTER || nob == Nob.BOTTOM_RIGHT;
    }

    public static bool is_left_nob (Nob nob) {
        return nob == Nob.TOP_LEFT || nob == Nob.LEFT_CENTER || nob == Nob.BOTTOM_LEFT;
    }

    public static bool is_right_nob (Nob nob) {
        return nob == Nob.TOP_RIGHT || nob == Nob.RIGHT_CENTER || nob == Nob.BOTTOM_RIGHT;
    }

    public static bool is_corner_nob (Nob nob) {
        return nob == Nob.TOP_RIGHT || nob == Nob.TOP_LEFT || nob == Nob.BOTTOM_RIGHT || nob == Nob.BOTTOM_LEFT;
    }

    public static bool is_horizontal_center (Nob nob) {
        return (nob == Utils.Nobs.Nob.RIGHT_CENTER || nob == Utils.Nobs.Nob.LEFT_CENTER);
    }

    public static bool is_vertical_center (Nob nob) {
        return (nob == Utils.Nobs.Nob.TOP_CENTER || nob == Utils.Nobs.Nob.BOTTOM_CENTER);
    }

    /*
     * Return a cursor type based of the type of nob.
     */
    public static Gdk.CursorType? cursor_from_nob (Nob nob_id) {
        Gdk.CursorType? result = null;
        switch (nob_id) {
            case Nob.NONE:
                result = null;
                break;
            case Nob.TOP_LEFT:
                result = Gdk.CursorType.TOP_LEFT_CORNER;
                break;
            case Nob.TOP_CENTER:
                result = Gdk.CursorType.TOP_SIDE;
                break;
            case Nob.TOP_RIGHT:
                result = Gdk.CursorType.TOP_RIGHT_CORNER;
                break;
            case Nob.RIGHT_CENTER:
                result = Gdk.CursorType.RIGHT_SIDE;
                break;
            case Nob.BOTTOM_RIGHT:
                result = Gdk.CursorType.BOTTOM_RIGHT_CORNER;
                break;
            case Nob.BOTTOM_CENTER:
                result = Gdk.CursorType.BOTTOM_SIDE;
                break;
            case Nob.BOTTOM_LEFT:
                result = Gdk.CursorType.BOTTOM_LEFT_CORNER;
                break;
            case Nob.LEFT_CENTER:
                result = Gdk.CursorType.LEFT_SIDE;
                break;
            case Nob.ROTATE:
                result = Gdk.CursorType.EXCHANGE;
                break;
            default:
                break;
        }

        return result;
    }

    public static Nob opposite_nob (Nob nob_id) {
        switch (nob_id) {
            case Nob.TOP_LEFT:
                return Nob.BOTTOM_RIGHT;
            case Nob.TOP_CENTER:
                return Nob.BOTTOM_CENTER;
            case Nob.TOP_RIGHT:
                return Nob.BOTTOM_LEFT;
            case Nob.RIGHT_CENTER:
                return Nob.LEFT_CENTER;
            case Nob.BOTTOM_RIGHT:
                return Nob.TOP_LEFT;
            case Nob.BOTTOM_CENTER:
                return Nob.TOP_CENTER;
            case Nob.BOTTOM_LEFT:
                return Nob.TOP_RIGHT;
            case Nob.LEFT_CENTER:
                return Nob.RIGHT_CENTER;
            default:
                break;
        }

        return Nob.NONE;
    }

    /*
     *
     */
    public static void rectify_nob (
        double top,
        double left,
        double bottom,
        double right,
        double ev_x,
        double ev_y,
        ref Nob nob
    ) {
        switch (nob) {
            case Nob.TOP_LEFT:
                rectify_top_nob (bottom, ev_y, ref nob);
                rectify_left_nob (right, ev_x, ref nob);
                return;
            case Nob.TOP_CENTER:
                rectify_top_nob (bottom, ev_y, ref nob);
                return;
            case Nob.TOP_RIGHT:
                rectify_top_nob (bottom, ev_y, ref nob);
                rectify_right_nob (left, ev_x, ref nob);
                return;
            case Nob.RIGHT_CENTER:
                rectify_right_nob (left, ev_x, ref nob);
                return;
            case Nob.BOTTOM_RIGHT:
                rectify_bottom_nob (top, ev_y, ref nob);
                rectify_right_nob (left, ev_x, ref nob);
                return;
            case Nob.BOTTOM_CENTER:
                rectify_bottom_nob (top, ev_y, ref nob);
                return;
            case Nob.BOTTOM_LEFT:
                rectify_bottom_nob (top, ev_y, ref nob);
                rectify_left_nob (right, ev_x, ref nob);
                return;
            case Nob.LEFT_CENTER:
                rectify_left_nob (right, ev_x, ref nob);
                return;
            default:
                break;
        }
    }
    public static void rectify_left_nob (double right, double ev_x, ref Nob nob) {
        if (ev_x <= right) {
            return;
        }

        if (nob == Nob.LEFT_CENTER) {
            nob = Nob.RIGHT_CENTER;
        }
        else if (nob == Nob.TOP_LEFT) {
            nob = Nob.TOP_RIGHT;
        }
        else if (nob == Nob.BOTTOM_LEFT) {
            nob = Nob.BOTTOM_RIGHT;
        }
    }

    public static void rectify_right_nob (double left, double ev_x, ref Nob nob) {
        if (ev_x >= left) {
            return;
        }

        if (nob == Nob.RIGHT_CENTER) {
            nob = Nob.LEFT_CENTER;
        }
        else if (nob == Nob.TOP_RIGHT) {
            nob = Nob.TOP_LEFT;
        }
        else if (nob == Nob.BOTTOM_RIGHT) {
            nob = Nob.BOTTOM_LEFT;
        }
    }

    public static void rectify_top_nob (double bottom, double ev_y, ref Nob nob) {
        if (ev_y <= bottom) {
            return;
        }

        if (nob == Nob.TOP_CENTER) {
            nob = Nob.BOTTOM_CENTER;
        }
        else if (nob == Nob.TOP_RIGHT) {
            nob = Nob.BOTTOM_RIGHT;
        }
        else if (nob == Nob.TOP_LEFT) {
            nob = Nob.BOTTOM_LEFT;
        }
    }

    public static void rectify_bottom_nob (double top, double ev_y, ref Nob nob) {
        if (ev_y >= top) {
            return;
        }

        if (nob == Nob.BOTTOM_CENTER) {
            nob = Nob.TOP_CENTER;
        }
        else if (nob == Nob.BOTTOM_RIGHT) {
            nob = Nob.TOP_RIGHT;
        }
        else if (nob == Nob.BOTTOM_LEFT) {
            nob = Nob.TOP_LEFT;
        }
    }

    public static void nob_xy_from_coordinates (
        Utils.Nobs.Nob nob,
        Geometry.Quad rect,
        double scale,
        ref double x,
        ref double y
    ) {

        x = 0.0;
        y = 0.0;

        switch (nob) {
            case Utils.Nobs.Nob.TOP_LEFT:
                x = rect.tl_x;
                y = rect.tl_y;
                break;
            case Utils.Nobs.Nob.TOP_CENTER:
                x = (rect.tl_x + rect.tr_x) / 2.0;
                y = (rect.tl_y + rect.tr_y) / 2.0;
                break;
            case Utils.Nobs.Nob.TOP_RIGHT:
                x = rect.tr_x;
                y = rect.tr_y;
                break;
            case Utils.Nobs.Nob.RIGHT_CENTER:
                x = (rect.tr_x + rect.br_x) / 2.0;
                y = (rect.tr_y + rect.br_y) / 2.0;
                break;
            case Utils.Nobs.Nob.BOTTOM_RIGHT:
                x = rect.br_x;
                y = rect.br_y;
                break;
            case Utils.Nobs.Nob.BOTTOM_CENTER:
                x = (rect.br_x + rect.bl_x) / 2.0;
                y = (rect.br_y + rect.bl_y) / 2.0;
                break;
            case Utils.Nobs.Nob.BOTTOM_LEFT:
                x = rect.bl_x;
                y = rect.bl_y;
                break;
            case Utils.Nobs.Nob.LEFT_CENTER:
                x = (rect.tl_x + rect.bl_x) / 2.0;
                y = (rect.tl_y + rect.bl_y) / 2.0;
                break;
            case Utils.Nobs.Nob.ROTATE:
                var dx = rect.tl_x - rect.bl_x;
                var dy = rect.tl_y - rect.bl_y;
                Utils.GeometryMath.normalize (ref dx, ref dy);


                x = (rect.tl_x + rect.tr_x) / 2.0 + dx * ROTATION_LINE_HEIGHT / scale;
                y = (rect.tl_y + rect.tr_y) / 2.0 + dy * ROTATION_LINE_HEIGHT / scale;
                break;
            default:
                break;
        }
    }

    /*
     * Turns x or y values to zero if they are not affected by the nob.
     * Assumes local x y coordinates.
     */
    public static void rectify_nob_xy (Nob nob, ref double x, ref double y) {
        if (is_horizontal_center (nob)) {
            y = 0.0;
            return;
        }

        if (is_vertical_center (nob)) {
            x = 0.0;
            return;
        }
    }
}

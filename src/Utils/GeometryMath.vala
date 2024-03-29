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

public class Akira.Utils.GeometryMath : Object {

    public static double clamp (double value, double min, double max) {
        return double.min (double.max (value, min), max);
    }

    public static void min_max (ref double x0, ref double x1) {
        if (x1 < x0) {
            double t = x0;
            x0 = x1;
            x1 = t;
        }
    }

    public static void min_max_coords (double x0, double x1, double x2, double x3, ref double min, ref double max) {
        min_max (ref x0, ref x1);
        min_max (ref x2, ref x3);

        min = x0 < x2 ? x0 : x2;
        max = x1 > x3 ? x1 : x3;
    }

    public static double distance (double x0, double y0, double x1, double y1) {
        var xx = (x1 - x0) * (x1 - x0);
        var yy = (y1 - y0) * (y1 - y0);

        return GLib.Math.sqrt (xx + yy);
    }

    public static void normalize (ref double dx, ref double dy) {
        var dm = GLib.Math.sqrt (dx * dx + dy * dy);
        dx = dm > 0 ? (dx / dm) : 0;
        dy = dm > 0 ? (dy / dm) : 0;
    }

    public static void to_local (
        double rotation_rad,
        double rot_center_x,
        double rot_center_y,
        ref double x,
        ref double y
    ) {
        var tr = Cairo.Matrix.identity ();
        tr.rotate (rotation_rad);
        to_local_from_matrix (tr, rot_center_x, rot_center_y, ref x, ref y);
    }

    public static void to_local_from_matrix (
        Cairo.Matrix tr,
        double rot_center_x,
        double rot_center_y,
        ref double x,
        ref double y
    ) {
        double dx = x - rot_center_x;
        double dy = y - rot_center_y;

        tr.transform_distance (ref dx, ref dy);

        x = rot_center_x + dx;
        y = rot_center_y + dy;
    }

    public static bool points_on_same_side_of_line (
        double l1_x,
        double l1_y,
        double l2_x,
        double l2_y,
        double p1_x,
        double p1_y,
        double p2_x,
        double p2_y
    ) {
        double delta_x = l2_x - l1_x;
        double delta_y = l2_y - l1_y;

        double one = delta_x * (p1_y - l1_y) - delta_y * (p1_x - l1_x);
        double two = delta_x * (p2_y - l2_y) - delta_y * (p2_x - l2_x);

        return (one >= 0 && two >= 0) || (one <= 0 && two <= 0);
    }

    public static bool is_normal_rotation (double rot_in_degrees) {
         return GLib.Math.fmod (rot_in_degrees, 90) == 0;
    }

    public static double vector2_dot_product (double x0, double y0, double x1, double y1) {
        return x0 * x1 + y0 * y1;
    }

    public static double vector2_cross_product (double x0, double y0, double x1, double y1) {
        return x0 * y1 - y0 * x1;
    }


    public static double angle_between_vectors (double x0, double y0, double x1, double y1) {
        return GLib.Math.atan2 (
            vector2_cross_product (x0, y0, x1, y1),
            vector2_dot_product (x0, y0, x1, y1)
        );
    }

    public static void matrix_skew_x (ref Cairo.Matrix mat, double factor) {
        var skew_mat = Cairo.Matrix (1.0, 0.0, factor, 1.0, 0, 0);
        mat = multiply_matrices (mat, skew_mat);
    }

    public static void matrix_skew_y (ref Cairo.Matrix mat, double factor) {
        var skew_mat = Cairo.Matrix (1.0, factor, 0.0, 1.0, 0, 0);
        mat = multiply_matrices (mat, skew_mat);
    }

    public static void matrix_rotate (ref Cairo.Matrix mat, double angle) {
        var rot_mat = Cairo.Matrix.identity ();
        rot_mat.rotate (angle);
        mat = multiply_matrices (mat, rot_mat);
    }

    public static Cairo.Matrix multiply_matrices (Cairo.Matrix a, Cairo.Matrix b) {
        return Cairo.Matrix (
            a.xx * b.xx + a.yx * b.xy,
            a.xx * b.yx + a.yx * b.yy,
            a.xy * b.xx + a.yy * b.xy,
            a.xy * b.yx + a.yy * b.yy,
            a.x0 * b.xx + a.y0 * b.xy + b.x0,
            a.x0 * b.yx + a.y0 * b.yy + b.y0);
    }

    /*
     * Returns the rotation component of a matrix.
     */
    public static double matrix_rotation_component (Cairo.Matrix mat) {
        return GLib.Math.atan2 (mat.yx, mat.xx);
    }

    /*
     * Decomposes a matrix to three operations (scale, shear and rotation)
     *
     * To recompose run two multiplications:
     * var new_matrix = multiply_matrices (scale_matrix, shear_matrix);
     * new_matrix = multiply_matrices (new_matrix, rotation_matrix);
     */
    public static bool decompose_matrix (
        Cairo.Matrix mat,
        ref double scale_x,
        ref double scale_y,
        ref double shear_x,
        ref double angle
    ) {
        // https://math.stackexchange.com/questions/612006/decomposing-an-affine-transformation
        var xx = mat.xx;
        var xy = mat.xy;
        var yx = mat.yx;
        var yy = mat.yy;

        double det = xx * yy - xy * yx;
        if (det.abs () < 0.000001) {
            return false;
        }

        scale_x = GLib.Math.sqrt (xx * xx + yx * yx);

        angle = GLib.Math.atan2 (yx, xx);

        var sin_th = GLib.Math.sin (angle);
        var cos_th = GLib.Math.cos (angle);

        var msy = xy * cos_th + yy * sin_th;

        if (sin_th != 0) {
            scale_y = (msy * cos_th - xy) / sin_th;
        } else {
            scale_y = (yy - sin_th * msy) / cos_th;
        }

        // Not sure about this
        //if (det < 0) {
        //    if (xx < yy) {
        //        scale_x = -scale_x;
        //    } else {
        //        scale_y = -scale_y;
        //    }
        //}

        shear_x = msy / scale_y;

        return true;
    }

    public static void recompose_matrix (
        out Cairo.Matrix mat,
        double scale_x,
        double scale_y,
        double shear_x,
        double angle
    ) {
        mat = Cairo.Matrix (scale_x, 0.0, 0.0, scale_y, 0.0, 0.0);
        matrix_skew_x (ref mat, shear_x);
        var rot = Cairo.Matrix.identity ();
        rot.rotate (angle);
        mat = multiply_matrices (mat, rot);
    }

    public static void transform_quad (
        Cairo.Matrix transform,
        ref Geometry.Quad area
    ) {
        var center_x = area.center_x;
        var center_y = area.center_y;
        area.translate (-center_x, -center_y);
        area.transformation = multiply_matrices (area.transformation, transform);

        transform.transform_distance (ref area.tr_x, ref area.tr_y);
        transform.transform_distance (ref area.tl_x, ref area.tl_y);
        transform.transform_distance (ref area.br_x, ref area.br_y);
        transform.transform_distance (ref area.bl_x, ref area.bl_y);
        area.translate (center_x, center_y);
    }

    public static Geometry.Quad apply_stretch (
        Cairo.Matrix stretch_mat,
        Geometry.Quad area,
        double offset_x,
        double offset_y,
        double center_offset_x,
        double center_offset_y,
        ref double width,
        ref double height,
        ref double rotation,
        ref double xx,
        ref double yy,
        ref double xy,
        ref double yx
    ) {
        stretch_mat.transform_distance (ref center_offset_x, ref center_offset_y);

        var dx = area.center_x;
        var dy = area.center_y;
        area.translate (-dx, -dy);

        stretch_mat.transform_distance (ref area.tl_x, ref area.tl_y);
        stretch_mat.transform_distance (ref area.tr_x, ref area.tr_y);
        stretch_mat.transform_distance (ref area.bl_x, ref area.bl_y);
        stretch_mat.transform_distance (ref area.br_x, ref area.br_y);

        width = distance (area.tl_x, area.tl_y, area.tr_x, area.tr_y).abs ();
        height = distance (area.tl_x, area.tl_y, area.bl_x, area.bl_y).abs ();

        var ltor_x = area.tr_x - area.tl_x;
        var ltor_y = area.tr_y - area.tl_y;

        rotation = angle_between_vectors (1, 0, ltor_x, ltor_y);

        var extra_rot_mat = Cairo.Matrix.identity ();
        extra_rot_mat.rotate (-rotation);

        extra_rot_mat.transform_distance (ref area.tl_x, ref area.tl_y);
        extra_rot_mat.transform_distance (ref area.tr_x, ref area.tr_y);
        extra_rot_mat.transform_distance (ref area.bl_x, ref area.bl_y);
        extra_rot_mat.transform_distance (ref area.br_x, ref area.br_y);

        yy = (area.br_y - area.tr_y).abs () / height;
        xy = (area.br_x - area.tr_x) / (area.br_y - area.tr_y) * yy;

        area.translate (dx + offset_x + center_offset_x, dy + offset_y + center_offset_y);

        return area;
    }

    public static Geometry.Point rotate_point (Geometry.Point point, double rotation, Geometry.Point origin) {
        double cos_theta = Math.cos (rotation);
        double sin_theta = Math.sin (rotation);

        double rot_x = cos_theta * (point.x - origin.x) - sin_theta * (point.y - origin.y) + origin.x;
        double rot_y = sin_theta * (point.x - origin.x) + cos_theta * (point.y - origin.y) + origin.y;

        return Geometry.Point (rot_x, rot_y);
    }

    public static bool compare_points (Geometry.Point a, Geometry.Point b, double thresh) {
        if (Utils.GeometryMath.distance (a.x, a.y, b.x, b.y) < thresh) {
            return true;
        }

        return false;
    }

    public static Geometry.Rectangle bounds_from_points (Geometry.PathSegment[] points) {
        Geometry.Rectangle bounds = Geometry.Rectangle ();
        bounds.left = double.MAX;
        bounds.top = double.MAX;
        bounds.right = double.MIN;
        bounds.bottom = double.MIN;

        foreach (var pt in points) {
            // Create a list of all points we need to calculate bounds for.
            Geometry.Point[] pts_in_segment = new Geometry.Point[0];

            if (pt.type == Lib.Modes.PathEditMode.Type.LINE) {
                pts_in_segment = new Geometry.Point[1];
                pts_in_segment[0] = pt.line_end;
            } else if (pt.type == Lib.Modes.PathEditMode.Type.QUADRATIC_LEFT) {
                pts_in_segment = new Geometry.Point[2];
                pts_in_segment[0] = pt.curve_begin;
                pts_in_segment[1] = pt.tangent_1;
            } else if (pt.type == Lib.Modes.PathEditMode.Type.QUADRATIC_RIGHT) {
                pts_in_segment = new Geometry.Point[2];
                pts_in_segment[0] = pt.curve_end;
                pts_in_segment[1] = pt.tangent_2;
            } else if (pt.type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE) {
                pts_in_segment = new Geometry.Point[4];
                pts_in_segment[0] = pt.curve_begin;
                pts_in_segment[1] = pt.tangent_1;
                pts_in_segment[2] = pt.tangent_2;
                pts_in_segment[3] = pt.curve_end;
            } else if (pt.type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE) {
                pts_in_segment = new Geometry.Point[4];
                pts_in_segment[0] = pt.curve_begin;
                pts_in_segment[1] = pt.tangent_1;
                pts_in_segment[2] = pt.tangent_2;
                pts_in_segment[3] = pt.curve_end;
            }

            // Update bounds for all these points.
            foreach (var point in pts_in_segment) {
                bounds.left = double.min (bounds.left, point.x);
                bounds.right = double.max (bounds.right, point.x);
                bounds.top = double.min (bounds.top, point.y);
                bounds.bottom = double.max (bounds.bottom, point.y);
            }
        }

        return bounds;
    }

    public static Geometry.Rectangle calculate_bounds_for_curve (Geometry.PathSegment segment, Geometry.Point point_before) {
        var p1 = segment.curve_begin;
        var p2 = segment.tangent_1;
        var p3 = segment.tangent_2;
        var p4 = segment.curve_end;

        double min_x = double.MAX, min_y = double.MAX, max_x = double.MIN, max_y = double.MIN;

        if (
            segment.type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE ||
            segment.type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE
        ) {
            double[] b1_extremes = Utils.Bezier.get_extremes (point_before, p2, p1);
            double[] b2_extremes = Utils.Bezier.get_extremes (p1, p3, p4);

            double temp = double.min (b1_extremes[0], b2_extremes[0]);
            min_x = double.min (min_x, temp);

            temp = double.min (b1_extremes[1], b2_extremes[1]);
            min_y = double.min (min_y, temp);

            temp = double.max (b1_extremes[2], b2_extremes[2]);
            max_x = double.max (max_x, temp);

            temp = double.max (b1_extremes[3], b2_extremes[3]);
            max_y = double.max (max_y, temp);
        } else if (segment.type == Lib.Modes.PathEditMode.Type.QUADRATIC_LEFT) {
            double[] b_extremes = Utils.Bezier.get_extremes (point_before, p2, p1);

            min_x = double.min (b_extremes[0], min_x);
            min_y = double.min (b_extremes[1], min_y);
            max_x = double.max (b_extremes[2], max_x);
            max_y = double.max (b_extremes[3], max_y);
        } else if (segment.type == Lib.Modes.PathEditMode.Type.QUADRATIC_RIGHT) {
            double[] b_extremes = Utils.Bezier.get_extremes (point_before, p3, p4);

            min_x = double.min (b_extremes[0], min_x);
            min_y = double.min (b_extremes[1], min_y);
            max_x = double.max (b_extremes[2], max_x);
            max_y = double.max (b_extremes[3], max_y);
        } else {
            assert (false);
        }

        return Geometry.Rectangle.with_coordinates (min_x, min_y, max_x, max_y);
    }
    public static Geometry.Point transform_point_around_item_origin (
        Geometry.Point point,
        Cairo.Matrix mat,
        bool invert = false
    ) {
        var matrix = Utils.GeometryMath.multiply_matrices (Cairo.Matrix.identity (), mat);

        if (invert) {
            matrix.invert ();
        }

        var new_point = Geometry.Point (point.x, point.y);
        matrix.transform_point (ref new_point.x, ref new_point.y);
        return new_point;
    }

}

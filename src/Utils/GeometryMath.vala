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
        ref Geometry.TransformedRectangle area
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

    public static Geometry.TransformedRectangle apply_stretch (
        Cairo.Matrix stretch_mat,
        Geometry.TransformedRectangle area,
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
}

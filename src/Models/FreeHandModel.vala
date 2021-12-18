/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

public class Akira.Models.FreeHandModel : Object {
    public Lib.Items.ModelInstance instance { get; construct; }
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private ViewLayers.ViewLayerPath path_layer;

    // These store a copy of points and commands in the path.
    private Lib.Modes.PathEditMode.Type[] commands;
    private Geometry.Point[] points;

    public Geometry.Point first_point;

    // This stores the raw points taken directly from input events.
    // These points are further processed to fit a curve.
    private Geometry.Point[] raw_points;

    // This is the error that we allow for approximating bezier curves.
    private const double TOLERANCE = 10.0;

    // This class provides methods for operating on bezier curves.
    private class Bezier {
        // Calculates the value of bezier curve at t. Returns that point.
        public static Geometry.Point q (Geometry.Point[] ctrl, double t) {
            var tx = 1.0 - t;
            var pa = ctrl[0].scale (tx * tx * tx);
            var pb = ctrl[1].scale (3 * tx * tx * t);
            var pc = ctrl[2].scale (3 * tx * t * t);
            var pd = ctrl[3].scale (t * t * t);

            return pa.add (pb).add (pc).add (pd);
        }

        // Calculates value of first derivative of bezier curve at t. Returns that point.
        public static Geometry.Point q_prime (Geometry.Point[] ctrl, double t) {
            var tx = 1.0 - t;
            var pa = ctrl[1].sub (ctrl[0]).scale (3 * tx * tx);
            var pb = ctrl[2].sub (ctrl[1]).scale (3 * tx * tx);
            var pc = ctrl[3].sub (ctrl[2]).scale (3 * tx * tx);

            return pa.add (pb).add (pc);
        }

        // Calculates value of second derivative of bezier curve at t. Returns that point.
        public static Geometry.Point q_prime_prime (Geometry.Point[] ctrl, double t) {
            var tx = 1.0 - t;
            var pa = ctrl[2].sub (ctrl[1].scale (2)).add (ctrl[0]).scale (6 * tx);
            var pb = ctrl[3].sub (ctrl[2].scale (2)).add (ctrl[1]).scale (6 * tx);

            return pa.add (pb);
        }
    }

    public FreeHandModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        commands = instance.components.path.commands;
        points = instance.components.path.data;

        raw_points = new Geometry.Point[0];

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        update_view ();
    }

    public void add_raw_point (Geometry.Point point) {
        raw_points.resize (raw_points.length + 1);
        raw_points[raw_points.length - 1] = point.sub (first_point);

        update_view ();
    }

    public void fit_curve () {
        var len = raw_points.length;

        Geometry.Point left_tan = normalize (raw_points[1].sub (raw_points[len]));
        Geometry.Point right_tan = normalize (raw_points[len - 2].sub (raw_points[len - 1]));

        points = fit_cubic (raw_points, 0, len - 1, left_tan, right_tan);

        commands = new Lib.Modes.PathEditMode.Type[points.length / 4];
        for (int i = 0; i < commands.length; ++i) {
            commands[i] = Lib.Modes.PathEditMode.Type.BEZIER;
        }

        points = recalculate_points (points);
        instance.components.path = new Lib.Components.Path.from_points (points, commands);
        recompute_components ();
    }

    /*
     * This method tries to fit a bezier curve onto the given set of points.
     * If the error between the approximation is too large, then we divide the points into 2 parts
     * apply the same algorithm recursively.

     * pts => the list of all points.
     * first => the starting index of points we will consider in this iteration.
     * last => the end index of points we will consider in this iteration.
     * left_tan => the left tangent vector. Direction is same as line joining first 2 points.
     * right_tan => the right tangent vector. Direction is same as line joining last 2 points.
     */
    private Geometry.Point[] fit_cubic (Geometry.Point[] pts, int first, int last, Geometry.Point left_tan, Geometry.Point right_tan) {
        // The maximum error permissible before we try to divide and recurse.
        var iteration_error = TOLERANCE * TOLERANCE;
        // Number of times we will make adjustments in the points and try to refit before recursing.
        var max_iterations = 20;

        // In case only 2 points are left, apply heuristics.
        if ((last - first + 1) == 2) {
            double dist = pts[last].distance (pts[first]) / 3.0;
            Geometry.Point[] bez_curve = new Geometry.Point[4];
            bez_curve[0] = pts[first];
            bez_curve[1] = bez_curve[0].add (left_tan.scale (dist));
            bez_curve[2] = bez_curve[3].add (right_tan.scale (dist));
            bez_curve[3] = pts[last];

            return bez_curve;
        }

        var u = chord_length_parameterize (pts, first, last);
        var bez_curve = generate_bezier (pts, first, last, u, left_tan, right_tan);

        int split;
        var max_error = compute_max_error (pts, first, last, bez_curve, u, out split);

        if (max_error < TOLERANCE) {
            return bez_curve;
        }

        double[] u_prime;
        // If the error exceeds the accepted limit, but is still within the max permissible bound,
        // Reparameterize and try to fit again.
        if (max_error < iteration_error) {

            u_prime = u;
            var prev_error = max_error;
            var prev_split = split;

            for (int i = 0; i < max_iterations; ++i) {
                u_prime = reparameterize (pts, first, last, u_prime, bez_curve);
                bez_curve = generate_bezier (pts, first, last, u_prime, left_tan, right_tan);
                max_error = compute_max_error (pts, first, last, bez_curve, u, out split);

                if (max_error < TOLERANCE) {
                    return bez_curve;
                }

                if (split == prev_split) {
                    var err_change = (max_error / prev_error);
                    if (err_change > 0.9999 || err_change < 1.0001) {
                        break;
                    }
                }

                prev_error = max_error;
                prev_split = split;
            }
        }

        var center_tan = pts[split - 1].sub (pts[split + 1]);
        if (center_tan.x == 0 && center_tan.y == 0) {
            center_tan = pts[split - 1].sub (pts[split]);
            center_tan.x = -1 * center_tan.y;
            center_tan.y = center_tan.x;
        }

        var to_center_tangent = normalize (center_tan);
        var from_center_tangent = to_center_tangent.scale (-1);

        var cubic_curve = new Geometry.Point[0];
        foreach (var it in fit_cubic (pts, first, split, left_tan, to_center_tangent)) {
            cubic_curve += it;
        }

        foreach (var it in fit_cubic (pts, split, last, from_center_tangent, right_tan)) {
            cubic_curve += it;
        }

        return cubic_curve;
    }

    // Assigns parameter values to points using relative distances.
    double[] chord_length_parameterize (Geometry.Point[] pts, int first, int last) {
        double[] u = new double[1];
        u[0] = 0.0;

        for (int i = first + 1; i <= last; ++i) {
            u += u[i - first - 1] + pts[i].distance (pts[i - 1]);
        }

        for (int i = 0; i < u.length; ++i) {
            u[i] = u[i] / u[u.length - 1];
        }

        return u;
    }

    // Uses Least Squares Method to find bezier control points for a region.
    private Geometry.Point[] generate_bezier (Geometry.Point[] pts, int first, int last, double[] u_prime, Geometry.Point left_tan, Geometry.Point right_tan) {
        var bez_curve = new Geometry.Point[4];
        bez_curve[0] = pts[first];
        bez_curve[3] = pts[last];
        var n_pts = last - first + 1;

        Geometry.Point[,] A = new Geometry.Point[n_pts, 2]; //vala-lint=naming-convention

        for (int i = 0; i < n_pts; ++i) {
            var u = u_prime[i];
            var ux = 1.0 - u;
            A[i, 0] = left_tan.scale (3 * u * ux * ux);
            A[i, 1] = right_tan.scale (3 * u * u * ux);
        }

        double[,] C = new double[2, 2]; //vala-lint=naming-convention
        double[] X = new double[2]; //vala-lint=naming-convention
        C[0, 0] = C[0, 1] = C[1, 0] = C[1, 1] = 0;
        X[0] = X[1] = 0;

        for (int i = 0; i < u_prime.length; ++i) {
            C[0, 0] += A[i, 0].dot (A[i, 0]);
            C[0, 1] += A[i, 0].dot (A[i, 1]);
            C[1, 0] = C[0, 1];
            C[1, 1] += A[i, 1].dot (A[i, 1]);

            var first_pt = pts[first];
            var last_pt = pts[last];
            Geometry.Point[] ctrl = {first_pt, first_pt, last_pt, last_pt};
            var tmp = pts[i + first].sub (Bezier.q (ctrl, u_prime[i]));

            X[0] += A[i, 0].dot (tmp);
            X[1] += A[i, 1].dot (tmp);
        }

        // Calculate determinants of C and X.
        var det_C0_C1 = C[0, 0] * C[1, 1] - C[1, 0] * C[0, 1]; //vala-lint=naming-convention
        var det_C0_X = C[0, 0] * X[1] - C[1, 0] * X[0]; //vala-lint=naming-convention
        var det_X_C1 = X[0] * C[1, 1] - X[1] * C[0, 1]; //vala-lint=naming-convention

        double alpha_l = (det_C0_C1 == 0) ? 0 : (det_X_C1 / det_C0_C1);
        double alpha_r = (det_C0_C1 == 0) ? 0 : (det_C0_X / det_C0_C1);

        var seg_length = pts[last].distance (pts[first]);
        var epsilon = 1.0e-6 * seg_length;

        //If alpha negative, use the Wu/Barsky heuristic.
        //If alpha is 0, you get coincident control points that lead to
        //divide by zero in any subsequent new_raphson_root_find() call.
        if (alpha_l < epsilon || alpha_r < epsilon) {
            var dist = seg_length / 3.0;
            //Fall back on standard (probably inaccurate) formula, and subdivide further if needed.
            bez_curve[1] = bez_curve[0].add (left_tan.scale (dist));
            bez_curve[2] = bez_curve[3].add (right_tan.scale (dist));

            return bez_curve;
        }

        //First and last control points of the Bezier curve are
        //positioned exactly at the first and last data points
        //Control points 1 and 2 are positioned an alpha distance out
        //on the tangent vectors, left and right, respectively
        bez_curve[1] = bez_curve[0].add (left_tan.scale (alpha_l));
        bez_curve[2] = bez_curve[3].add (right_tan.scale (alpha_r));

        return bez_curve;
    }

    private double[] reparameterize (Geometry.Point[] pts, int first, int last, double[] u, Geometry.Point[] bez_curve) {

        var u_prime = new double[u.length];
        for (int i = first; i <= last; ++i) {
            u_prime[i - first] = newton_raphson_root_find (bez_curve, pts[i], u[i - first]);
        }

        return u_prime;
    }

    private double newton_raphson_root_find (Geometry.Point[] bez_curve, Geometry.Point p, double u) {
        var d = Bezier.q (bez_curve, u).sub (p);
        var q_prime = Bezier.q_prime (bez_curve, u);

        double numerator = d.dot (q_prime);
        double denominator = norm (q_prime) * norm (q_prime) + 2 * Bezier.q_prime_prime (bez_curve, u).dot (d);

        if (denominator == 0.0f) {
            return u;
        }

        return (u - (numerator / denominator));
    }

    private double compute_max_error (Geometry.Point[] pts, int first, int last, Geometry.Point[] bez_curve, double[] u, out int split) {
        split = (last + first) / 2;
        double max_dist = 0.0;

        var t_dist = map_to_relative_dist (bez_curve, 10);

        for (int i = first; i <= last; ++i) {
            var point = pts[i];
            var t = find_t (bez_curve, u[i - first], t_dist, 10);
            var v = Bezier.q (bez_curve, t).sub (point);

            var dist = Math.pow (norm (v), 2);

            if (dist > max_dist) {
                max_dist = dist;
                split = i;
            }
        }

        return max_dist;
    }

    private double[] map_to_relative_dist (Geometry.Point[] bez_curve, double parts) {

        var b_t_dist = new double[1];
        b_t_dist[0] = 0;

        var b_t_prev = bez_curve[0];
        var sum_len = 0.0;

        for (int i = 1; i <= parts; ++i) {
            var b_t_curr = Bezier.q (bez_curve, i / parts);
            sum_len += norm (b_t_curr.sub (b_t_prev));

            b_t_dist += sum_len;
            b_t_prev = b_t_curr;
        }

        for (int i = 0; i < b_t_dist.length; ++i) {
            b_t_dist[i] /= sum_len;
        }

        return b_t_dist;
    }

    private double find_t (Geometry.Point[] bez_curve, double param, double[] t_dist, double parts) {
        if (param < 0) {
            return 0;
        }

        if (param > 1) {
            return 1;
        }

        for (int i = 1; i <= parts; ++i) {

            if (param <= t_dist[i]) {
                var t_min = (i - 1) / parts;
                var t_max = i / parts;
                var len_min = t_dist[i - 1];
                var len_max = t_dist[i];

                var t = (param - len_min) / (len_max - len_min) * (t_max - t_min) + t_min;
                return t;
            }
        }

        return 0;
    }

    private double norm (Geometry.Point p) {
        return p.distance (Geometry.Point (0, 0));
    }

    private Geometry.Point normalize (Geometry.Point pt) {
            var length = norm (pt);
            return pt.scale (1.0 / length);
    }

    /*
     * This method shift all points in path such that none of them are in negative space.
     */
    private Geometry.Point[] recalculate_points (Geometry.Point[] points) {
        double min_x = 0, min_y = 0;

        foreach (var pt in points) {
            if (pt.x < min_x) {
                min_x = pt.x;
            }
            if (pt.y < min_y) {
                min_y = pt.y;
            }
        }

        Geometry.Point[] recalculated_points = new Geometry.Point[points.length];

        // Shift all the points.
        for (int i = 0; i < points.length; ++i) {
            recalculated_points[i] = Geometry.Point (points[i].x - min_x, points[i].y - min_y);
        }

        // Then shift the reference point.
        first_point.x += min_x;
        first_point.y += min_y;

        return recalculated_points;
    }

    private void recompute_components () {
        // To calculate the new center of bounds of rectangle,
        // Move the center to point where user placed first point. This is represented as (0,0) internally.
        // Then translate it to the relative center of bounding box of path.
        var bounds = instance.components.path.calculate_extents ();
        double center_x = first_point.x + bounds.center_x;
        double center_y = first_point.y + bounds.center_y;

        instance.components.center = new Lib.Components.Coordinates (center_x, center_y);
        instance.components.size = new Lib.Components.Size (bounds.width, bounds.height, false);
        // Update the component.
        view_canvas.items_manager.item_model.mark_node_geometry_dirty_by_id (instance.id);
        view_canvas.items_manager.compile_model ();

        // After we have computed the path, there is no need to show to raw points.
        // Update the view without those.
        update_view (false);
    }

    /*
     * Recalculates the extents and updates the ViewLayerPath
     */
    private void update_view (bool show_live_path = true) {
        PathDataModel path_data = PathDataModel ();
        path_data.source_type = Lib.Modes.AbstractInteractionMode.ModeType.FREE_HAND;

        var points = instance.components.path.data;

        var coordinates = view_canvas.selection_manager.selection.coordinates ();

        Geometry.Rectangle extents = Geometry.Rectangle.empty ();
        extents.left = coordinates.center_x - coordinates.width / 2.0;
        extents.right = coordinates.center_x + coordinates.width / 2.0;
        extents.top = coordinates.center_y - coordinates.height / 2.0;
        extents.bottom = coordinates.center_y + coordinates.height / 2.0;

        path_data.points = points;
        path_data.commands = commands;

        if (show_live_path) {
            path_data.live_pts = raw_points;
        }

        path_data.length = raw_points.length;
        path_data.extents = extents;
        path_data.rot_angle = instance.components.transform.rotation;

        //  replaace thhis code from the path segment pr.
        path_data.live_extents = get_extents_using_live_pts (extents);

        path_layer.update_path_data (path_data);
    }

    private Geometry.Rectangle get_extents_using_live_pts (Geometry.Rectangle extents) {
        if (points.length == 0 || raw_points.length == 0) {
            return extents;
        }

        var data = new Geometry.Point[raw_points.length + 1];

        data[0] = Geometry.Point ();
        data[0].x = first_point.x;
        data[0].y = first_point.y;

        for (int i = 0; i < raw_points.length; ++i) {
            data[i + 1].x = raw_points[i].x + first_point.x;
            data[i + 1].y = raw_points[i].y + first_point.y;
        }

        // The array of commands isn't really needed for calculating extents. So just keep it empty.
        var cmds = new Lib.Modes.PathEditMode.Type[0];
        var live_path = new Lib.Components.Path.from_points (data, cmds);

        return live_path.calculate_extents ();
    }
}

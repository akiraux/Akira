/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Following is a generic structure used for storing all types of segments
 * is a path.
 * type : refers to the type of segment.
 * curve_begin : first point of a curve or end point of line.
 * tangent_1, tangent_2 : control points for controlling curves.
 * curve_end : last point of a curve
 *
 * We can create a different types of segments using this rep as
 * 1. Symmetric Bezier Curve (both control points are equi-distant from curve_begin)
 * 2. Asymmetric Bezier Curve (control points can be at different distances from curve_begin)
 * 3. Quadratic Curve (single control point)
 * 4. Line (pretty obvious)
 */
public struct Akira.Utils.PathSegment {
    public Lib.Modes.PathEditMode.Type type;

    // This point is used for drawing lines.
    // Store point in segment_begin to save space, but use the alias to make code readable.
    public Geometry.Point line_end {
        get {
            return curve_begin;
        }
        set {
            curve_begin = value;
        }
    }

    public Geometry.Point last_point {
        get {
            if (type == Lib.Modes.PathEditMode.Type.LINE) {
                return line_end;
            } else if (type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
                return curve_begin;
            }

            return curve_end;
        }
    }

    // These points are used for drawing curves.
    public Geometry.Point curve_begin;
    public Geometry.Point tangent_1;
    public Geometry.Point tangent_2;
    public Geometry.Point curve_end;

    public PathSegment () {
        type = Lib.Modes.PathEditMode.Type.NONE;
        curve_begin = Geometry.Point (double.MAX, double.MAX);
        tangent_1 = Geometry.Point (double.MAX, double.MAX);
        tangent_2 = Geometry.Point (double.MAX, double.MAX);
        curve_end = Geometry.Point (double.MAX, double.MAX);
    }

    // Creates new line segment.
    public PathSegment.line (Geometry.Point point) {
        type = Lib.Modes.PathEditMode.Type.LINE;
        line_end = point;
    }

    // Creates new cubic bezier curve.
    public PathSegment.cubic_bezier (
        Geometry.Point curve_begin,
        Geometry.Point control_point_1,
        Geometry.Point control_point_2,
        Geometry.Point curve_end
    ) {
        type = Lib.Modes.PathEditMode.Type.CUBIC;

        this.curve_begin = curve_begin;
        this.tangent_1 = control_point_1;
        this.tangent_2 = control_point_2;
        this.curve_end = curve_end;
    }

    // Creates new quadratic bezier curve
    public PathSegment.quadratic_bezier (
        Geometry.Point curve_begin,
        Geometry.Point control_point,
        Geometry.Point curve_end
    ) {
        type = Lib.Modes.PathEditMode.Type.QUADRATIC;

        this.curve_begin = curve_begin;
        //  this.curve_end = curve_end;
        this.tangent_1 = control_point;
    }

    // Use for converting a line segment to a curve.
    // point_before and point_after are used for calculating positions of control points.
    // If point_after is not provided, create a quadratic curve
    // If it is provided, create a symmetric cubic bezier curve
    public void line_to_curve (
        Utils.PathSegment? segment_before,
        Utils.PathSegment? segment_after
    ) {
        type = Lib.Modes.PathEditMode.Type.CUBIC;

        if (segment_before == null) {
            // TODO: create quaratic bezier here.
            return;
        }

        if (segment_after == null) {
            // TODO: create quadratic bezier here.
            return;
        }

        Geometry.Point point_before, point_after;

        if (segment_before.type == Lib.Modes.PathEditMode.Type.LINE) {
            point_before = segment_before.line_end;
        } else {
            point_before = Geometry.Point (
                (curve_begin.x + segment_before.curve_begin.x) / 2.0,
                (curve_begin.y + segment_before.curve_begin.y) / 2.0
            );
        }

        if (segment_after.type == Lib.Modes.PathEditMode.Type.LINE) {
            point_after = segment_after.line_end;
        } else {
            point_after = Geometry.Point (
                (curve_begin.x + segment_after.curve_begin.x) / 2.0,
                (curve_begin.y + segment_after.curve_begin.y) / 2.0
            );
        }

        var mid_vector = Geometry.Point (
            (point_after.x - point_before.x) / 2.0,
            (point_after.y - point_before.y) / 2.0
        );

        tangent_1 = Geometry.Point (curve_begin.x - mid_vector.x, curve_begin.y - mid_vector.y);
        tangent_2 = Geometry.Point (curve_begin.x + mid_vector.x, curve_begin.y + mid_vector.y);
        curve_end = point_after;
    }

    // Use for converting a curve segment to a line.
    public void curve_to_line () {
        type = Lib.Modes.PathEditMode.Type.LINE;
    }

    public Geometry.Point get_by_type (Lib.Modes.PathEditMode.PointType ptype) {
        if (ptype == Lib.Modes.PathEditMode.PointType.LINE_END) {
            return line_end;
        }

        if (ptype == Lib.Modes.PathEditMode.PointType.CURVE_BEGIN) {
            return curve_begin;
        }

        if (ptype == Lib.Modes.PathEditMode.PointType.TANGENT_FIRST) {
            return tangent_1;
        }

        if (ptype == Lib.Modes.PathEditMode.PointType.TANGENT_SECOND) {
            return tangent_2;
        }

        if (ptype == Lib.Modes.PathEditMode.PointType.CURVE_END) {
            return curve_end;
        }

        return Geometry.Point (0, 0);
    }

    public Lib.Modes.PathEditMode.PointType hit_test (Geometry.Point point, double thresh) {
        if (type == Lib.Modes.PathEditMode.Type.LINE) {
            if (Utils.GeometryMath.compare_points (line_end, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.LINE_END;
            }
        } else if (type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
            if (Utils.GeometryMath.compare_points (curve_begin, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.CURVE_BEGIN;
            }

            if (Utils.GeometryMath.compare_points (tangent_1, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.TANGENT_FIRST;
            }

            if (Utils.GeometryMath.compare_points (curve_end, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.CURVE_END;
            }
        } else if (type == Lib.Modes.PathEditMode.Type.CUBIC) {
            if (Utils.GeometryMath.compare_points (curve_begin, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.CURVE_BEGIN;
            }

            if (Utils.GeometryMath.compare_points (tangent_1, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.TANGENT_FIRST;
            }

            if (Utils.GeometryMath.compare_points (tangent_2, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.TANGENT_SECOND;
            }

            if (Utils.GeometryMath.compare_points (curve_end, point, thresh)) {
                return Lib.Modes.PathEditMode.PointType.CURVE_END;
            }
        }

        return Lib.Modes.PathEditMode.PointType.NONE;
    }

    public bool check_tangents_inline () {
        var tangent_mid_x = (tangent_1.x + tangent_2.x) / 2.0;
        var tangent_mid_y = (tangent_1.y + tangent_2.y) / 2.0;

        double err_x = (tangent_mid_x - curve_begin.x).abs ();
        double err_y = (tangent_mid_y - curve_begin.y).abs ();

        if (err_x <= double.EPSILON && err_y <= double.EPSILON) {
            return true;
        }

        return false;
    }

    public void translate (double dx, double dy) {
        if (type == Lib.Modes.PathEditMode.Type.LINE) {
            line_end = Geometry.Point (line_end.x - dx, line_end.y - dy);
        } else if (type == Lib.Modes.PathEditMode.Type.QUADRATIC) {
            curve_begin = Geometry.Point (curve_begin.x - dx, curve_begin.y - dy);
            tangent_1 = Geometry.Point (tangent_1.x - dx, tangent_1.y - dy);
            curve_end = Geometry.Point (curve_end.x - dx, curve_end.y - dy);
        } else if (type == Lib.Modes.PathEditMode.Type.CUBIC) {
            curve_begin = Geometry.Point (curve_begin.x - dx, curve_begin.y - dy);
            tangent_1 = Geometry.Point (tangent_1.x - dx, tangent_1.y - dy);
            tangent_2 = Geometry.Point (tangent_2.x - dx, tangent_2.y - dy);
            curve_end = Geometry.Point (curve_end.x - dx, curve_end.y - dy);
        }
    }

    public void move_tangents (double delta_x, double delta_y, bool is_tan1_reference) {
        if (is_tan1_reference) {
            tangent_1.x -= delta_x;
            tangent_1.y -= delta_y;

            tangent_2.x += delta_x;
            tangent_2.y += delta_y;
        } else {
            tangent_1.x += delta_x;
            tangent_1.y += delta_y;

            tangent_2.x -= delta_x;
            tangent_2.y -= delta_y;
        }
    }

    public PathSegment.deserialized (Json.Object obj) {
        // TODO:
    }

    public Json.Node PathSegment.serialize () {
        var node = new Json.Node (Json.NodeType.OBJECT);
        return node;
    }
}

public struct Akira.Utils.SelectedPoint {
    public int sel_index;
    public Lib.Modes.PathEditMode.PointType sel_type;
    public bool tangents_staggered;

    public SelectedPoint () {
        tangents_staggered = false;
    }
}

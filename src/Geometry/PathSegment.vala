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
public struct Akira.Geometry.PathSegment {
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

    // Creates new line segment.
    public PathSegment.line (Geometry.Point point) {
        type = Lib.Modes.PathEditMode.Type.LINE;
        line_end = point;

        tangent_1 = Geometry.Point (0, 0);
        tangent_2 = Geometry.Point (0, 0);
        curve_end = Geometry.Point (0, 0);
    }

    // Creates new cubic bezier curve.
    public PathSegment.cubic_bezier (
        Geometry.Point curve_begin,
        Geometry.Point control_point_1,
        Geometry.Point control_point_2,
        Geometry.Point curve_end
    ) {
        type = Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE;

        this.curve_begin = curve_begin;
        this.tangent_1 = control_point_1;
        this.tangent_2 = control_point_2;
        this.curve_end = curve_end;
    }

    public PathSegment.cubic_bezier_single (
        Geometry.Point curve_begin,
        Geometry.Point control_point_1,
        Geometry.Point control_point_2,
        Geometry.Point curve_end
    ) {
        type = Lib.Modes.PathEditMode.Type.CUBIC_SINGLE;

        this.curve_begin = curve_begin;
        this.tangent_1 = control_point_1;
        this.tangent_2 = control_point_2;
        this.curve_end = curve_end;
    }

    // Creates new quadratic bezier curve
    public PathSegment.quadratic_bezier (
        Geometry.Point curve_begin,
        Geometry.Point control_point
    ) {
        type = Lib.Modes.PathEditMode.Type.QUADRATIC;

        this.curve_begin = curve_begin;
        this.tangent_1 = control_point;

        tangent_2 = Geometry.Point (0, 0);
        curve_end = Geometry.Point (0, 0);
    }


    public PathSegment copy () {
        var segment = PathSegment ();

        segment.type = type;
        segment.curve_begin = curve_begin;
        segment.tangent_1 = tangent_1;
        segment.tangent_2 = tangent_2;
        segment.curve_end = curve_end;

        return segment;
    }

    // Use for converting a line segment to a curve.
    // point_before and point_after are used for calculating positions of control points.
    // If point_after is not provided, create a quadratic curve
    // If it is provided, create a symmetric cubic_DOUBLE bezier curve
    public void line_to_curve (
        PathSegment? segment_before,
        PathSegment? segment_after
    ) {
        // Atleast one of the segments must be present inorder to calculate tangents.
        assert (segment_before != null && segment_after != null);

        // When converting to quadratic curves, this is the dist. at which tangents are placed.
        double tangent_length = 100;
        type = Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE;

        // If we are converting the first point of the segment,
        // Make it a quadratic curve. Never occurs, but kept as safeguard.
        if (segment_before == null) {
            type = Lib.Modes.PathEditMode.Type.QUADRATIC;
            tangent_1 = Geometry.Point (curve_begin.x - tangent_length, curve_begin.y - tangent_length);

            return;
        }

        // If last segment is being converted to curve, make it quadratic.
        if (segment_after == null) {
            type = Lib.Modes.PathEditMode.Type.QUADRATIC;
            tangent_1 = Geometry.Point (curve_begin.x + tangent_length, curve_begin.y + tangent_length);

            return;
        }

        // For all other segments, we need to find position for tangents.
        // Following will create tangents that are parallel to CURVE_BEGIN and CURVE_END
        // to make result more appealing.
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

        assert (false);
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
        } else if (type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE) {
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
        } else if (
            type == Lib.Modes.PathEditMode.Type.CUBIC_SINGLE ||
            type == Lib.Modes.PathEditMode.Type.CUBIC_DOUBLE
        ) {
            curve_begin = Geometry.Point (curve_begin.x - dx, curve_begin.y - dy);
            tangent_1 = Geometry.Point (tangent_1.x - dx, tangent_1.y - dy);
            tangent_2 = Geometry.Point (tangent_2.x - dx, tangent_2.y - dy);
            curve_end = Geometry.Point (curve_end.x - dx, curve_end.y - dy);
        }
    }

    public void transform (Cairo.Matrix transform, bool invert = false) {
        curve_begin = Utils.GeometryMath.transform_point_around_item_origin (curve_begin, transform, invert);
        tangent_1 = Utils.GeometryMath.transform_point_around_item_origin (tangent_1, transform, invert);
        tangent_2 = Utils.GeometryMath.transform_point_around_item_origin (tangent_2, transform, invert);
        curve_end = Utils.GeometryMath.transform_point_around_item_origin (curve_end, transform, invert);
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

    public void snap_points () {
        curve_begin = Geometry.Point (Math.round (curve_begin.x), Math.round (curve_begin.y));
        tangent_1 = Geometry.Point (Math.round (tangent_1.x), Math.round (tangent_1.y));
        tangent_2 = Geometry.Point (Math.round (tangent_2.x), Math.round (tangent_2.y));
        curve_end = Geometry.Point (Math.round (curve_end.x), Math.round (curve_end.y));
    }


    public PathSegment.deserialized (Json.Object obj) {
        // TODO:
    }

    public Json.Node PathSegment.serialize () {
        var node = new Json.Node (Json.NodeType.OBJECT);
        return node;
    }
}

public struct Akira.Geometry.SelectedPoint {
    public int sel_index;
    public Lib.Modes.PathEditMode.PointType sel_type;
    public bool tangents_staggered;

    public SelectedPoint () {
        tangents_staggered = false;
    }
}

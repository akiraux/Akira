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

public enum Akira.Utils.Type {
    LINE,
    QUADRATIC,
    CUBIC
}

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
    public Type type;

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

    // These points are used for drawing curves.
    public Geometry.Point curve_begin;
    public Geometry.Point tangent_1;
    public Geometry.Point tangent_2;
    public Geometry.Point curve_end;

    // Creates new line segment.
    public PathSegment.line (Geometry.Point point) {
        type = Type.CUBIC;
        line_end = point;
    }

    // Creates new cubic bezier curve.
    public PathSegment.cubic_bezier (
        Geometry.Point curve_begin,
        Geometry.Point control_point_1,
        Geometry.Point control_point_2,
        Geometry.Point curve_end
    ) {
        type = Type.CUBIC;

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
        type = Type.QUADRATIC;

        this.curve_begin = curve_begin;
        this.curve_end = curve_end;
        this.tangent_1 = control_point;
    }

    // Use for converting a line segment to a curve.
    // point_before and point_after are used for calculating positions of control points.
    // If point_after is not provided, create a quadratic curve
    // If it is provided, create a symmetric cubic bezier curve
    public void line_to_curve (
        Geometry.Point point_before,
        Geometry.Point? point_after = null
    ) {
        type = Type.CUBIC;
    }

    // Use for converting a curve segment to a line.
    public void curve_to_line () {
        type = Type.LINE;
    }
}

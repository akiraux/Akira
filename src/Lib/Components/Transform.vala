/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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

public class Akira.Lib.Components.Transform : Component, Copyable<Transform> {
    private double _rotation = 0.0;
    private double _scale_x = 1.0;
    private double _scale_y = 1.0;
    private double _skew_xy = 0.0;
    private double _skew_yx = 0.0;

    public double rotation { get { return _rotation; } }
    public double rotation_in_degrees { get { return _rotation * 180 / GLib.Math.PI; } }

    public Cairo.Matrix rotation_matrix {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.rotate (_rotation);
            return mat;
        }
    }

    public Cairo.Matrix scale_matrix {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.scale (_scale_x, _scale_y);
            return mat;
        }
    }

    public Cairo.Matrix skew_matrix {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.xy = _skew_xy;
            mat.yx = _skew_yx;
            return mat;
        }
    }

    public Cairo.Matrix transformation_matrix {
        get {
            Cairo.Matrix mat;
            Utils.GeometryMath.recompose_matrix (out mat, _scale_x, _scale_y, _skew_xy, _rotation);
            return mat;
        }
    }

    public Transform (
        double radians,
        double scale_x,
        double scale_y,
        double skew_xy,
        double skew_yx
    ) {
        _rotation = radians;
        _scale_x = scale_x;
        _scale_y = scale_y;
        _skew_xy = skew_xy;
        _skew_yx = skew_yx;
    }

    public Transform.from_rotation (double in_radians) {
        _rotation = in_radians;
    }

    public Transform.deserialized (Json.Object obj) {
        _rotation = obj.get_double_member ("rotation");
        _scale_x = obj.get_double_member ("scale_x");
        _scale_y = obj.get_double_member ("scale_y");
        _skew_xy = obj.get_double_member ("skew_xy");
        _skew_yx = obj.get_double_member ("skew_yx");
    }

    protected override void serialize_details (ref Json.Object obj) {
        obj.set_double_member ("rotation", _rotation);
        obj.set_double_member ("scale_x", _scale_x);
        obj.set_double_member ("scale_y", _scale_y);
        obj.set_double_member ("skew_xy", _skew_xy);
        obj.set_double_member ("skew_yx", _skew_yx);
    }

    public Transform copy () {
        return new Transform (
            _rotation,
            _scale_x,
            _scale_y,
            _skew_xy,
            _skew_yx
        );
    }

    public Transform with_main_rotation (double in_radians) {
        return new Transform (
            in_radians,
            _scale_x,
            _scale_y,
            _skew_xy,
            _skew_yx
        );
    }
}

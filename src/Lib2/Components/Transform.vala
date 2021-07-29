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

public class Akira.Lib2.Components.Transform : Copyable<Transform> {
    private double _main_rotation = 0.0;

    private double _transform_rotation = 0.0;
    private double _scale_x = 1.0;
    private double _scale_y = 1.0;
    private double _skew_xy = 0.0;
    private double _skew_yx = 0.0;

    public double rotation { get { return _main_rotation; } }
    public double rotation_in_degrees { get { return _main_rotation * 180 / GLib.Math.PI; } }
    public double total_rotation { get { return _main_rotation; } }

    public Cairo.Matrix rotation_matrix {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.rotate(_main_rotation);
            return mat;
        }
    }

    public Cairo.Matrix extra_matrix {
        get {
            var mat = Cairo.Matrix.identity ();
            mat.rotate(_transform_rotation);

            var mat2 = Cairo.Matrix.identity ();
            mat2.xx = _scale_x;
            mat2.yy = _scale_y;
            mat2.xy = _skew_xy;
            mat2.yx = _skew_yx;
            return Utils.GeometryMath.multiply_matrices (mat2, mat);
        }
    }

    public Transform (
        double main_radians, 
        double transform_rotation, 
        double scale_x, 
        double scale_y, 
        double skew_xy, 
        double skew_yx
    ) {
        _main_rotation = main_radians;
        _transform_rotation = transform_rotation;
        _scale_x = scale_x;
        _scale_y = scale_y;
        _skew_xy = skew_xy;
        _skew_yx = skew_yx;
    }

    public Transform.from_rotation (double in_radians) {
        _main_rotation = in_radians;
    }

    public Transform copy () {
        return new Transform (
            _main_rotation,
            _transform_rotation,
            _scale_x,
            _scale_y,
            _skew_xy,
            _skew_yx
        );
    }

    public Transform with_main_rotation (double in_radians) {
        return new Transform (
            in_radians,
            _transform_rotation,
            _scale_x,
            _scale_y,
            _skew_xy,
            _skew_yx
        );
    }
}

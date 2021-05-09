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

public class Akira.Lib2.Components.CompiledGeometry : Object {
    private Cairo.Matrix _transform;

    public Cairo.Matrix transform {
        get { return _transform; }
    }

    public CompiledGeometry (Cairo.Matrix transform) {
        _transform = transform;
    }

    public static CompiledGeometry compile (
        Coordinates coordinates,
        Size size,
        Rotation rotation,
        Borders? borders,
        Flipped? flipped
    ) {
        var mat = Cairo.Matrix.identity();
        mat.x0 = coordinates.x;
        mat.y0 = coordinates.y;

        return new CompiledGeometry (mat);
    }
}

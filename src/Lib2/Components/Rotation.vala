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

public class Akira.Lib2.Components.Rotation : Copyable<Rotation> {
    private double _degrees;

    public Rotation (double degrees) {
        _degrees = degrees;
     }

    public Rotation from_radians (double radians) {
        return new Rotation (180 * GLib.Math.PI * radians);
    }

    public Rotation copy () {
        return new Rotation (_degrees);
    }

     public double in_degrees () {
        return _degrees;
     }

     public double in_radians () {
        return _degrees * GLib.Math.PI / 180.0;
     }

     public bool has_normal_rotation () {
         return GLib.Math.fmod (_degrees, 90) == 0;
     }
}

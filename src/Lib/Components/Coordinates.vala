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

public class Akira.Lib.Components.Coordinates : Component, Copyable<Coordinates> {
    private double _x;
    private double _y;

    public double x {
        get { return _x; }
    }

    public double y {
        get { return _y; }
    }

    public Coordinates (double x, double y) {
        _x = x;
        _y = y;
    }

    public Coordinates.deserialized (Json.Object obj) {
        _x = obj.get_double_member ("x");
        _y = obj.get_double_member ("y");
    }

    protected override void serialize_details (ref Json.Object obj) {
        obj.set_double_member ("x", _x);
        obj.set_double_member ("y", _y);
    }

    public Coordinates copy () {
        return new Coordinates (_x, _y);
    }

    public Coordinates translated (double dx, double dy) {
        return new Coordinates (_x + dx, _y + dy);
    }
}

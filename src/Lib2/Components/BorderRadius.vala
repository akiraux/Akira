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

public class Akira.Lib2.Components.BorderRadius : Copyable<BorderRadius> {

    private int _x;
    private int _y;
    private bool _autoscale;
    private bool _uniform;

    public BorderRadius (int x, int y, bool autoscale, bool uniform) {
        _x = x;
        _y = y;
        _autoscale = autoscale;
        _uniform = uniform;

        if (_uniform) {
            _x = _y;
        }
    }

    public BorderRadius copy () {
        return new BorderRadius (_x, _y, _autoscale, _uniform);

    }

    // Recommended accessors

    public int x () { return _x; }
    public int y () { return _x; }
    public bool autoscale () { return _autoscale; }
    public bool uniform () { return _uniform; }

    // Mutators

    public BorderRadius with_x (int new_x) {
        return new BorderRadius (_x, _y, _autoscale, _uniform);
    }

    public BorderRadius with_y (int new_y) {
        return new BorderRadius (_x, new_y, _autoscale, _uniform);
    }

    public BorderRadius with_autoscale (bool new_autoscale) {
        return new BorderRadius (_x, _y, new_autoscale, _uniform);
    }

    public BorderRadius with_uniform (bool new_uniform) {
        return new BorderRadius (_x, _y, _autoscale, new_uniform);
    }
}

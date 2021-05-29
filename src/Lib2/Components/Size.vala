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

public class Akira.Lib2.Components.Size : Copyable<Size> {
    private double _width;
    private double _height;
    private bool _locked;

    public double width {
        get { return _width; }
    }

    public double height {
        get { return _height; }
    }

    public bool locked {
        get { return _locked; }
    }

    public double ratio {
        get { return _height == 0 ? 0.0 : _width / _height; }
    }

    public Size (double width, double height, bool locked) {
        _locked = locked;
        _width = width;
        _height = height;
    }

    public Size copy () {
        return new Size (_width, _height, _locked);
    }

    public Size with_width (double new_width) {
        return new Size (new_width, _height, _locked);
    }

    public Size with_height (double new_height) {
        return new Size (_width, new_height, _locked);
    }
}

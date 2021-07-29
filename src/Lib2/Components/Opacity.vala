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

public class Akira.Lib2.Components.Opacity : Copyable<Opacity> {
    private double _opacity;

    public double opacity {
        get { return _opacity; }
    }

    public Opacity (double opacity) {
        if (opacity < 0.0) {
            _opacity = 0.0;
            return;
        }

        _opacity = opacity <= 100.0 ? opacity : 100.0;
    }

    public Opacity copy () {
        return new Opacity (_opacity);
    }
}

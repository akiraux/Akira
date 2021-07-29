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


public class Akira.Lib2.Components.Flipped : Copyable<Flipped> {
    private bool _horizontal;
    private bool _vertical;

    public bool horizontal {
        get { return _horizontal; }
    }

    public bool vertical {
        get { return _vertical; }
    }

    public Flipped (bool horizontal, bool vertical) {
        _horizontal = horizontal;
        _vertical = vertical;
    }

    public Flipped copy () {
        return new Flipped (horizontal, vertical);
    }
}

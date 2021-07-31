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

public class Akira.Lib2.Components.Border {
    public struct BorderData {
        public int _id;
        public Color _color;
        public int _size;

        public BorderData (int id = -1, Color color = Color (), int size = 0) {
            _id = id;
            _color = color;
            _size = size;
        }

        // Recommended accessors

        public int id () { return _id; }
        public Gdk.RGBA color () { return _color.rgba; }
        public bool is_color_hidden () { return _color.hidden; }
        public int size () { return _size; }

        // Mutators

        public BorderData with_color (Color new_color) {
            return BorderData (_id, new_color, _size);
        }

        public BorderData with_size (int new_size) {
            return BorderData (_id, _color, new_size);
        }
    }

    // main data for boxed Border
    private BorderData _data;

    public Border (BorderData data) {
        _data = data;
    }

    // Recommended accessors

    public int id () { return _data._id; }
    public Gdk.RGBA color () { return _data._color.rgba; }
    public bool is_color_hidden () { return _data._color.hidden; }
    public int size () { return _data._size; }
}

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

public class Akira.Lib2.Components.Border : Object {
    private int _id;
    private int _size;
    private Color _color;

    public int id {
        get { return _id; }
    }

    public int size {
        get { return _size; }
    }

    public Lib2.Components.Color color {
        get { return _color; }
    }

    public Border (int id, Lib2.Components.Color color, int size) {
        _id = id;
        _color = color;
        _size = size;
    }

    public Border with_id (int new_id) {
        return new Border (new_id, _color, _size);
    }

    public Border with_color (Lib2.Components.Color new_color) {
        return new Border (_id, new_color, _size);
    }

    public Border with_size (int new_size) {
        return new Border (_id, _color, new_size);
    }
}

/**
 * Copyright (c) 2019-2022 Alecaddd (https://alecaddd.com)
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

public class Akira.Lib.Components.Borders : Component, Copyable<Borders> {
    public struct Border {
        public int _id;
        public Color _color;
        public double _size;

        public Border (int id = -1, Color color = Color (), double? size = null) {
            _id = id;
            _color = color;
            _size = size != null ? size : settings.border_size;
        }

        public Border.deserialized (int id, Json.Object obj) {
            _id = id;
            _color = Color.deserialized (obj.get_object_member ("color"));
            _size = (double)obj.get_int_member ("size");
        }

        public Json.Node serialize () {
            var obj = new Json.Object ();
            obj.set_int_member ("id", _id);
            obj.set_member ("color", _color.serialize ());
            obj.set_double_member ("size", _size);
            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (obj);
            return node;
        }

        // Recommended accessors.
        public int id {
            get {
                return _id;
            }
        }
        public Gdk.RGBA color {
            get {
                return _color.rgba;
            }
        }
        public bool hidden {
            get {
                return _color.hidden;
            }
        }
        public double size {
            get {
                return _size;
            }
        }

        // Mutators.
        public Border with_color (Color new_color) {
            return Border (_id, new_color, _size);
        }

        public Border with_size (double new_size) {
            return Border (_id, _color, new_size);
        }
    }

    public Border[] data;

    public Borders () {
        data = new Border[0];
    }

    public Borders.single_color (Color color, int size) {
        data = new Border[1];
        data[0] = Border (0, color, size);
    }

    public Borders.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("border_data").get_elements ();
        data = new Border[0];

        var idx = 0;
        foreach (unowned var border in arr) {
            data.resize (data.length + 1);
            data[idx] = Border.deserialized (idx, border.get_object ());
            ++idx;
        }
    }

    protected override void serialize_details (ref Json.Object obj) {
        var array = new Json.Array ();

        foreach (unowned var d in data) {
            array.add_element (d.serialize ());
        }

        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        obj.set_member ("border_data", node);
    }

    public Borders copy () {
        var cln = new Borders ();
        cln.data = data;
        return cln;
    }

    // Recommended accessors.
    public Border? border_from_id (int id) {
        foreach (unowned var border in data) {
            if (border.id == id) {
                return border.with_color (border._color);
            }
        }
        return null;
    }

    public bool replace (Border border) {
        for (var i = 0; i < data.length; ++i) {
            if (data[i].id == border.id) {
                data[i] = border;
                return true;
            }
        }
        return false;
    }

    /*
     * Create a new Border with the passed color and add it to the data structure.
     * It's up to the code requiring this to then replace the borders component.
     */
    public void append_border_with_color (Color color, double? size = null) {
        int latest_id = int.MIN;
        foreach (unowned var border in data) {
            latest_id = int.max (latest_id, border.id);
        }
        latest_id++;
        var border = Border ((int) latest_id, color, size);
        data.resize (data.length + 1);
        data[data.length - 1] = border;
    }

    public int remove (uint id) {
        var ct = 0;
        foreach (unowned var border in data) {
            if (border.id == id) {
                return remove_at (ct) ? 1 : -1;
            }
            ++ct;
        }
        return -1;
    }

    private bool remove_at (int pos) {
        if (pos >= data.length || pos < 0) {
            assert (false);
            return false;
        }

        data.move (pos + 1, pos, data.length - pos - 1);
        data.resize (data.length - 1);
        return true;
    }

    /*
     * Helper method used to retrieve the size of the thickest visible border.
     */
    public double get_border_width () {
        double size = 0;
        foreach (unowned var border in data) {
            if (border.hidden) {
                continue;
            }
            size = double.max (size, border.size);
        }
        return size;
    }
}

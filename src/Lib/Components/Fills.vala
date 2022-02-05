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

public class Akira.Lib.Components.Fills : Component, Copyable<Fills> {
    public struct Fill {
        public int _id;
        public Color _color;

        public Fill (int id = -1, Color color = Color ()) {
            _id = id;
            _color = color;
        }

        public Fill.deserialized (int id, Json.Object obj) {
            _id = id;
            _color = Color.deserialized (obj.get_object_member ("color"));
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
        public bool is_color_hidden {
            get {
                return _color.hidden;
            }
        }

        // Mutators.
        public Fill with_color (Color new_color) {
            return Fill (_id, new_color);
        }

        public Json.Node serialize () {
            var obj = new Json.Object ();
            obj.set_int_member ("id", _id);
            obj.set_member ("color", _color.serialize ());
            var node = new Json.Node (Json.NodeType.OBJECT);
            node.set_object (obj);
            return node;
        }
    }

    public Fill[] data;

    public Fills () {
        data = new Fill[1];
    }

    public Fills.with_color (Color color) {
        data = new Fill[1];
        data[0] = Fill(0, color);
    }

    public Fills.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("fill_data").get_elements ();
        data = new Fill[0];
        var idx = 0;
        foreach (unowned var fill in arr) {
            data.resize (data.length + 1);
            data[idx] = Fill.deserialized (idx, fill.get_object ());
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
        obj.set_member ("fill_data", node);
    }

    public Fills copy () {
        var cln = new Fills ();
        cln.data = data;
        return cln;
    }

    // Recommended accessors.
    public Fill? fill_from_id (int id) {
        foreach (unowned var fill in data) {
            if (fill.id == id) {
                return fill.with_color (fill._color);
            }
        }
        return null;
    }

    public bool replace (Fill fill) {
        for (var i = 0; i < data.length; ++i) {
            if (data[i].id == fill.id) {
                data[i] = fill;
                return true;
            }
        }
        return false;
    }

    public void append (Fill fill) {
        data.resize (data.length + 1);
        data[data.length - 1] = fill;
    }

    public int remove (uint id) {
        var ct = 0;
        foreach (unowned var fill in data) {
            if (fill.id == id) {
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
 }

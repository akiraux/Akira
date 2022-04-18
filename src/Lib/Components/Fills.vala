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
        public Pattern _pattern;

        public Fill (int id = -1, Pattern pattern = new Pattern ()) {
            _id = id;
            _pattern = pattern;
        }

        public Fill.deserialized (int id, Json.Object obj) {
            _id = id;
            _pattern = new Pattern.deserialized (obj.get_object_member ("pattern"));
        }

        // Recommended accessors.
        public int id {
            get {
                return _id;
            }
        }
        public Pattern pattern {
            get {
                return _pattern;
            }
        }
        public bool hidden {
            get {
                return _pattern.hidden;
            }
        }

        // Mutators.
        public Fill with_color (Color new_color, int id = 0) {
            Pattern pattern = new Pattern.solid (new_color.rgba, new_color.hidden);
            var fill = Fill (id, pattern);
            fill._id = id;
            return fill;
        }

        public Json.Node serialize () {
            var obj = new Json.Object ();
            obj.set_int_member ("id", _id);
            obj.set_member ("pattern", _pattern.serialize ());
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
        data[0] = Fill (0, new Pattern.solid (color.rgba, color.hidden));
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
                return Fill (id, fill.pattern);
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

    /*
     * Create a new Fill with the passed color and add it to the data structure.
     * It's up to the code requiring this to then replace the fills component.
     */
    public void append_fill_with_color (Color color) {
        double latest_id = int.MIN;
        foreach (unowned var fill in data) {
            latest_id = double.max (latest_id, fill.id);
        }
        latest_id++;
        var pattern = new Pattern.solid (color.rgba, color.hidden);
        var fill = Fill ((int) latest_id, pattern);
        data.resize (data.length + 1);
        data[data.length - 1] = fill;
    }

    // Todo...
    public void append_fill_with_image () {}

    // Todo...
    public void append_fill_with_gradient () {}

    // Todo...
    public void append_fill_with_pattern () {}

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

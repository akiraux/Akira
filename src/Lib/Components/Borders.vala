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
        public Pattern _pattern {
            get {
                switch (active_pattern) {
                    case Pattern.PatternType.SOLID:
                        return solid_pattern;
                    case Pattern.PatternType.LINEAR:
                        return linear_pattern;
                    case Pattern.PatternType.RADIAL:
                        return radial_pattern;
                    default:
                        return solid_pattern;
                }
            }

            set {
                switch (active_pattern) {
                    case Pattern.PatternType.SOLID:
                        solid_pattern = value;
                        break;
                    case Pattern.PatternType.LINEAR:
                        linear_pattern = value;
                        break;
                    case Pattern.PatternType.RADIAL:
                        radial_pattern = value;
                        break;
                    default:
                        solid_pattern = value;
                        break;
                }
            }
        }

        // Each border item will have patterns for all three types,
        // so that user can easily switch between them.
        // However, the non active patterns will not be serialized.
        public Pattern solid_pattern;
        public Pattern linear_pattern;
        public Pattern radial_pattern;

        public Pattern.PatternType active_pattern;

        public double _size;

        public Border (int id = -1, Pattern pattern = new Pattern (), double? size = null) {
            _id = id;
            active_pattern = Pattern.PatternType.SOLID;

            var border_rgba = Gdk.RGBA ();
            border_rgba.parse (settings.border_color);
            solid_pattern = new Pattern.solid (border_rgba, false);

            linear_pattern = new Pattern.linear (Geometry.Point (5, 5), Geometry.Point (95, 95), false);
            radial_pattern = new Pattern.radial (Geometry.Point (5, 5), Geometry.Point (95, 95), false);

            _size = size != null ? size : settings.border_size;
        }

        public Border.deserialized (int id, Json.Object obj) {
            _id = id;
            _size = (double)obj.get_int_member ("size");
        }

        public Border.with_all_patterns (int id, Pattern solid_pattern, Pattern linear_pattern, Pattern radial_pattern, Pattern.PatternType type) {
            this.solid_pattern = solid_pattern;
            this.linear_pattern = linear_pattern;
            this.radial_pattern = radial_pattern;
            this.active_pattern = type;
        }

        public Json.Node serialize () {
            var obj = new Json.Object ();
            obj.set_int_member ("id", _id);
            obj.set_member ("pattern", _pattern.serialize ());
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
        public double size {
            get {
                return _size;
            }
        }

        // Mutators.
        public Border with_color (Color new_color) {
            Pattern pattern = new Pattern.solid (new_color.rgba, new_color.hidden);
            var border = Border (id, pattern, _size);
            return border;
        }

        public Border with_replaced_pattern (Pattern new_pattern) {
            var new_border = Border.with_all_patterns (_id, solid_pattern, linear_pattern, radial_pattern, new_pattern.type);
            new_border._pattern = new_pattern;

            return new_border;
        }

        public Border with_size (double new_size) {
            return Border (_id, _pattern, new_size);
        }
    }

    public Border[] data;

    public Borders () {
        data = new Border[1];
    }

    public Borders.single_color (Color color, int size) {
        data = new Border[1];
        data[0] = Border (0, new Pattern.solid (color.rgba, color.hidden), size);
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
                return Border.with_all_patterns (id, border.solid_pattern, border.linear_pattern, border.radial_pattern, border.active_pattern);
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
    public void append_border_with_color (Color color) {
        int latest_id = int.MIN;
        foreach (unowned var border in data) {
            latest_id = int.max (latest_id, border.id);
        }
        latest_id++;
        var pattern = new Pattern.solid (color.rgba, color.hidden);
        var border = Border ((int) latest_id, pattern);
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
}

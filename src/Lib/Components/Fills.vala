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

        // Each fill item will have patterns for all three types,
        // so that user can easily switch between them.
        // However, the non active patterns will not be serialized.
        public Pattern solid_pattern;
        public Pattern linear_pattern;
        public Pattern radial_pattern;

        public Pattern.PatternType active_pattern;

        public Fill (int id = -1, Pattern pattern = new Pattern ()) {
            _id = id;
            active_pattern = Pattern.PatternType.SOLID;

            var fill_rgba = Gdk.RGBA ();
            fill_rgba.parse (settings.fill_color);
            solid_pattern = new Pattern.solid (fill_rgba, false);

            linear_pattern = new Pattern.linear (Geometry.Point (5, 5), Geometry.Point (95, 95), false);
            radial_pattern = new Pattern.radial ();
        }

        public Fill.with_all_patterns (int id, Pattern solid_pattern, Pattern linear_pattern, Pattern radial_pattern, Pattern.PatternType type) {
            this.solid_pattern = solid_pattern;
            this.linear_pattern = linear_pattern;
            this.radial_pattern = radial_pattern;
            this.active_pattern = type;
        }

        public Fill.deserialized (int id, Json.Object obj) {
            _id = id;
            //  active_pattern = Pattern.PatternType.SOLID;

            //  solid_pattern = new Pattern.solid (0, 0, 0, 1);

            //  linear_pattern = new Pattern.linear (Geometry.Point (0, 0), Geometry.Point (100, 100), false);
            //  linear_pattern.add_stop_color (Gdk.RGBA () {red = 0, green = 0, blue = 0, alpha = 0}, 0);
            //  linear_pattern.add_stop_color (Gdk.RGBA () {red = 1, green = 1, blue = 1, alpha = 0}, 1);

            //  radial_pattern = new Pattern.radial ();
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

        public Fill with_replaced_pattern (Pattern new_pattern) {
            var new_fill = Fill ();

            new_fill._id = this._id;
            new_fill.active_pattern = new_pattern.type;
            new_fill.solid_pattern = this.solid_pattern;
            new_fill.linear_pattern = this.linear_pattern;
            new_fill.radial_pattern = this.radial_pattern;

            return new_fill;
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
                return Fill.with_all_patterns (id, fill.solid_pattern, fill.linear_pattern, fill.radial_pattern, fill.active_pattern);
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
        int latest_id = int.MIN;
        foreach (unowned var fill in data) {
            latest_id = int.max (latest_id, fill.id);
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

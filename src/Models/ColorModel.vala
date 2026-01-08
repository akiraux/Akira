/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 * Model to keep track of Fills and Borders colors of an item. We use this
 * model to easily bind the ListBox UI to the Fills and Borders Components.
 */
public class Akira.Models.ColorModel : GLib.Object {
    public signal void value_changed ();

    public class SignalBlocker {
        private unowned ColorModel item;

        public SignalBlocker (ColorModel fill_item) {
            item = fill_item;
            item.block_signal += 1;
        }

        ~SignalBlocker () {
            item.block_signal -= 1;
        }
    }

    protected int block_signal = 0;
    protected Lib.Items.ModelInstance _cached_instance;

    // All three types of patterns will be stored here.
    // Based on which type is active, update it.
    public Lib.Components.Pattern solid_pattern;
    public Lib.Components.Pattern linear_pattern;
    public Lib.Components.Pattern radial_pattern;

    public Lib.Components.Pattern.PatternType _active_pattern_type;
    public Lib.Components.Pattern.PatternType active_pattern_type {
        get {
            return _active_pattern_type;
        }

        set {
            _active_pattern_type = value;
            on_value_changed ();
            value_changed ();
        }
    }

    public Lib.Components.Pattern pattern {
        get {
            switch (_active_pattern_type) {
                case Lib.Components.Pattern.PatternType.SOLID:
                    return solid_pattern;
                case Lib.Components.Pattern.PatternType.LINEAR:
                    return linear_pattern;
                case Lib.Components.Pattern.PatternType.RADIAL:
                    return radial_pattern;
                default:
                    return solid_pattern;
            }
        }

        set {
            switch (_active_pattern_type) {
                case Lib.Components.Pattern.PatternType.SOLID:
                    solid_pattern = value;
                    break;
                case Lib.Components.Pattern.PatternType.LINEAR:
                    linear_pattern = value;
                    break;
                case Lib.Components.Pattern.PatternType.RADIAL:
                    radial_pattern = value;
                    break;
                default:
                    solid_pattern = value;
                    break;
            }

            on_value_changed ();
            value_changed ();
        }
    }

    private bool _hidden;
    public bool hidden {
        get {
            return _hidden;
        }
        set {
            if (value == _hidden) {
                return;
            }

            _hidden = value;
            on_value_changed ();
            value_changed ();
        }
    }

    private int _size;
    public int size {
        get {
            return _size;
        }
        set {
            if (value == _size) {
                return;
            }

            _size = value;
            on_value_changed ();
            value_changed ();
        }
    }

    public void move_pattern_position_by_delta (Utils.Nobs.Nob nob, Geometry.Point delta) {
        Geometry.Point percent_delta = Geometry.Point (
            delta.x * 100.0 / _cached_instance.components.size.width,
            delta.y * 100.0 / _cached_instance.components.size.height
        );

        switch (nob) {
            case Utils.Nobs.Nob.GRADIENT_START:
                pattern.start = Geometry.Point (
                    pattern.start.x - percent_delta.x,
                    pattern.start.y - percent_delta.y
                );
                break;
            case Utils.Nobs.Nob.GRADIENT_END:
                pattern.end = Geometry.Point (
                    pattern.end.x - percent_delta.x,
                    pattern.end.y - percent_delta.y
                );
                break;
            default:
                break;
        }

        on_value_changed ();
        value_changed ();
    }

    public virtual void on_value_changed () {}
    public virtual void delete () {}
}

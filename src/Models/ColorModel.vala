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

    private Gdk.RGBA _color;
    public Gdk.RGBA color {
        get {
            return _color;
        }
        set {
            if (value == _color) {
                return;
            }

            _color = value;
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

    public virtual void on_value_changed () {}
    public virtual void delete () {}
}

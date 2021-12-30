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
 * model to easily bind the GtkListBox UI to the Fills and Borders Components.
 */
public class Akira.Models.ColorModel : GLib.Object {
    private unowned Lib.Components.Fill? fill;
    private unowned Lib.Components.Border? border;

    public Type type;
    public enum Type {
        FILL,
        BORDER
    }

    public string color {
        owned get {
            return type == Type.FILL
                ? fill.color().to_string ()
                : border.color ().to_string ();
        }
        set {
            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (value);
            new_rgba.alpha = (double) alpha / 255;

            if (type == Type.FILL) {
                fill.set_color_rgba (new_rgba);
                return;
            }

            //border.set_color_rgba (new_rgba);
        }
    }

    public int alpha {
        get {
            return type == Type.FILL
                ? (int) fill.color ().alpha
                //: border.alpha;
                : -1;
        }
        set {
            if (type == Type.FILL) {
                var current_rgba = fill.color ();
                current_rgba.alpha = value;

                fill.set_color_rgba (current_rgba);
                return;
            }

            //border.alpha = value;
        }
    }

    public bool hidden {
        get {
            return type == Type.FILL
                ? fill.is_color_hidden ()
                //: border.is_color_hidden ();
                : true;
        }
        set {
            if (type == Type.FILL) {
                fill.set_hidden (value);
                return;
            }

            //border.hidden = value;
        }
    }

    public int size {
        get {
            //return border.size;
            return 0;

        }
        set {
            //border.size = value;
        }
    }

    public Lib.Components.Fill? get_fill () {
        return fill;
    }

    public ColorModel (Lib.Components.Fill? fill, Lib.Components.Border? border = null) {
        type = fill != null ? Type.FILL : Type.BORDER;
        this.fill = fill;
        this.border = border;
    }
}

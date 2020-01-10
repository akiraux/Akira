/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public abstract class Akira.Models.ItemModel : GLib.Object {
    public Lib.Models.CanvasItem item { get; construct; }
    public Akira.Models.ListModel list_model { get; set; }
    public Akira.Utils.BlendingMode blending_mode { get; set; }

    public string color {
        owned get {
            return item.border_color.to_string ();
        }
        set {
            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (value);
            item.border_color = new_rgba;
        }
    }

    public int alpha {
        get {
            return item.stroke_alpha;
        }
        set {
            item.stroke_alpha = value;
        }
    }

    public int border_size {
        get {
            return item.border_size;
        }
        set {
            item.border_size = value;
        }
    }

    public bool hidden {
        get {
            return item.hidden_border;
        }
        set {
            item.hidden_border = value;
        }
    }

    public string to_string () {
        return "Color: %s\nAlpha: %f\nSize: %i\nHidden: %s\nBlendingMode: %s".printf (
            color, alpha, border_size, (hidden ? "1" : "0"), blending_mode.to_string ());
    }
}

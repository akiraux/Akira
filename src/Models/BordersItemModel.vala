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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Models.BordersItemModel : Models.BaseModel {
    public string color {
        owned get {
            return border.color.to_string ();
        }
        set {
            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (value);
            border.color = new_rgba;
        }
    }

    public int alpha {
        get {
            return border.alpha;
        }
        set {
            border.alpha = value;
        }
    }

    public int size {
        get {
            return border.size;
        }
        set {
            border.size = value;
        }
    }

    public bool hidden {
        get {
            return border.hidden;
        }
        set {
            border.hidden = value;
        }
    }

    public BordersItemModel (Lib.Components.Border _border, ListModel _model) {
        border = _border;
        model = _model;
    }

    public string to_string () {
        return "Color: %s\nAlpha: %f\nSize: %i\nHidden: %s".printf (
            color, alpha, size, (hidden ? "1" : "0"));
    }
}

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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Models.FillsItemModel : Models.ItemModel {
    public string color {
        owned get {
            return item.color.to_string ();
        }
        set {
            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (value);
            item.color = new_rgba;
        }
    }

    public int alpha {
        get {
            return item.fill_alpha;
        }
        set {
            item.fill_alpha = value;
        }
    }

    public bool hidden {
        get {
            return item.hidden_fill;
        }
        set {
            item.hidden_fill = value;
        }
    }

    public Akira.Utils.BlendingMode blending_mode;

    public FillsItemModel (
        Lib.Models.CanvasItem item,
        Akira.Models.ListModel list_model
    ) {
        Object (
            item: item,
            list_model: list_model
        );
    }

    construct {
        item.has_fill = true;
        blending_mode = Akira.Utils.BlendingMode.NORMAL;
    }

    public string to_string () {
        return "Color: %s\nAlpha: %f\nHidden: %s\nBlendingMode: %s".printf (
            color, alpha, (hidden ? "1" : "0"), blending_mode.to_string ());
    }
}

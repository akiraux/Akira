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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Models.LayerModel : Models.ItemModel {
    public string name {
        owned get {
            return item.id;
        }
        set {
            // TODO: add "name" property to item
            debug (@"New item.name: $(value)");
        }
    }

    public string icon {
        get {
            return item.layer_icon;
        }
    }

    public bool? visibility {
        owned get {
            return item.visibility == Goo.CanvasItemVisibility.VISIBLE;
        }
        set {
            item.visibility = value
                ? Goo.CanvasItemVisibility.VISIBLE
                : Goo.CanvasItemVisibility.INVISIBLE;
        }
    }

    public bool? locked {
        get {
            return true;
        }

        set {
            debug (@"Locking panel: $(value)");
        }
    }

    public LayerModel (
        Lib.Models.CanvasItem item,
        Akira.Models.ListModel list_model
    ) {
        Object (
            item: item,
            list_model: list_model
        );
    }

    construct {
    }

    public string to_string () {
        return "Layer: %s Hidden: %d Lock: %d".printf (item.id, 0, 0);
    }
}

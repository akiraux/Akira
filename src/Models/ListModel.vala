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

public class Akira.Models.ListModel : GLib.Object, GLib.ListModel {
    private GLib.List<Akira.Models.FillsItemModel?> fills_list;

    construct {
        fills_list = new GLib.List<Akira.Models.FillsItemModel?> ();
    }

    public uint get_n_items () {
        return (uint) fills_list.length ();
    }

    public Object? get_item (uint position) {
        //  debug ("get item %u", position);
        var o = fills_list.nth_data (position);
        if (o != null) {
            return o as Object;
        }
        return null;
    }

    public Type get_item_type () {
        return typeof (Akira.Models.FillsItemModel);
    }

    public async void add (Lib.Models.CanvasItem item) {
        var model_item = new Models.FillsItemModel (
            item,
            Akira.Utils.BlendingMode.NORMAL,
            this
        );

        fills_list.append (model_item);

        items_changed (get_n_items () - 1, 0, 1);
        item.has_fill = true;
    }

    public async void remove_item (Akira.Models.FillsItemModel? item) {
        if (item == null) {
            return;
        }

        var position = fills_list.index (item);
        fills_list.remove (item);
        items_changed (position, 1, 0);

        // Update has_fill only if no fills are present and the item is still
        // selected. This is necessary to be sure we're removing the fill only
        // if the user specifically clicked on the trash icon.
        if (get_n_items () == 0 && item.item.selected) {
            item.item.has_fill = false;
        }
    }

    public async void clear () {
        //  debug ("clear fill list");
        fills_list.foreach ((item) => {
            //  debug ("remove fill");
            remove_item.begin (item);
        });
    }
}

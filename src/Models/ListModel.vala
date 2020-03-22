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
    private GLib.List<Akira.Models.BaseModel?> list;

    construct {
        list = new GLib.List<Akira.Models.BaseModel?> ();
    }

    public uint get_n_items () {
        return (uint) list.length ();
    }

    public Object? get_item (uint position) {
        Object? o = null;
        o = list.nth_data (position);
        if (o != null) {
            return o as Object;
        }

        return null;
    }

    public Type get_item_type () {
        return typeof (Akira.Models.ItemModel);
    }

    public Akira.Models.BaseModel? find_item (Akira.Lib.Models.CanvasItem item) {
        for (var i = 0; i < list.length (); i++) {
            if (list.nth_data (i).item == item) {
                return get_item (i) as Akira.Models.BaseModel;
            }
        }

        return null;
    }

    public int index (Akira.Lib.Models.CanvasItem item) {
        return (int) list.index (find_item (item));
    }

    public void add (Akira.Lib.Models.CanvasItem item, bool append = true) {
        add_item.begin (new Akira.Models.ItemModel (item, this), append);
    }

    public void remove (Akira.Lib.Models.CanvasItem item) {
        remove_item.begin (find_item (item));
    }

    public async void add_item (Akira.Models.BaseModel model_item, bool append = true) {
        if (append) {
            list.append (model_item);
            items_changed (get_n_items () - 1, 0, 1);
            return;
        }

        list.prepend (model_item);
        items_changed (0, 0, 1);
    }

    public async void remove_item (Object? item_model) {
        if (item_model == null) {
            return;
        }

        var model = (Akira.Models.BaseModel) item_model;
        var position = list.index (model);

        list.remove (model);
        items_changed (position, 1, 0);
    }

    public void insert_at (int position, Akira.Lib.Models.CanvasItem item) {
        var item_model = new Akira.Models.ItemModel (item, this);

        list.insert (item_model, position);

        items_changed (position, 0, 1);
    }

    public Akira.Lib.Models.CanvasItem? remove_at (int position) {
        var item = list.nth_data (position);
        list.remove (item);

        items_changed (position, 1, 0);

        return item.item;
    }

    public async void clear () {
        list.foreach ((item) => {
            remove_item.begin (item);
        });
    }

    public void sort (CompareFunc<Akira.Models.ItemModel?> sort_fn) {
        list.sort (sort_fn);
        items_changed (0, list.length (), list.length ());
    }
}

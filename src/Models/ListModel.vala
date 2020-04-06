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

public class Akira.Models.ListModel<Model> : GLib.Object, GLib.ListModel {
    private GLib.List<Model?> list;

    construct {
        list = new GLib.List<Model> ();
    }

    public uint get_n_items () {
        return (uint) list.length ();
    }

    public Object? get_item (uint position) {
        return list.nth_data (position) as Object;
    }

    public Model? nth_data (uint position) {
        return list.nth_data (position);
    }

    public Type get_item_type () {
        return typeof (Model);
    }

    public Model? find_item (Model item) {
        for (var i = 0; i < list.length (); i++) {
            if (list.nth_data (i) == item) {
                return get_item (i);
            }
        }

        return null;
    }

    public int index (Model item) {
        return (int) list.index (find_item (item));
    }

    public async void add_item (Model model_item, bool append = true) {
        if (append) {
            list.append (model_item);
            items_changed (get_n_items () - 1, 0, 1);
            return;
        }

        list.prepend (model_item);
        items_changed (0, 0, 1);
    }

    public async void remove_item (Model? model) {
        if (model == null) {
            return;
        }

        var position = list.index (model);

        list.remove (model);
        items_changed (position, 1, 0);
    }

    public void insert_at (int position, Model item) {
        list.insert (item, position);
        items_changed (position, 0, 1);
    }

    public Model? remove_at (int position) {
        var item = list.nth_data (position);
        list.remove (item);

        items_changed (position, 1, 0);

        return item;
    }

    public async void clear () {
        list.foreach ((item) => {
            remove_item.begin (item);
        });
    }

    public void sort (CompareFunc<Model> sort_fn) {
        list.sort (sort_fn);
        items_changed (0, list.length (), list.length ());
    }

    public Iterator<Model> iterator () {
        return new Iterator<Model> (this);
    }

    public class Iterator<Model> {
        private int index;
        private int length;
        private ListModel<Model> model;

        public Iterator (ListModel<Model> model) {
            this.model = model;
            this.length = (int) model.list.length ();
        }

        public bool next () {
            return index < length;
        }

        public Model get () {
            return model.list.nth_data (this.index++);
        }
    }
}

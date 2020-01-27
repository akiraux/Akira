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

public class Iterator {
  private int index;
  private weak GLib.List<Akira.Models.ItemModel?> list;

  public Iterator (GLib.List<Akira.Models.ItemModel?> list) {
    index = 0;
    this.list = list;
  }

  public bool next () {
    return index < list.length ();
  }

  public Akira.Models.ItemModel? get () {
    index++;
    return this.list.nth_data (index - 1);
  }
}

public class Akira.Models.ListModel : GLib.Object, GLib.ListModel {
    private GLib.List<Akira.Models.ItemModel?> list;

    construct {
        list = new GLib.List<Akira.Models.ItemModel?> ();
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

    public async void add_item (Akira.Models.ItemModel model_item) {
        list.append (model_item);
        items_changed (get_n_items () - 1, 0, 1);
    }

    public async void remove_item (Object? item_model) {
        if (item_model == null) {
            return;
        }

        var model = (Akira.Models.ItemModel) item_model;
        var position = list.index (model);
        list.remove (model);
        items_changed (position, 1, 0);
    }

    public async void clear () {
        list.foreach ((item) => {
            remove_item.begin (item);
        });
    }

    public Iterator iterator () {
      return new Iterator(list);
    }

    public void sort (CompareFunc<Akira.Models.ItemModel?> sort_fn) {
      list.sort (sort_fn);
      items_changed (0, 0, 0);
    }
}

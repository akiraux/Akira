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
    private GLib.List<Akira.Models.ItemModel?> list;
    private GLib.List<Akira.Models.FillsItemModel?> fills_list;
    private GLib.List<Akira.Models.BordersItemModel?> borders_list;
    public ListType list_type;
    public enum ListType {
        FILL,
        BORDER,
        NONE
    }

    public ListModel (ListType type) {
        list_type = type;
    }

    construct {
        if (list_type == ListType.FILL) {
            fills_list = new GLib.List<Akira.Models.FillsItemModel?> ();
        } else if (list_type == ListType.BORDER) {
            borders_list = new GLib.List<Akira.Models.BordersItemModel?> ();
        } else {
            list = new GLib.List<Akira.Models.ItemModel?> ();
        }
    }

    public uint get_n_items () {
        if (list_type == ListType.FILL) {
            return (uint) fills_list.length ();
        } else if (list_type == ListType.BORDER) {
            return (uint) borders_list.length ();
        } else {
            return (uint) list.length ();
        }
    }

    public Object? get_item (uint position) {
        Object? o = null;
        //  debug ("get item %u", position);
        if (list_type == ListType.FILL) {
            o = fills_list.nth_data (position);
        } else if (list_type == ListType.BORDER) {
            o = borders_list.nth_data (position);
        } else {
            o = list.nth_data (position);
        }

        if (o != null) {
            return o as Object;
        }

        return null;
    }

    public Type get_item_type () {
        if (list_type == ListType.FILL) {
            return typeof (Akira.Models.FillsItemModel);
        } else if (list_type == ListType.BORDER) {
            return typeof (Akira.Models.BordersItemModel);
        }
        return typeof (Akira.Models.ItemModel);
    }

    public async void add_item (Akira.Models.ItemModel model_item) {
        list.append (model_item);
        items_changed (get_n_items () - 1, 0, 1);
    }

    public async void add_fill (Lib.Models.CanvasItem item) {
        var model_item = new Models.FillsItemModel (
            item,
            Akira.Utils.BlendingMode.NORMAL,
            this
        );

        fills_list.append (model_item);
        items_changed (get_n_items () - 1, 0, 1);
        item.has_fill = true;
    }

    public async void add_border (Lib.Models.CanvasItem item) {
        var model_item = new Models.BordersItemModel (
            item,
            this,
            Akira.Utils.BlendingMode.NORMAL
        );

        borders_list.append (model_item);
        items_changed (get_n_items () - 1, 0, 1);
    }

    public async void remove_item (Object? item_model) {
        if (item_model == null) {
            return;
        }

        if (list_type == ListType.FILL) {
            var model = (Akira.Models.FillsItemModel) item_model;
            var position = fills_list.index (model);
            fills_list.remove (model);
            items_changed (position, 1, 0);

            // Update has_fill only if no fill is present and the item is still
            // selected. This is necessary to be sure we're removing the fill only
            // if the user specifically clicked on the trash icon.
            if (get_n_items () == 0 && model.item.selected) {
                model.item.has_fill = false;
            }
            return;
        } else if (list_type == ListType.BORDER) {
            var model = (Akira.Models.BordersItemModel) item_model;
            var position = borders_list.index (model);
            borders_list.remove (model);
            items_changed (position, 1, 0);

            // Update has_border only if no border is present and the item is still
            // selected. This is necessary to be sure we're removing the border only
            // if the user specifically clicked on the trash icon.
            if (get_n_items () == 0 && model.item.selected) {
                model.item.has_border = false;
            }
            return;
        }

        var model = (Akira.Models.ItemModel) item_model;
        var position = list.index (model);
        list.remove (model);
        items_changed (position, 1, 0);
    }

    public async void clear () {
        //  debug ("clear fill list");
        if (list_type == ListType.FILL) {
            fills_list.foreach ((item) => {
                //  debug ("remove fill");
                remove_item.begin (item);
            });
            return;
        } else if (list_type == ListType.BORDER) {
            borders_list.foreach ((item) => {
                //  debug ("remove fill");
                remove_item.begin (item);
            });
        }

        list.foreach ((item) => {
            remove_item.begin (item);
        });
    }
}

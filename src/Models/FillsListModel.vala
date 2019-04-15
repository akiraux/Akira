/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/


public class Akira.Models.FillsListModel : GLib.Object, GLib.ListModel {
    private GLib.List<Akira.Models.FillsItemModel> fills_list;

    public FillsListModel () {
        Object (
        );
    }

    construct {
        fills_list = new GLib.List<Akira.Models.FillsItemModel> ();
    }

    public uint get_n_items () {
        return (uint) fills_list.length ();
    }

    public Object? get_item (uint position) {
        return fills_list.nth_data (position) as Object;
    }

    public Type get_item_type () {
        return typeof (Akira.Models.FillsItemModel);
    }

    public void add () {
        var position = fills_list.length ();
        fills_list.append (new Akira.Models.FillsItemModel ("#abcded",
                                                            100,
                                                            true,
                                                            Akira.Utils.BlendingMode.NORMAL,
                                                            this));

        items_changed (position, 0, 1);
        update_fills ();
    }

    public void remove (Akira.Models.FillsItemModel item) {
        var position = fills_list.index (item);
        fills_list.remove (item);

        items_changed (position, 1, 0);
        update_fills ();
    }

    public void update_fills () {
        // Update fills on canvas
    }
}

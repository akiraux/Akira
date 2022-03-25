/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 * The scrollable fills panel.
 */
public class Akira.Layouts.FillsList.FillListBox : VirtualizingSimpleListBox {
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.HashMap<int, FillItemModel> fills;
    private FillListStore list_store;

    public FillListBox (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        fills = new Gee.HashMap<int, FillItemModel> ();
        list_store = new FillListStore ();
        // list_store.set_sort_func (fills_sort_function);

        model = list_store;

        // Factory function to reuse the already generated row UI element when
        // a new fill is created or the fills list scrolls to reveal fills
        // outside of the viewport.
        factory_func = (item, old_widget) => {
            FillListItem? row = null;
            if (old_widget != null) {
                row = old_widget as FillListItem;
            } else {
                row = new FillListItem (view_canvas);
            }

            row.assign ((FillItemModel) item);
            row.show_all ();

            return row;
        };
    }

    public void refresh_list () {
        if (fills.size > 0) {
            var removed = fills.size;
            fills.clear ();
            list_store.remove_all ();
            list_store.items_changed (0, removed, 0);
        }

        unowned var sm = view_canvas.selection_manager;
        if (sm.count () == 0) {
            return;
        }

        var added = 0;
        foreach (var selected in sm.selection.nodes.values) {
            var node = selected.node;
            if (node.instance.components.fills == null) {
                continue;
            }
            foreach (var fill in node.instance.components.fills.data) {
                var item = new FillItemModel (view_canvas, node, fill.id);
                fills[node.id] = item;
                list_store.add (item);
                added++;
            }
        }

        list_store.items_changed (0, 0, added);
    }
}

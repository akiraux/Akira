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
 * The borders panel.
 */
public class Akira.Layouts.BordersList.BorderListBox : VirtualizingSimpleListBox {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.HashMap<int, BorderItemModel> borders;
    private BorderListStore list_store;

    public BorderListBox (Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        borders = new Gee.HashMap<int, BorderItemModel> ();
        list_store = new BorderListStore ();
        // list_store.set_sort_func (borders_sort_function);

        model = list_store;

        // Factory function to reuse the already generated row UI element when
        // a new border is created or the borders list scrolls to reveal borders
        // outside of the viewport.
        factory_func = (item, old_widget) => {
            BorderListItem? row = null;
            if (old_widget != null) {
                row = old_widget as BorderListItem;
            } else {
                row = new BorderListItem (view_canvas);
            }

            row.assign ((BorderItemModel) item);
            row.show_all ();

            return row;
        };
    }

    public void refresh_list () {
        if (borders.size > 0) {
            var removed = borders.size;
            borders.clear ();
            list_store.remove_all ();
            list_store.items_changed (0, removed, 0);
        }

        unowned var sm = view_canvas.selection_manager;
        var count = sm.count ();
        if (count == 0) {
            return;
        }

        var added = 0;
        foreach (var selected in sm.selection.nodes.values) {
            // Break out of the look if we have multiple selected items and more
            // than 4 fills to avoid creating too many widgets at once.
            if (added > 4 && count > 1) {
                break;
            }

            var node = selected.node;
            if (node.instance.components.borders == null) {
                continue;
            }
            foreach (var border in node.instance.components.borders.data) {
                var item = new BorderItemModel (view_canvas, node, border.id);
                borders[node.id] = item;
                list_store.add (item);
                added++;
            }
        }

        list_store.items_changed (0, 0, added);
    }
}

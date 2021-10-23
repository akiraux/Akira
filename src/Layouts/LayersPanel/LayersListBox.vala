/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * The scrollable layers panel.
 */
public class Akira.Layouts.LayersPanel.LayersListBox : VirtualListBox {
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.HashMap<string, LayerItemModel> layers;
    private LayersListBoxModel layers_model;

    public LayersListBox (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        activate_on_single_click = true;
        layers = new Gee.HashMap<string, LayerItemModel> ();
        layers_model = new LayersListBoxModel ();

        factory_func = (item, old_widget) => {
            LayersListBoxRow? row = null;
            if (old_widget != null) {
                row = old_widget as LayersListBoxRow;
            } else {
                row = new LayersListBoxRow ();
            }

            row.assign ((LayerItemModel)item);
            row.show_all ();

            return row;
        };
    }
}

/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib2.Managers.SelectionManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    /*
     * Blocks notifications until class is destructed.
     */
    public class ChangeSignalBlocker {
        private unowned SelectionManager manager;

        public ChangeSignalBlocker (SelectionManager sm) {
            this.manager = sm;
            this.manager.block_change_notifications += 1;
        }

        ~ChangeSignalBlocker () {
            manager.block_change_notifications -= 1;
            manager.on_selection_changed ();
        }

    }

    public Lib2.Items.ItemSelection selection;
    protected int block_change_notifications = 0;

    public SelectionManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        selection = new Lib2.Items.ItemSelection (null);
    }

    public bool is_empty () {
        return selection.is_empty ();
    }

    public void reset_selection (Lib2.Items.ModelItem? selected_item) {
        if (is_empty () && selected_item == null) {
            return;
        }

        selection = new Lib2.Items.ItemSelection (selected_item);
        on_selection_changed ();
    }

    public void add_to_selection (Lib2.Items.ModelItem item) {
        selection.add_item (item);
        on_selection_changed ();
    }

    public bool item_selected (Lib2.Items.ModelItem item) {
        return selection.has_item (item);
    }

    public void on_selection_changed () {
        if (block_change_notifications == 0) {
            view_canvas.window.event_bus.selection_modified ();
        }
    }
}

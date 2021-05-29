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
 */

public class Akira.Lib2.Managers.CopyManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    public Gee.ArrayList<Lib2.Items.ModelItem> candidates;

    public CopyManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        view_canvas.window.event_bus.request_copy.connect(do_copy);
        view_canvas.window.event_bus.request_paste.connect(do_paste);
    }

    public void do_copy () {
        candidates = new Gee.ArrayList<Lib2.Items.ModelItem> ();

        foreach (var to_copy in view_canvas.selection_manager.selection.items) {
            candidates.add (to_copy.clone ());
        }
    }

    public void do_paste () {
        if (candidates.size == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        view_canvas.selection_manager.reset_selection (null);
        foreach (var to_paste in candidates) {
            var new_item = to_paste.clone ();
            view_canvas.items_manager.add_item_to_canvas (new_item);
            view_canvas.selection_manager.add_to_selection (new_item);
        }

    }
}

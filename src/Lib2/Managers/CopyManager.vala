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

    private Lib2.Items.Model copy_model;

    public CopyManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
    }

    construct {
        view_canvas.window.event_bus.request_copy.connect(do_copy);
        view_canvas.window.event_bus.request_paste.connect(do_paste);
    }

    public void do_copy () {
        copy_model = new Lib2.Items.Model ();

        int res = 0;
        foreach (var to_copy in view_canvas.selection_manager.selection.nodes.values) {
            res += Utils.ModelUtil.clone_from_model (
                view_canvas.items_manager.item_model,
                to_copy.id,
                copy_model,
                Lib2.Items.Model.origin_id
            );
        }

        var children = copy_model.node_from_id (Lib2.Items.Model.origin_id).children;

        assert (res == 0);
    }

    public void do_paste () {
        if (copy_model == null) {
            return;
        }

        var children = copy_model.node_from_id (Lib2.Items.Model.origin_id).children;

        if (children == null || children.length == 0) {
            return;
        }

        var blocker = new SelectionManager.ChangeSignalBlocker (view_canvas.selection_manager);
        (void) blocker;

        view_canvas.selection_manager.reset_selection ();

        int res = 0;
        foreach (var child in children.data) {
            res += Utils.ModelUtil.clone_from_model (
                copy_model,
                child.id,
                view_canvas.items_manager.item_model,
                Lib2.Items.Model.origin_id
            );
        }

        view_canvas.items_manager.compile_model ();
        assert (res == 0);
    }
}

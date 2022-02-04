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

/*
 *
 */
public class Akira.Lib.Managers.HistoryManager : Object {
    public unowned ViewCanvas view_canvas { get; construct; }

    public class Snapshot {
        public Snapshot (string description, Lib.Items.Model model) {
            this.description = description;
            this.model = model;
        }

        public string description;
        public Lib.Items.Model model;
    }

    private Gee.LinkedList<Snapshot> undo_stack;
    private Gee.LinkedList<Snapshot> redo_stack;


    public HistoryManager (ViewCanvas canvas) {
        Object (view_canvas : canvas);
        view_canvas.window.event_bus.create_model_snapshot.connect (snapshot);
        view_canvas.window.event_bus.undo.connect (undo);
        view_canvas.window.event_bus.redo.connect (redo);
    }

    construct {
        undo_stack = new Gee.LinkedList<Snapshot> ();
        redo_stack = new Gee.LinkedList<Snapshot> ();
    }

    private void snapshot (string description) {
        unowned var im = view_canvas.items_manager;
        var clone = new Lib.Items.Model.clone (im.item_model);
        undo_stack.add (new Snapshot (description, clone));

        redo_stack.clear ();
    }

    public void undo () {
        apply_snapshot (undo_stack, redo_stack);
    }

    public void redo () {
        apply_snapshot (redo_stack, undo_stack);
    }

    /*
     * Implementation for undo/redo. Shared since they are symmetric.
     */
    private void apply_snapshot (Gee.LinkedList<Snapshot> source, Gee.LinkedList<Snapshot> other) {
        if (source.size == 0) {
            return;
        }

        unowned var im = view_canvas.items_manager;
        view_canvas.selection_manager.reset_selection ();
        view_canvas.mode_manager.deregister_active_mode ();
        view_canvas.hover_manager.remove_hover_effect ();

        var last_stack = source.last ();
        source.remove (last_stack);
        other.add (new Snapshot (last_stack.description, new Lib.Items.Model.clone (im.item_model)));

        // replace model
        im.replace_model (last_stack.model);

        // Regenerate the layers list.
        view_canvas.window.main_window.regenerate_list ();
    }

}

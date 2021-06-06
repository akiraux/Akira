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
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.FillsItemTest : Akira.TestSuite {
    public FillsItemTest () {
        this.add_test ("loops_through_items", this.loop_through_items);
    }

    public override void setup () {}

    public override void teardown () {}

    // Unit test for Akira.Models.FillListModel.add () method.
    // Check whether quickly selecting and deselecting multiple items causes a segfault.
    public void loop_through_items () {
        /*
        app.activate.connect ((a) => {
            var window = new Akira.Window (app);
            app.add_window (window);
            var canvas = window.main_window.main_canvas.canvas;

            // TRUE: The canvas was properly generated.
            assert (canvas is Akira.Lib.Canvas);

            var list_model = window.main_window.left_sidebar.fills_panel.list_model;

            // Create 1000 Items and quickly select/deselect them to stress test the canvas.
            for (var i = 0; i < 10; i++) {
                window.items_manager.set_item_to_insert ("rectangle");
                var item = window.items_manager.insert_item (10, 10);

                // We don't need to set any other parameter or create other widgets like the layer
                // panel since we're only interested in testing the selection effect and the fill model.
                canvas.selected_bound_manager.add_item_to_selection (item as Akira.Lib.Items.CanvasItem);

                // TRUE: We selected the correct item.
                assert (canvas.selected_bound_manager.selected_items.index (item) == 0);
                assert ((item as Akira.Lib.Items.CanvasItem).selected == true);

                // TRUE: A fill model was created and listed.
                assert (list_model.get_n_items () == 1);

                canvas.selected_bound_manager.delete_selection ();

                // TRUE: The previous fill model was deleted.
                assert (list_model.get_n_items () == 0);

                // TRUE: We no item is selected.
                assert (canvas.selected_bound_manager.selected_items.length () == 0);
            }

            // Shut down the test.
            app.quit ();
        });

        app.run ();
        app = null;
        */
    }
}

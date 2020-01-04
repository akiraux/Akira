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
        app.activate.connect ((a) => {
            var window = new Akira.Window (app);
            app.add_window (window);
            var canvas = window.main_window.main_canvas.canvas;

            // TRUE: The canvas was properly generated.
            assert (canvas is Akira.Lib.Canvas);

            //  var root = canvas.get_root_item ();
            //  var fills_list_model = window.main_window.left_sidebar.fill_box_panel.fills_list_model;

            //  // Create 1000 Items and quickly select/deselect them to stress test the canvas.
            //  for (var i = 0; i < 1000; i++) {
            //      var item = new Goo.CanvasRect (null, 10, 10, 10, 10,
            //                                     "line-width", 1.0,
            //                                     "radius-x", 0.0,
            //                                     "radius-y", 0.0,
            //                                     "stroke-color", "#cccccc",
            //                                     "fill-color", "#f00", null);

            //      item.set ("parent", root);

            //      // We don't need to set any other parameter or create other widgets like the layer
            //      // panel since we're only interested in testing the selection effect and the fill model.
            //      canvas.init_item (item);
            //      canvas.selected_item = item;

            //      // TRUE: We selected the correct item.
            //      assert (canvas.selected_item == item);

            //      canvas.add_select_effect (item);

            //      // TRUE: A fill model was created and listed.
            //      assert (fills_list_model.get_n_items () == 1);

            //      canvas.delete_selected ();

            //      // TRUE: The previous fill model was deleted.
            //      assert (fills_list_model.get_n_items () == 0);

            //      // TRUE: We deselected the item.
            //      assert (canvas.selected_item == null);
            //  }

            // Shut down the test.
            app.quit ();
        });

        app.run ();
        app = null;
    }
}

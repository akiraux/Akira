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
        this.add_test ("loops_through_items", this.loops_through_items);
    }

    public override void setup () {}

    public override void teardown () {}

    // Unit test for Akira.Models.FillListModel.add () method.
    // Check whether quickly selecting and deselecting multiple items causes a segfault.
    public void loops_through_items () {
        //  var app = new Akira.Application ();
        app.activate.connect ((a) => {
            var window = new Akira.Window (app);
            app.add_window (window);
            var canvas = window.main_window.main_canvas.canvas;

            // TRUE: The canvas was properly generated.
            assert (canvas is Akira.Lib.Canvas);

            // Create Items
            var root = canvas.get_root_item ();
            var item = new Goo.CanvasRect (null, 10, 10, 10, 10,
                                        "line-width", 1.0,
                                        "radius-x", 0.0,
                                        "radius-y", 0.0,
                                        "stroke-color", "#cccccc",
                                        "fill-color", "#f00", null);

            item.set ("parent", root);
            item.set_transform (Cairo.Matrix.identity ());
            item.set_data<double?> ("rotation", 0);

            var artboard = window.main_window.right_sidebar.layers_panel.artboard;
            var layer = new Akira.Layouts.Partials.Layer (window, artboard, item,
                "Rectangle", "shape-rectangle-symbolic", false);
            item.set_data<Akira.Layouts.Partials.Layer?> ("layer", layer);
            artboard.container.add (layer);
            artboard.show_all ();

            //  canvas.selected_item = item;

            //  Timeout.add (3000, () => {
            //      app.quit();
            //      return false;
            //  });
            app.quit();
        });

        app.run ();
        app = null;
    }
}

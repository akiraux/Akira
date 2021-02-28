/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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

public class Akira.Lib.Managers.SnapManager : Object {
    private const string DEBUG_COLOR = "#444";
    private const string MATCH_COLOR = "#f00";
    private const double LINE_WIDTH = 1.0;
    private const double SENSITIVITY = 4.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }

    private Goo.CanvasItem root;
    //private Goo.CanvasRect? select_effect;
    //private Goo.CanvasItemSimple[] nobs = new Goo.CanvasItemSimple[9];
    //private Goo.CanvasBounds select_bb;

    // If the effect needs to be created or it's only a value update.
    private bool create { get; set; default = true; }

    public SnapManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();
    }

    public void generate_snap_grid (List<Items.CanvasItem> selection) {
        List<weak Goo.CanvasItem> vertical_candidates = null;
        List<weak Goo.CanvasItem> horizontal_candidates = null;

        Goo.CanvasBounds vertical_filter = {0, 0, 0, 0};
        Goo.CanvasBounds horizontal_filter = {0, 0, 0, 0};

        Gee.HashMap<int, List<int>>  vertical_snaps = null;
        Gee.HashMap<int, List<int>>  horizontal_snaps = null;

        foreach (var item in selection)
        {
          horizontal_filter.x1 = item.bounds.x1;
          horizontal_filter.x2 = item.bounds.x2;
          horizontal_filter.y1 = canvas.y1;
          horizontal_filter.y2 = canvas.y2;

          vertical_filter.x1 = canvas.x1;
          vertical_filter.x2 = canvas.x2;
          vertical_filter.y1 = item.bounds.y1;
          vertical_filter.y2 = item.bounds.y2;

          vertical_candidates.concat(canvas.get_items_in_area(vertical_filter, true, true, false));
          horizontal_candidates.concat(canvas.get_items_in_area(horizontal_filter, true, true, false));
        }

        foreach (var vfi in vertical_candidates) {
          var candidate_item = vfi as Items.CanvasItem;
          if (candidate_item != null && selection.find(candidate_item) == null) {

          }
        }

        foreach (var hfi in horizontal_candidates) {
          var candidate_item = hfi as Items.CanvasItem;
          if (candidate_item != null && selection.find(candidate_item) == null) {
            debug("   :(");
          }
        }
    }
}

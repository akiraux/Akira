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

    private Gee.HashMap<int, Gee.HashSet<int>> vertical_snaps;
    private Gee.HashMap<int, Gee.HashSet<int>> horizontal_snaps;

    // If the effect needs to be created or it's only a value update.
    private bool create { get; set; default = true; }

    public SnapManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        root = canvas.get_root_item ();
        vertical_snaps = new Gee.HashMap<int, Gee.HashSet<int>>();
        horizontal_snaps = new Gee.HashMap<int, Gee.HashSet<int>>();
    }

    public void generate_snap_grid (List<Items.CanvasItem> selection) {
        List<weak Goo.CanvasItem> vertical_candidates = null;
        List<weak Goo.CanvasItem> horizontal_candidates = null;

        Goo.CanvasBounds vertical_filter = {0, 0, 0, 0};
        Goo.CanvasBounds horizontal_filter = {0, 0, 0, 0};

        vertical_snaps.clear();
        horizontal_snaps.clear();

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
            populate_horizontal_snaps(candidate_item, ref vertical_snaps);
          }
        }

        debug("vs: %d",vertical_snaps.size);

        foreach (var hfi in horizontal_candidates) {
          var candidate_item = hfi as Items.CanvasItem;
          if (candidate_item != null && selection.find(candidate_item) == null) {
            populate_vertical_snaps(candidate_item, ref horizontal_snaps);
          }
        }
        debug("hs: %d",horizontal_snaps.size);
    }

    private void add_to_map(int pos, int n1, int n2, int n3, ref Gee.HashMap<int, Gee.HashSet<int>> map)
    {
        if (map.has_key(pos)) {
            var k = map.get(pos);
            k.add(n1);
            k.add(n2);
            k.add(n3);
        }
        else {
            var v = new Gee.HashSet<int>();
            v.add(n1);
            v.add(n2);
            v.add(n3);
            map.set(pos, v);
        }
    }

    private void populate_horizontal_snaps(Items.CanvasItem item, ref Gee.HashMap<int, Gee.HashSet<int>> map)
    {
        int x_1 = (int)item.bounds.x1;
        int x_2 = (int)item.bounds.x1;
        int y_1 = (int)item.bounds.x1;
        int y_2 = (int)item.bounds.x1;
        int center_x = (int)((item.bounds.x2 - item.bounds.x1) / 2.0 + item.bounds.x1);
        int center_y = (int)((item.bounds.y2 - item.bounds.y1) / 2.0 + item.bounds.y1);

        add_to_map(x_1, y_1, y_2, center_y, ref map);
        add_to_map(x_2, y_1, y_2, center_y, ref map);
        add_to_map(center_x, center_y, center_y, center_y, ref map);
    }

    private void populate_vertical_snaps(Items.CanvasItem item, ref Gee.HashMap<int, Gee.HashSet<int>> map)
    {
        int x_1 = (int)item.bounds.x1;
        int x_2 = (int)item.bounds.x1;
        int y_1 = (int)item.bounds.x1;
        int y_2 = (int)item.bounds.x1;
        int center_x = (int)((item.bounds.x2 - item.bounds.x1) / 2.0 + item.bounds.x1);
        int center_y = (int)((item.bounds.y2 - item.bounds.y1) / 2.0 + item.bounds.y1);

        add_to_map(y_1, x_1, x_2, center_x, ref map);
        add_to_map(y_2, x_1, x_2, center_x, ref map);
        add_to_map(center_y, center_x, center_x, center_x, ref map);
    }
}

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
    private const string STROKE_COLOR = "#ff0000";
    private const double LINE_WIDTH = 1.0;
    private const double DOT_RADIUS = 3.0;
    private const double SENSITIVITY = 5.0;

    public weak Akira.Lib.Canvas canvas { get; construct; }


    // Canvas items
    private Goo.CanvasItem root;
    private Gee.ArrayList<Goo.CanvasItemSimple> vertical_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> horizontal_decorator_lines;
    private Gee.ArrayList<Goo.CanvasItemSimple> decorator_dots;


    // Snap grid data
    public struct SnapMeta {
        public Gee.HashSet<int> normals;
        public int polarity;
    }

    public Gee.HashMap<int, SnapMeta?> vertical_snaps;
    public Gee.HashMap<int, SnapMeta?> horizontal_snaps;

    // snap match data
    public enum MatchType {
        NONE=-1,
        FUZZY,
        EXACT,
    }
    public struct SnapMatch {
        public bool wants_snap() {
            return type != MatchType.NONE;
        }

        public int snap_offset() {
            if (wants_snap()) {
                return snap_position + polarity_offset - reference_position;
            }
            return 0;
        }

        public MatchType type;
        public int snap_position;
        public int polarity_offset;
        public int reference_position;
        public Gee.HashMap<int, int> exact_matches;
    }

    public struct SnapMatchData {
        public bool wants_snap() {
            return horizontal.wants_snap() || vertical.wants_snap();
        }

        SnapMatch horizontal;
        SnapMatch vertical;
    }

    // matchdata
    public SnapMatchData snap_match_data;

    // If the effect needs to be created or it's only a value update.
    private bool create { get; set; default = true; }

    public SnapManager (Akira.Lib.Canvas canvas) {
        Object (
            canvas: canvas
        );
    }

    construct {
        vertical_snaps = new Gee.HashMap<int, SnapMeta>();
        horizontal_snaps = new Gee.HashMap<int, SnapMeta>();

        snap_match_data.horizontal.type = MatchType.NONE;
        snap_match_data.horizontal.reference_position = 0;
        snap_match_data.horizontal.snap_position = 0;
        snap_match_data.horizontal.polarity_offset = 0;
        snap_match_data.horizontal.exact_matches = new Gee.HashMap<int, int>();

        snap_match_data.vertical.type = MatchType.NONE;
        snap_match_data.vertical.reference_position = 0;
        snap_match_data.vertical.snap_position = 0;
        snap_match_data.vertical.polarity_offset = 0;
        snap_match_data.vertical.exact_matches = new Gee.HashMap<int, int>();

        vertical_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        horizontal_decorator_lines = new Gee.ArrayList<Goo.CanvasItemSimple> ();
        decorator_dots = new Gee.ArrayList<Goo.CanvasItemSimple> ();
    }

    public void reset()
    {
        vertical_snaps.clear();
        horizontal_snaps.clear();
        reset_matches();
        reset_decorators();
    }

    public void reset_matches()
    {
        snap_match_data.horizontal.type = MatchType.NONE;
        snap_match_data.horizontal.reference_position = 0;
        snap_match_data.horizontal.snap_position = 0;
        snap_match_data.horizontal.polarity_offset = 0;
        snap_match_data.horizontal.exact_matches.clear();

        snap_match_data.vertical.type = MatchType.NONE;
        snap_match_data.vertical.reference_position = 0;
        snap_match_data.vertical.snap_position = 0;
        snap_match_data.vertical.polarity_offset = 0;
        snap_match_data.vertical.exact_matches.clear();
    }

    public void reset_decorators()
    {
        foreach (var decorator in vertical_decorator_lines) {
            decorator.set("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        foreach (var decorator in horizontal_decorator_lines) {
            decorator.set("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
        foreach (var decorator in decorator_dots) {
            decorator.set("visibility", Goo.CanvasItemVisibility.HIDDEN);
        }
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
          horizontal_filter.x1 = item.bounds.x1 - SENSITIVITY;
          horizontal_filter.x2 = item.bounds.x2 + SENSITIVITY;
          horizontal_filter.y1 = canvas.y1;
          horizontal_filter.y2 = canvas.y2;

          vertical_filter.x1 = canvas.x1;
          vertical_filter.x2 = canvas.x2;
          vertical_filter.y1 = item.bounds.y1 - SENSITIVITY;
          vertical_filter.y2 = item.bounds.y2 + SENSITIVITY;

          vertical_candidates.concat(canvas.get_items_in_area(vertical_filter, true, true, false));
          horizontal_candidates.concat(canvas.get_items_in_area(horizontal_filter, true, true, false));
        }

        foreach (var vfi in vertical_candidates) {
          var candidate_item = vfi as Items.CanvasItem;
          if (candidate_item != null && selection.find(candidate_item) == null) {
            populate_vertical_snaps(candidate_item, ref vertical_snaps);
          }
        }

        foreach (var hfi in horizontal_candidates) {
          var candidate_item = hfi as Items.CanvasItem;
          if (candidate_item != null && selection.find(candidate_item) == null) {
            populate_horizontal_snaps(candidate_item, ref horizontal_snaps);
          }
        }
    }

    public void generate_snap_matches(List<Items.CanvasItem> selection)
    {
        generate_snap_grid(selection);
        reset_matches();

        var v_sel_snaps = new Gee.HashMap<int, SnapMeta?>();
        var h_sel_snaps = new Gee.HashMap<int, SnapMeta?>();

        foreach (var item in selection)
        {
            populate_horizontal_snaps(item, ref h_sel_snaps);
            populate_vertical_snaps(item, ref v_sel_snaps);
        }

        int diff = (int) SENSITIVITY + 1;
        int tmpdiff = (int) SENSITIVITY + 1;
        int polarity_offset = 0;

        foreach (var sel_snap in v_sel_snaps) {
            foreach (var cand in vertical_snaps) {
                if ((sel_snap.value.polarity > 0) != (cand.value.polarity > 0)) {
                    polarity_offset = 0; //(sel_snap.value.polarity > 0) ? -1 : 1;

                }
                else {
                    polarity_offset= 0;
                }


                diff = (int)(cand.key - sel_snap.key);
                diff = diff.abs();

                if (diff < SENSITIVITY) {
                    if ((int)(cand.key + polarity_offset - sel_snap.key) == 0) {
                        snap_match_data.vertical.type = MatchType.EXACT;
                        snap_match_data.vertical.snap_position = sel_snap.key;
                        snap_match_data.vertical.reference_position = sel_snap.key;
                        snap_match_data.vertical.polarity_offset = polarity_offset;
                        snap_match_data.vertical.exact_matches[cand.key] = polarity_offset;
                        tmpdiff = diff;
                    }
                    else if (diff < tmpdiff) {
                        snap_match_data.vertical.type = MatchType.FUZZY;
                        snap_match_data.vertical.snap_position = cand.key;
                        snap_match_data.vertical.reference_position = sel_snap.key;
                        snap_match_data.vertical.polarity_offset = polarity_offset;
                        tmpdiff = diff;
                    }
                }
            }
        }

        tmpdiff = (int) SENSITIVITY + 1;
        foreach (var sel_snap in h_sel_snaps) {
            foreach (var cand in horizontal_snaps) {
                if ((sel_snap.value.polarity > 0) != (cand.value.polarity > 0)) {
                    polarity_offset = 0; //(sel_snap.value.polarity > 0) ? -1 : 1;

                }
                else {
                    polarity_offset= 0;
                }

                diff = (int)(cand.key - sel_snap.key);
                diff = diff.abs();

                if (diff < SENSITIVITY) {
                    if ((int)(cand.key + polarity_offset - sel_snap.key) == 0) {
                        snap_match_data.horizontal.type = MatchType.EXACT;
                        snap_match_data.horizontal.snap_position = cand.key;
                        snap_match_data.horizontal.reference_position = sel_snap.key;
                        snap_match_data.horizontal.polarity_offset = polarity_offset;
                        snap_match_data.horizontal.exact_matches[cand.key] = polarity_offset;
                        tmpdiff = diff;
                    }
                    else if (diff < tmpdiff) {
                        snap_match_data.horizontal.type = MatchType.FUZZY;
                        snap_match_data.horizontal.snap_position = cand.key;
                        snap_match_data.horizontal.reference_position = sel_snap.key;
                        snap_match_data.horizontal.polarity_offset = polarity_offset;
                        tmpdiff = diff;
                    }
                }
                tmpdiff = diff;
            }
        }
    }

    public void populate_decorators()
    {
        if (root == null) {
            root = canvas.get_root_item ();
        }

        reset_decorators();

       if (snap_match_data.vertical.wants_snap()) {
            foreach (var snap_position in snap_match_data.vertical.exact_matches) {
                add_vertical_decorator_line(snap_position.key, snap_position.value);
            }
       }

       if (snap_match_data.horizontal.wants_snap()) {
            foreach (var snap_position in snap_match_data.horizontal.exact_matches) {
                add_horizontal_decorator_line(snap_position.key, snap_position.value);
            }
       }

    }

    private void add_to_map(int pos, int n1, int n2, int n3, int polarity, ref Gee.HashMap<int, SnapMeta?> map)
    {
        if (map.has_key(pos)) {
            SnapMeta? k = map.get(pos);
            k.normals.add(n1);
            k.normals.add(n2);
            k.normals.add(n3);
            // #TOFIX - this isn't accumulating
            k.polarity += polarity;
        }
        else {
            var v = SnapMeta();
            v.normals = new Gee.HashSet<int>();
            v.normals.add(n1);
            v.normals.add(n2);
            v.normals.add(n3);
            v.polarity = polarity;
            map.set(pos, v);
        }
    }

    private void populate_horizontal_snaps(Items.CanvasItem item, ref Gee.HashMap<int, SnapMeta?> map)
    {
        int x_1 = (int)item.bounds.x1;
        int x_2 = (int)item.bounds.x2;
        int y_1 = (int)item.bounds.y1;
        int y_2 = (int)item.bounds.y2;
        int center_x = (int)((item.bounds.x2 - item.bounds.x1) / 2.0 + item.bounds.x1);
        int center_y = (int)((item.bounds.y2 - item.bounds.y1) / 2.0 + item.bounds.y1);

        add_to_map(x_1, y_1, y_2, center_y, -1, ref map);
        add_to_map(x_2, y_1, y_2, center_y, 1, ref map);
        add_to_map(center_x, center_y, center_y, center_y, 0, ref map);
    }

    private void populate_vertical_snaps(Items.CanvasItem item, ref Gee.HashMap<int, SnapMeta?> map)
    {
        int x_1 = (int)item.bounds.x1;
        int x_2 = (int)item.bounds.x2;
        int y_1 = (int)item.bounds.y1;
        int y_2 = (int)item.bounds.y2;
        int center_x = (int)((item.bounds.x2 - item.bounds.x1) / 2.0 + item.bounds.x1);
        int center_y = (int)((item.bounds.y2 - item.bounds.y1) / 2.0 + item.bounds.y1);

        add_to_map(y_1, x_1, x_2, center_x, -1,  ref map);
        add_to_map(y_2, x_1, x_2, center_x, 1, ref map);
        add_to_map(center_y, center_x, center_x, center_x, 0, ref map);
    }

    private void add_vertical_decorator_line(int pos, int polarity_offset) {
        var snap_value = vertical_snaps.get(pos);
        if (snap_value != null) {

            // add dots
            foreach (var normal in snap_value.normals) {
                add_decorator_dot(normal, pos + polarity_offset);
            }

            // add lines (reuse if possible
            foreach (var line in vertical_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set("y", (double)pos + polarity_offset);
                    line.set("line-width", LINE_WIDTH / canvas.current_scale);
                    line.raise(null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line(
                null,
                canvas.x1, pos + polarity_offset,
                canvas.x2, pos + polarity_offset,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set("parent", root);
            tmp.raise(null);
            vertical_decorator_lines.add(tmp);
        }
    }

    private void add_horizontal_decorator_line(int pos, int polarity_offset) {
        var snap_value = horizontal_snaps.get(pos);
        if (snap_value != null) {

            // add dots
            foreach (var normal in snap_value.normals) {
                add_decorator_dot(pos + polarity_offset, normal);
            }

            // add lines (reuse if possible
            foreach (var line in horizontal_decorator_lines) {
                if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                    line.set("visibility", Goo.CanvasItemVisibility.VISIBLE);
                    line.set("x", (double)pos + polarity_offset);
                    line.set("line-width", LINE_WIDTH / canvas.current_scale);
                    line.raise(null);
                    return;
                }
            }

            var tmp = new Goo.CanvasPolyline.line(
                null,
                pos + polarity_offset, canvas.y1,
                pos + polarity_offset, canvas.y2,
                "line-width", LINE_WIDTH / canvas.current_scale,
                "stroke-color", STROKE_COLOR,
                null
            );

            tmp.can_focus = false;
            tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

            tmp.set("parent", root);
            tmp.raise(null);
            horizontal_decorator_lines.add(tmp);
        }
    }

    private void add_decorator_dot(int x, int y) {
        // add dot
        foreach (var line in decorator_dots) {
            if (line.visibility == Goo.CanvasItemVisibility.HIDDEN) {
                line.set("visibility", Goo.CanvasItemVisibility.VISIBLE);
                line.set("center_x", (double)x);
                line.set("center_y", (double)y);
                line.set("radius_x", DOT_RADIUS / canvas.current_scale);
                line.set("radius_y", DOT_RADIUS / canvas.current_scale);
                line.raise(null);
                return;
            }
        }

        var tmp = new Goo.CanvasEllipse(
            null,
            x, y,
            DOT_RADIUS / canvas.current_scale, DOT_RADIUS / canvas.current_scale,
            "line-width", 0.0,
            "fill-color", STROKE_COLOR,
            null
        );

        tmp.can_focus = false;
        tmp.pointer_events = Goo.CanvasPointerEvents.NONE;

        tmp.set("parent", root);
        tmp.raise(null);
        decorator_dots.add(tmp);
    }

}

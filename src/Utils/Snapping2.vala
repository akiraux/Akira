/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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

/**
 * Utility providing snap functionality between objects.
 * For Lib2
 */
public class Akira.Utils.Snapping2 : Object {
    /*
     * Returns a sensitivity adjusted to the given canvas scale.
     */
    public static int adjusted_sensitivity (double canvas_scale) {
        // Limit the sensitivity. This seems like a sensible default for now.
        if (canvas_scale > settings.snaps_sensitivity) {
            return 1;
        }

        // Beyond 0.002, the snapping breaks down. Arguably, it does before.
        return (int) (settings.snaps_sensitivity / double.max (0.002, canvas_scale));
    }

    /*
     * Generates the best snap grid from selection.
     */
    public static Utils.Snapping.SnapGrid generate_best_snap_grid (
        Lib2.ViewCanvas canvas,
        Lib2.Items.ItemSelection selection,
        Goo.CanvasBounds selection_area,
        int sensitivity
    ) {

        selection_area.x1 -= sensitivity;
        selection_area.x2 += sensitivity;
        selection_area.y1 -= sensitivity;
        selection_area.y2 += sensitivity;

        //Lib2.Items.CanvasArtboard artboard = null;
        bool all_in_same_artboard = false;

        /*
        foreach (var sel in selection) {
            if (artboard != null && artboard != sel.artboard) {
                all_in_same_artboard = false;
                break;
            }

            artboard = sel.artboard;
            all_in_same_artboard = artboard != null;
        }

        if (artboard != null && all_in_same_artboard) {
            return snap_grid_from_artboard (canvas, artboard, selection, sensitivity);
        }
        */

        return snap_grid_from_canvas (canvas, selection, selection_area, sensitivity);
    }

    /*
     * Generates a snap grid from a canvas.
     */
    public static Utils.Snapping.SnapGrid snap_grid_from_canvas (
        Lib2.ViewCanvas canvas,
        Lib2.Items.ItemSelection selection,
        Goo.CanvasBounds selection_area,
        int sensitivity
    ) {
        var grid = Utils.Snapping.SnapGrid ();
        grid.v_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();
        grid.h_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();

        double cand_top = 0;
        double cand_left = 0;
        double cand_bottom = 0;
        double cand_right = 0;
        double cand_center_x = 0;
        double cand_center_y = 0;

        double vis_x1 = 0;
        double vis_x2 = 0;
        double vis_y1 = 0;
        double vis_y2 = 0;
        canvas.visible_bounds (ref vis_y1, ref vis_x1, ref vis_y2, ref vis_x2);

        var candidate_list = canvas.items_manager.children_in_group(Lib2.Items.Model.origin_id);
        for (var i = 0; i < candidate_list.length; ++i) {
            var item = candidate_list.index(i).instance.item;

            if (item == null || selection.has_item_id (item.id)) {
                continue;
            }

            item.compiled_geometry ().bounding_box (
                out cand_top,
                out cand_left,
                out cand_bottom,
                out cand_right,
                out cand_center_x,
                out cand_center_y
            );

            if ((cand_right < vis_x1 || cand_left > vis_x2) ||
                (cand_bottom < vis_y1 || cand_top > vis_y2)) {
                // the candidate is not in view
                continue;
            }

            if (!(cand_right < selection_area.x1 || cand_left > selection_area.x2)) {
                populate_horizontal_snaps (
                    cand_top,
                    cand_left,
                    cand_bottom,
                    cand_right,
                    cand_center_x,
                    cand_center_y,
                    ref grid.h_snaps
                );
            }

            if (!(cand_bottom < selection_area.y1 || cand_top > selection_area.y2)) {
                populate_vertical_snaps (
                    cand_top,
                    cand_left,
                    cand_bottom,
                    cand_right,
                    cand_center_x,
                    cand_center_y,
                    ref grid.v_snaps
                );
            }
        }

        return grid;
    }

    /**
     * Calculate snaps inside a grid that match the selection input.
     */
    public static Utils.Snapping.SnapMatchData generate_snap_matches (
        Utils.Snapping.SnapGrid grid,
        Lib2.Items.ItemSelection selection,
        Goo.CanvasBounds selection_area,
        int sensitivity
    ) {
        var matches = Utils.Snapping.default_match_data ();

        var v_sel_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();
        var h_sel_snaps = new Gee.HashMap<int, Utils.Snapping.SnapMeta> ();

        double left = selection_area.x1;
        double right = selection_area.x2;
        double top = selection_area.y1;
        double bottom = selection_area.y2;
        double center_x = (left + right) / 2.0;
        double center_y = (top + bottom) / 2.0;

        populate_vertical_snaps (top, left, bottom, right, center_x, center_y, ref v_sel_snaps);
        populate_horizontal_snaps (top, left, bottom, right, center_x, center_y, ref h_sel_snaps);

        populate_snap_matches_from_list (v_sel_snaps, grid.v_snaps, ref matches.v_data, sensitivity);
        populate_snap_matches_from_list (h_sel_snaps, grid.h_snaps, ref matches.h_data, sensitivity);

        return matches;
    }


    /*
     * Populates the horizontal snaps of an item.
     */
    private static void populate_horizontal_snaps (
        double top,
        double left,
        double bottom,
        double right,
        double center_x,
        double center_y,
        ref Gee.HashMap<int, Utils.Snapping.SnapMeta> map
    ) {
        int x_1 = (int) Math.round (left);
        int x_2 = (int) Math.round (right);
        int y_1 = (int) Math.round (top);
        int y_2 = (int) Math.round (bottom);
        int cx = snap_ceil (center_x);
        int cy = snap_ceil (center_y);

        add_to_map (x_1, y_1, y_2, cy, -1, ref map);
        add_to_map (x_2, y_1, y_2, cy, 1, ref map);
        add_to_map (cx, cy, cy, cy, 0, ref map);
    }

    /*
     * Populates the vertical snaps of an item.
     */
    private static void populate_vertical_snaps (
        double top,
        double left,
        double bottom,
        double right,
        double center_x,
        double center_y,
        ref Gee.HashMap<int, Utils.Snapping.SnapMeta> map
    ) {
        int x_1 = (int) Math.round (left);
        int x_2 = (int) Math.round (right);
        int y_1 = (int) Math.round (top);
        int y_2 = (int) Math.round (bottom);
        int cx = snap_ceil (center_x);
        int cy = snap_ceil (center_y);

        add_to_map (y_1, x_1, x_2, cx, -1, ref map);
        add_to_map (y_2, x_1, x_2, cx, 1, ref map);
        add_to_map (cy, cx, cx, cx, 0, ref map);
    }

    /*
     * Simple method to add information to a snap list.
     */
    private static void add_to_map (
        int pos,
        int n1,
        int n2,
        int n3,
        int polarity,
        ref Gee.HashMap<int, Utils.Snapping.SnapMeta> map
    ) {
        if (map.has_key (pos)) {
            Utils.Snapping.SnapMeta k = map.get (pos);
            k.normals.add (n1);
            k.normals.add (n2);
            k.normals.add (n3);
            k.polarity += polarity;
            return;
        }

        var v = new Utils.Snapping.SnapMeta ();
        v.normals = new Gee.HashSet<int> ();
        v.normals.add (n1);
        v.normals.add (n2);
        v.normals.add (n3);
        v.polarity = polarity;
        map.set (pos, v);
    }


    /*
     * Matches in one direction (vertical / horizontal).
     */
    private static void populate_snap_matches_from_list (
        Gee.HashMap<int, Utils.Snapping.SnapMeta> target_snap_list,
        Gee.HashMap<int, Utils.Snapping.SnapMeta> grid_snap_list,
        ref Utils.Snapping.SnapMatch matches,
        int sensitivity
    ) {
        var sorted_target_snaps = new Gee.TreeMap<int, Utils.Snapping.SnapMeta> ();
        var sorted_grid_snaps = new Gee.TreeMap<int, Utils.Snapping.SnapMeta> ();

        sorted_target_snaps.set_all (target_snap_list);
        sorted_grid_snaps.set_all (grid_snap_list);

        int diff = 0;
        int polarity_offset = 0;
        var tmpdiff = sensitivity;
        foreach (var target_snap in sorted_target_snaps) {
            foreach (var cand in sorted_grid_snaps) {
                polarity_offset = 0;
                diff = (int) (cand.key - target_snap.key);
                diff = diff.abs ();

               if (diff < sensitivity) {
                    if ((int) (cand.key + polarity_offset - target_snap.key) == 0) {
                        matches.type = Utils.Snapping.MatchType.EXACT;
                        matches.snap_position = cand.key;
                        matches.reference_position = target_snap.key;
                        matches.polarity_offset = polarity_offset;
                        matches.exact_matches[cand.key] = polarity_offset;
                    } else if (diff < tmpdiff) {
                        matches.type = Utils.Snapping.MatchType.FUZZY;
                        matches.snap_position = cand.key;
                        matches.reference_position = target_snap.key;
                        matches.polarity_offset = polarity_offset;
                    }
                }

                tmpdiff = diff;
            }
        }
    }

    /*
     * finds the ceiling, making sure small epsilons don't cause instability
     */
    private static int snap_ceil (double val) {
        int res = (int) val;
        if ((val - res) > 0.001) {
            res += 1;
        }
        return res;
    }
}

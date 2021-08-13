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
    /**
     * Metadata used in the cosmetic aspects of snap lines and dots.
     */
    public class SnapMeta2 {
        public int[] normals;
        public int polarity;
    }

    /**
     * Grid snaps found for a given selection and set of candidates.
     */
    public struct SnapGrid2 {
        public bool is_empty () {
            return (v_snaps.size == 0 && h_snaps.size == 0);
        }

        public Gee.TreeMap<int, SnapMeta2> v_snaps;
        public Gee.TreeMap<int, SnapMeta2> h_snaps;
    }

    /**
     * Type of match that was found for a snap.
     */
    public enum MatchType2 {
        NONE = -1,  //< No match was found.
        FUZZY,      //< A match was found, but requires an offset.
        EXACT,      //< An exact match was found, no offset is necessary.
    }

    /**
     * Information used to define a match for a given selection.
     * An instance of this class corresponds to a single direction (vertical or horizontal).
     */
    public struct SnapMatch2 {
        /**
         * Returns true if a match was found
         */
        public bool snap_found () {
            return type != MatchType2.NONE;
        }

        /**
         * Returns the offset necessary to bring the reference position to the selected items.
         */
        public int snap_offset () {
            if (snap_found ()) {
                return snap_position - reference_position;
            }
            return 0;
        }

        public MatchType2 type;
        public int snap_position; //< Position of matched snap.
        public int reference_position; //< Position relative to the selection used as a reference.
        public Gee.Set<int> exact_matches; //< map of exact matches.
    }

    /**
     * Couple of MatchData used for convenience.
     */
    public struct SnapMatchData2 {
        public bool snap_found () {
            return h_data.snap_found () || v_data.snap_found ();
        }

        SnapMatch2 h_data;
        SnapMatch2 v_data;
    }

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
    public static SnapGrid2 generate_best_snap_grid (
        Lib2.ViewCanvas canvas,
        Lib2.Items.NodeSelection selection,
        Geometry.Rectangle selection_area,
        int sensitivity
    ) {
        selection_area.left -= sensitivity;
        selection_area.right += sensitivity;
        selection_area.top -= sensitivity;
        selection_area.bottom += sensitivity;

        int group_id;
        selection.spans_one_group (out group_id);
        group_id = int.max (group_id, Lib2.Items.Model.ORIGIN_ID);

        return snap_grid_from_canvas (canvas, group_id, selection, selection_area, sensitivity);
    }

    /*
     * Generates a snap grid from a canvas.
     * If group_node is passed, then it will be used to generate snaps only within that group.
     */
    public static SnapGrid2 snap_grid_from_canvas (
        Lib2.ViewCanvas canvas,
        int group_id,
        Lib2.Items.NodeSelection selection,
        Geometry.Rectangle selection_area,
        int sensitivity
    ) {
        var grid = SnapGrid2 ();
        grid.v_snaps = new Gee.TreeMap<int, SnapMeta2> ();
        grid.h_snaps = new Gee.TreeMap<int, SnapMeta2> ();

        double vis_x1 = 0;
        double vis_x2 = 0;
        double vis_y1 = 0;
        double vis_y2 = 0;
        canvas.visible_bounds (ref vis_y1, ref vis_x1, ref vis_y2, ref vis_x2);

        var candidate_list = canvas.items_manager.children_in_group (group_id);
        int v_added = 0;
        int h_added = 0;

        foreach (unowned var node in candidate_list.data) {
            if (selection.has_id (node.id, false)) {
                continue;
            }

            unowned var inst = node.instance;
            if ((inst.bounding_box.right < vis_x1 || inst.bounding_box.left > vis_x2) ||
                (inst.bounding_box.bottom < vis_y1 || inst.bounding_box.top > vis_y2)) {
                // the candidate is not in view
                continue;
            }

            if (!(inst.bounding_box.right < selection_area.left || inst.bounding_box.left > selection_area.right)) {
                populate_horizontal_snaps (inst.bounding_box, ref grid.h_snaps);
                h_added++;
            }

            if (!(inst.bounding_box.bottom < selection_area.top || inst.bounding_box.top > selection_area.bottom)) {
                populate_vertical_snaps (inst.bounding_box, ref grid.v_snaps);
                v_added++;
            }
        }

        return grid;
    }

    /*
     * Calculate snaps inside a grid that match the selection input.
     */
    public static SnapMatchData2 generate_snap_matches (
        SnapGrid2 grid,
        Lib2.Items.NodeSelection selection,
        Geometry.Rectangle selection_area,
        int sensitivity
    ) {
        var matches = Utils.Snapping2.default_match_data ();

        var v_sel_snaps = new Gee.TreeMap<int, SnapMeta2> ();
        var h_sel_snaps = new Gee.TreeMap<int, SnapMeta2> ();

        populate_vertical_snaps (selection_area, ref v_sel_snaps);
        populate_horizontal_snaps (selection_area, ref h_sel_snaps);

        populate_snap_matches_from_list (v_sel_snaps, grid.v_snaps, ref matches.v_data, sensitivity);
        populate_snap_matches_from_list (h_sel_snaps, grid.h_snaps, ref matches.h_data, sensitivity);

        return matches;
    }


    /*
     * Populates the horizontal snaps of an item.
     */
    private static void populate_horizontal_snaps (
        Geometry.Rectangle rect,
        ref Gee.TreeMap<int, SnapMeta2> s_map
    ) {
        int x_1 = (int) Math.round (rect.left);
        int x_2 = (int) Math.round (rect.right);
        int y_1 = (int) Math.round (rect.top);
        int y_2 = (int) Math.round (rect.bottom);
        int cx = snap_ceil (rect.center_x);
        int cy = snap_ceil (rect.center_y);

        add_to_map (x_1, y_1, y_2, cy, -1, ref s_map);
        add_to_map (x_2, y_1, y_2, cy, 1, ref s_map);
        add_to_map (cx, cy, cy, cy, 0, ref s_map);
    }

    /*
     * Populates the vertical snaps of an item.
     */
    private static void populate_vertical_snaps (
        Geometry.Rectangle rect,
        ref Gee.TreeMap<int, SnapMeta2> s_map
    ) {
        int x_1 = (int) Math.round (rect.left);
        int x_2 = (int) Math.round (rect.right);
        int y_1 = (int) Math.round (rect.top);
        int y_2 = (int) Math.round (rect.bottom);
        int cx = snap_ceil (rect.center_x);
        int cy = snap_ceil (rect.center_y);

        add_to_map (y_1, x_1, x_2, cx, -1, ref s_map);
        add_to_map (y_2, x_1, x_2, cx, 1, ref s_map);
        add_to_map (cy, cx, cx, cx, 0, ref s_map);
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
        ref Gee.TreeMap<int, SnapMeta2> s_map
    ) {
        if (s_map.has_key (pos)) {
            var k = s_map[pos];
            Utils.Array.append_to_iarray (ref k.normals, n1);
            Utils.Array.append_to_iarray (ref k.normals, n2);
            Utils.Array.append_to_iarray (ref k.normals, n3);
            k.polarity += polarity;
            return;
        }

        var k = new SnapMeta2 ();
        k.normals = new int[0];
        Utils.Array.append_to_iarray (ref k.normals, n1);
        Utils.Array.append_to_iarray (ref k.normals, n2);
        Utils.Array.append_to_iarray (ref k.normals, n3);
        s_map.set (pos, k);
    }


    /*
     * Matches in one direction (vertical / horizontal).
     */
    private static void populate_snap_matches_from_list (
        Gee.TreeMap<int, SnapMeta2> target_snap_list,
        Gee.TreeMap<int, SnapMeta2> grid_snap_list,
        ref SnapMatch2 matches,
        int sensitivity
    ) {
        int diff = 0;
        var tmpdiff = sensitivity;
        foreach (var target_snap in target_snap_list.keys) {
            foreach (var cand in grid_snap_list.keys) {
                diff = (int) (cand - target_snap);
                diff = diff.abs ();

               if (diff < sensitivity) {
                    if ((int) (cand - target_snap) == 0) {
                        matches.type = MatchType2.EXACT;
                        matches.snap_position = cand;
                        matches.reference_position = target_snap;
                        matches.exact_matches.add (cand);
                        tmpdiff = 0;
                    } else if (diff < tmpdiff) {
                        matches.type = MatchType2.FUZZY;
                        matches.snap_position = cand;
                        matches.reference_position = target_snap;
                        tmpdiff = diff;
                    }
                }
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

    /**
     * Generate a default match data.
     */
    public static SnapMatchData2 default_match_data () {
        var matches = SnapMatchData2 ();
        matches.v_data.type = MatchType2.NONE;
        matches.v_data.snap_position = 0;
        matches.v_data.reference_position = 0;
        matches.v_data.exact_matches = new Gee.TreeSet<int> ();

        matches.h_data.type = MatchType2.NONE;
        matches.h_data.snap_position = 0;
        matches.h_data.reference_position = 0;
        matches.h_data.exact_matches = new Gee.TreeSet<int> ();

        return matches;
    }
}

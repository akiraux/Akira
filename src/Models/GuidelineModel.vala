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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

public class Akira.Models.GuidelineModel {
    // Stores the coordinates of horizontal guides.
    // Since a guideline is a straight line (either horizontal or vertical),
    // we only need one coordinate to store a line.
    public Utils.SortedArray h_guides;
    // Stores the coordinates of vertical guides.
    public Utils.SortedArray v_guides;

    // Stores index of line in the sorted array.
    public int highlight_guide;
    public Lib.Managers.GuideManager.Direction highlight_direction;
    // Stores the coordinate of currently highlighted guideline.
    public double highlight_position;

    // The distances between guidelines will be displayed near the current cursor position.
    public Geometry.Point cursor_position;
    // This string will contain the distances either from the nearest guidelines or another item.
    // This string will be draw as is on the canvas.
    public string distances;

    // Stores the extents of the artboard.
    // The guidelines will only be drawn inside this region.
    public Geometry.Rectangle drawable_extents;

    public GuidelineModel () {
        h_guides = new Utils.SortedArray ();
        v_guides = new Utils.SortedArray ();
    }

    public GuidelineModel copy () {
        var clone = new GuidelineModel ();

        clone.h_guides = h_guides.clone ();
        clone.v_guides = v_guides.clone ();

        clone.highlight_guide = highlight_guide;
        clone.highlight_direction = highlight_direction;
        clone.highlight_position = highlight_position;

        clone.drawable_extents = drawable_extents;
        clone.cursor_position = cursor_position;
        clone.distances = distances;

        return clone;
    }

    public void add_h_guide (double pos) {
        h_guides.insert (pos);
    }

    public void add_v_guide (double pos) {
        v_guides.insert (pos);
    }

    public void set_highlighted_guide (int guide, Lib.Managers.GuideManager.Direction direction) {
        highlight_guide = guide;
        highlight_direction = direction;

        if (direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            highlight_position = h_guides.elements[guide];
        } else if (direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            highlight_position = v_guides.elements[guide];
        }
    }

    public void set_drawable_extents (Geometry.Rectangle extents) {
        drawable_extents = extents;

        // We also need to add the edges of the artboard.
        // These lines make it easier to measure distances.
        int index;
        if (h_guides.contains (extents.left, out index) || h_guides.contains (extents.right, out index)) {
            return;
        } else if (v_guides.contains (extents.top, out index) || v_guides.contains (extents.bottom, out index)) {
            return;
        }

        v_guides.insert (extents.left);
        v_guides.insert (extents.right);
        h_guides.insert (extents.top);
        h_guides.insert (extents.bottom);
    }

    public bool does_guide_exist_at (
        Geometry.Point point,
        out int sel_line,
        out Lib.Managers.GuideManager.Direction sel_direction
    ) {
        double thresh = 1;

        // We are skipping the first and last lines as those are fixed
        // and only used for calculating distances.
        for (int i = 1; i < h_guides.length - 1; ++i) {
            if ((h_guides.elements[i] - point.y).abs () < thresh) {
                sel_line = i;
                sel_direction = Lib.Managers.GuideManager.Direction.HORIZONTAL;
                return true;
            }
        }

        for (int i = 1; i < v_guides.length - 1; ++i) {
            if ((v_guides.elements[i] - point.x).abs () < thresh) {
                sel_line = i;
                sel_direction = Lib.Managers.GuideManager.Direction.VERTICAL;
                return true;
            }
        }

        sel_line = -1;
        sel_direction = Lib.Managers.GuideManager.Direction.NONE;

        return false;
    }

    public void move_guide_to_position (
        int position,
        Lib.Managers.GuideManager.Direction direction,
        Geometry.Point new_pos
    ) {
        if (direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            highlight_position = new_pos.y;
            highlight_direction = direction;
            highlight_guide = position;
        } else if (direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            highlight_position = new_pos.x;
            highlight_direction = direction;
            highlight_guide = position;
        }
    }

    public void remove_guide (Lib.Managers.GuideManager.Direction dir, int pos) {
        if (dir == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            h_guides.remove_at (pos);
        } else if (dir == Lib.Managers.GuideManager.Direction.VERTICAL) {
            v_guides.remove_at (pos);
        }
    }

    /*
     * This method will calculate the distances of selected guideline and its nearest neighbours.
     * It also calculates the position where this text is to be displayed on canvas.
     * The distances will always be drawn next to the cursor.
     */
    public void calculate_distance_positions (Geometry.Point cursor) {
        double distance_1 = 0;
        double distance_2 = 0;

        // Calculate the distance between the highlighted guide and the neareast neighbour on either sides.
        if (highlight_direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            distance_1 = highlight_position - h_guides.elements[highlight_guide - 1];
            distance_2 = h_guides.elements[highlight_guide] - highlight_position;
        } else if (highlight_direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            distance_1 = highlight_position - v_guides.elements[highlight_guide - 1];
            distance_2 = v_guides.elements[highlight_guide] - highlight_position;
        }

        cursor_position = cursor;
        distances = """%.3f, %.3f""".printf (distance_1, distance_2);
    }
 }

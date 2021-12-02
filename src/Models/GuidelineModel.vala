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
    // In case we are moving the guide, stores index of next guideline.
    public int highlight_guide;
    public Lib.Managers.GuideManager.Direction highlight_direction;
    // Stores the coordinate of currently highlighted guideline.
    public double highlight_position;

    // The distances between guidelines will be displayed near the current cursor position.
    public Geometry.Point cursor_position;
    // This array stores the distances from all four sides.
    // Can be distances from neighbouring guidelines or other canvas items.
    // Stored as { LEFT, RIGHT, TOP, BOTTOM }
    public double[] distances;

    // Stores the extents of the artboard.
    // The guidelines will only be drawn inside this region.
    public Geometry.Rectangle drawable_extents;

    public signal void changed ();

    public GuidelineModel () {
        h_guides = new Utils.SortedArray (0, 0);
        v_guides = new Utils.SortedArray (0, 0);

        drawable_extents = Geometry.Rectangle.empty ();
        distances = new double[4];
        distances[0] = distances[1] = distances[2] = distances[3] = -1;
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
        changed ();
    }

    public void add_v_guide (double pos) {
        v_guides.insert (pos);
        changed ();
    }

    public void set_highlighted_guide (int guide, Lib.Managers.GuideManager.Direction direction) {
        highlight_guide = guide;
        highlight_direction = direction;

        if (direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            highlight_position = h_guides.at(guide);
        } else if (direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            highlight_position = v_guides.at(guide);
        }

        changed ();
    }

    public void set_drawable_extents (Geometry.Rectangle extents) {
        // In case the artboard was moved without scaling.
        if (extents.width == drawable_extents.width && extents.height == drawable_extents.height) {
            double delta_x = 0;
            double delta_y = 0;

            delta_x = drawable_extents.left - extents.left;
            delta_y = drawable_extents.top - extents.top;

            drawable_extents = extents;

            h_guides.translate_all (delta_y);
            v_guides.translate_all (delta_x);
            changed ();

            return;
        }
        // Remove the guidelines at edges of previous extents if they exist.
        // Solves bug when artboard gets resized.
        h_guides.remove_item (drawable_extents.top);
        h_guides.remove_item (drawable_extents.bottom);
        v_guides.remove_item (drawable_extents.left);
        v_guides.remove_item (drawable_extents.right);

        drawable_extents = extents;

        // Then add the new edges of artboard.
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

        h_guides.set_bounds (extents.top, extents.bottom);
        v_guides.set_bounds (extents.left, extents.right);

        changed ();
    }

    public bool does_guide_exist_at (
        Geometry.Point point,
        out int sel_line,
        out Lib.Managers.GuideManager.Direction sel_direction
    ) {
        if (h_guides.contains (point.y, out sel_line)) {
            // The first and last guidelines are only for calculating distances.
            // They should not be moved.
            if (sel_line == 0 || sel_line == h_guides.length) {
                sel_line = -1;
                sel_direction = Lib.Managers.GuideManager.Direction.NONE;
                return false;
            } else {
                sel_direction = Lib.Managers.GuideManager.Direction.HORIZONTAL;
                return true;
            }
        }

        if (v_guides.contains (point.x, out sel_line)) {
            if (sel_line == 0 || sel_line == v_guides.length) {
                sel_line = -1;
                sel_direction = Lib.Managers.GuideManager.Direction.NONE;
                return false;
            } else {
                sel_direction = Lib.Managers.GuideManager.Direction.VERTICAL;
                return true;
            }
        }

        sel_line = -1;
        sel_direction = Lib.Managers.GuideManager.Direction.NONE;
        changed ();

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
            changed ();
        } else if (direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            highlight_position = new_pos.x;
            highlight_direction = direction;
            highlight_guide = position;
            changed ();
        }
    }

    public void remove_guide (Lib.Managers.GuideManager.Direction dir, int pos) {
        if (dir == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            h_guides.remove_at (pos);
            changed ();
        } else if (dir == Lib.Managers.GuideManager.Direction.VERTICAL) {
            v_guides.remove_at (pos);
            changed ();
        }
    }

    /*
     * This method will calculate the distances of selected guideline and its nearest neighbours.
     * It also calculates the position where this text is to be displayed on canvas.
     * The distances will always be drawn next to the cursor.
     */
    public void calculate_distance_positions (Geometry.Point cursor) {
        // Calculate the distance between the highlighted guide and the neareast neighbour on either sides.
        if (highlight_direction == Lib.Managers.GuideManager.Direction.HORIZONTAL) {
            h_guides.get_distance_to_neighbours (highlight_position, out distances[2], out distances[3]);
            distances[0] = distances[1] = -1;
        } else if (highlight_direction == Lib.Managers.GuideManager.Direction.VERTICAL) {
            v_guides.get_distance_to_neighbours (highlight_position, out distances[0], out distances[1]);
            distances[2] = distances[3] = -1;
        }

        cursor_position = cursor;
        changed ();
    }

    public void reset_distances () {
        distances[0] = distances[1] = distances[2] = distances[3] = -1;
        changed ();
    }
 }

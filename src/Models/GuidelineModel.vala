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

    public int highlight_guide;
    public Lib.Managers.GuideManager.Direction highlight_direction;
    public double highlight_position;

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

    public bool does_guide_exist_at (Geometry.Point point, out int sel_line, out Lib.Managers.GuideManager.Direction sel_direction) {
        double thresh = 1;

        for (int i = 0; i < h_guides.length; ++i) {
            if ((h_guides.elements[i] - point.y).abs () < thresh) {
                sel_line = i;
                sel_direction = Lib.Managers.GuideManager.Direction.HORIZONTAL;
                return true;
            }
        }

        for (int i = 0; i < v_guides.length; ++i) {
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

    public void move_guide_to_position (int position, Lib.Managers.GuideManager.Direction direction, Geometry.Point new_pos) {
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
 }

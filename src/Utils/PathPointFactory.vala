/*
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

/*
 * This class is responsible for creating new PathItems.
 * It will also add new points. When all the points have been added, only then
 * will the PathItem be appended to Components.Path
 */
public class Akira.Utils.PathPointFactory {
    public enum Command {
         LINE,
         CURVE
    }

    // Stores the recently created PathItem. Used for adding new points.
    private PathItem current_item;
    // Stores the index of point being added to current_item.
    private int item_point_index;
    // Check to see if no of points required by PathItem have been added.
    public bool all_points_added;

    public void create (Command item_type) {
        switch (item_type) {
            case Command.LINE:
                current_item = new PathLine ();
                break;
            case Command.CURVE:
                current_item = new PathCurve ();
                break;
            default:
                current_item = new PathItem ();
                break;
        }

        item_point_index = 0;
        all_points_added = false;
    }

    public void add_next_point (Geometry.Point point) {
        current_item.points[item_point_index] = point;
        ++item_point_index;

        if (item_point_index == current_item.points.length) {
            all_points_added = true;
        }
    }

    public PathItem get_path_item () {
        return current_item;
    }

    public bool are_all_points_added () {
        return all_points_added;
    }

    public void set_current_item (PathItem item) {
        current_item = item;
    }

    /*
     * Checks if last inserted point can be deleted from PathItem.
     * If yes, deletes it, otherwise returns false.
     * If this method returns true, we need to delete items from previous PathItem in Path
     */
    public bool delete_last_point () {
        if (item_point_index != 0) {
            --item_point_index;
            return false;
        }

        return true;
    }
}

public class Akira.Utils.PathItem {
    public PathPointFactory.Command command;
    public Geometry.Point[]? points;

    public PathItem copy () {
        var new_item = new PathItem ();
        new_item.command = command;
        new_item.points = points;
        return new_item;
    }
}

public class Akira.Utils.PathLine : PathItem {
    public PathLine () {
        command = PathPointFactory.Command.LINE;
        points = new Geometry.Point[1];
    }
}

public class Akira.Utils.PathCurve : PathItem {
    public PathCurve () {
        command = PathPointFactory.Command.CURVE;
        points = new Geometry.Point[3];
    }
}

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

public class Akira.Utils.PathPointFactory {
    public enum Command {
         MOVE,
         LINE,
         CURVE
    }

    public PathItem create (Command item_type) {
        switch (item_type) {
            case Command.MOVE:
                return new PathMove ();
            case Command.LINE:
                return new PathLine ();
            case Command.CURVE:
                return new PathCurve ();
            default:
                return new PathItem ();
        }
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

public class Akira.Utils.PathMove : PathItem {
    public PathMove () {
        command = PathPointFactory.Command.MOVE;
        points = new Geometry.Point[1];
    }

    public void add_point (Geometry.Point point) {
        points[0] = point;
    }
}

public class Akira.Utils.PathLine : PathItem {
    public PathLine () {
        command = PathPointFactory.Command.LINE;
        points = new Geometry.Point[1];
    }

    public void add_point (Geometry.Point point) {
        points[0] = point;
    }
}

public class Akira.Utils.PathCurve : PathItem {
    public PathCurve () {
        command = PathPointFactory.Command.CURVE;
        points = new Geometry.Point[3];
    }

    public void add_first_point (Geometry.Point point) {
        points[0] = point;
    }

    public void add_second_point (Geometry.Point point) {
        points[1] = point;
    }

    public void add_third_point (Geometry.Point point) {
        points[2] = point;
    }

}

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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

/*
 * Goo.CanvasItem wrapper that holds an id that can be used to associate with ModelItem.
 */
public interface Akira.Lib2.Items.CanvasItem : Goo.CanvasItemSimple, Goo.CanvasItem {
    public abstract int parent_id { get; set;}
}

public class Akira.Lib2.Items.CanvasRect : Goo.CanvasRect, CanvasItem {
     public int parent_id { get; set; default = -1; }

     public CanvasRect (Goo.CanvasItem parent, double x, double y, double width, double height) {
        this.parent = parent;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.radius_x = 0.0;
        this.radius_y = 0.0;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);
     }
}

public class Akira.Lib2.Items.CanvasEllipse : Goo.CanvasEllipse, CanvasItem {
    public int parent_id { get; set; default = -1; }

    public CanvasEllipse (Goo.CanvasItem parent, double center_x, double center_y, double radius_x, double radius_y) {
        this.parent = parent;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.radius_x = 0.0;
        this.radius_y = 0.0;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);
    }
}

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

public class Akira.Lib2.Items.CanvasArtboardLabel : Goo.CanvasText, CanvasItem {
    private const int FONT_SIZE = 10;
    public int parent_id { get; set; default = -1; }

    public CanvasArtboardLabel (Goo.CanvasItem parent, double center_x, double center_y) {
        // Define the label colors for dark/light theme variation.
        var light_color = Utils.Color.color_string_to_uint ("rgba(255, 255, 255, 0.75)");
        var dark_color = Utils.Color.color_string_to_uint ("rgba(0, 0, 0, 0.75)");
        this.parent = parent;
        this.x = x;
        this.y = y;
        this.width = 1.0;
        this.height = width;
        this.anchor = Goo.CanvasAnchorType.SW;
        set("font", "Open Sans " + (FONT_SIZE/* / akira_canvas.current_scale*/).to_string ());
        set("ellipsize", Pango.EllipsizeMode.END);
        set("fill-color-rgba", settings.dark_theme ? light_color : dark_color);

        can_focus = false;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);
    }
}

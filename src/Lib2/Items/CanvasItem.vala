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

public class Akira.Lib2.Items.CanvasRect : Goo.CanvasItemSimple , CanvasItem {
     public int parent_id { get; set; default = -1; }

     public double x { get; set; }
     public double y { get; set; }
     public double width { get; set; }
     public double height { get; set; }
     public double radius_x { get; set; }
     public double radius_y { get; set; }

     public CanvasRect (Goo.CanvasItem parent, double x, double y, double width, double height) {
        this.parent = parent;
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.radius_x = 0;
        this.radius_y = 0;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);
     }

     public override void simple_create_path (Cairo.Context cr) {
        if (radius_x > 0 || radius_y > 0) {
            /* The radii can't be more than half the size of the rect. */
            double rx = double.min (radius_x, width / 2);
            double ry = double.min (radius_y, height / 2);

            /* Draw the top-right arc. */
            cr.save ();
            cr.translate (x + width - rx, y + ry);
            cr.scale (rx, ry);
            cr.arc (0.0, 0.0, 1.0, 1.5 * GLib.Math.PI, 2.0 * GLib.Math.PI);
            cr.restore ();

            /* Draw the line down the right side. */
            cr.line_to (x + width, y + height - ry);

            /* Draw the bottom-right arc. */
            cr.save ();
            cr.translate (x + width - rx, y + height - ry);
            cr.scale (rx, ry);
            cr.arc (0.0, 0.0, 1.0, 0.0, 0.5 * GLib.Math.PI);
            cr.restore ();

            /* Draw the line left across the bottom. */
            cr.line_to (x + rx, y + height);

            /* Draw the bottom-left arc. */
            cr.save ();
            cr.translate (x + rx, y + height - y);
            cr.scale (rx, ry);
            cr.arc (0.0, 0.0, 1.0, 0.5 * GLib.Math.PI, GLib.Math.PI);
            cr.restore ();

            /* Draw the line up the left side. */
            cr.line_to (x, y + ry);

            /* Draw the top-left arc. */
            cr.save ();
            cr.translate (x + rx, y + ry);
            cr.scale (rx, ry);
            cr.arc (0.0, 0.0, 1.0, GLib.Math.PI, 1.5 * GLib.Math.PI);
            cr.restore ();

            /* Close the path across the top. */
            cr.close_path ();
        }
        else {
            cr.rectangle (x, y, width, height);
        }
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
        set ("font", "Open Sans " + (FONT_SIZE/* / akira_canvas.current_scale*/).to_string ());
        set ("ellipsize", Pango.EllipsizeMode.END);
        set ("fill-color-rgba", settings.dark_theme ? light_color : dark_color);

        can_focus = false;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);
    }
}

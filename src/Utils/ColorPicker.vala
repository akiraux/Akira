/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Ivan "isneezy" Vilanculo <vilanculoivan@gmail.com>
* Ported from: https://github.com/ColorPicker/RonnyDo
*/

public class Akira.Utils.ColorPicker : Gtk.Window {
    public signal void picked (Gdk.RGBA color);
    public signal void cancelled ();
    public signal void moved (Gdk.RGBA color);
    public signal void key_pressed (Gdk.EventKey e);
    public signal void key_released (Gdk.EventKey e);

    const string DARK_BORDER_COLOR_STRING = "#333333";
    private Gdk.RGBA dark_border_color = Gdk.RGBA ();

    const string BRIGHT_BORDER_COLOR_STRING = "#FFFFFF";
    private Gdk.RGBA bright_border_color = Gdk.RGBA ();


    // 1. Snapsize is the amount of pixel going to be magnified by the zoomlevel.
    // 2. The snapsize must be odd to have a 1px magnifier center.
    // 3. Asure that snapsize*max_zoomlevel+shadow_width*2 is smaller than 2 * get_screen ().get_display ().get_maximal_cursor_size()
    //    Valid: snapsize = 31, max_zoomlevel = 7, shadow_width = 15 --> 247px
    //           get_maximal_cursor_size = 128 --> 256px
    //    Otherwise the cursor starts to flicker. See https://github.com/stuartlangridge/ColourPicker/issues/6#issuecomment-277972290
    //    and https://github.com/RonnyDo/ColorPicker/issues/19
    int snapsize = 31;
    int min_zoomlevel = 2;
    int max_zoomlevel = 7;
    int zoomlevel = 6;
    int shadow_width = 15;

    private Gdk.Cursor magnifier = null;

    construct {
        app_paintable = true;
        decorated = false;
        resizable = false;
        set_visual (get_screen ().get_rgba_visual ());
        type = Gtk.WindowType.POPUP;
    }


    public ColorPicker () {
        stick ();
        set_resizable (true);
        set_deletable (false);
        set_skip_taskbar_hint (true);
        set_skip_pager_hint (true);
        set_keep_above (true);


        dark_border_color.parse (DARK_BORDER_COLOR_STRING);
        bright_border_color.parse (BRIGHT_BORDER_COLOR_STRING);

        // TODO remove the zoom level restauration if we do not need it
        // restore zoomlevel
        // if (settings.zoomlevel >= min_zoomlevel && settings.zoomlevel <= max_zoomlevel) {
        //    zoomlevel = settings.zoomlevel;
        // }

        var display = Gdk.Display.get_default ();
        Gdk.Monitor monitor = display.get_primary_monitor ();
        Gdk.Rectangle geom = monitor.get_geometry ();
        set_default_size (geom.width, geom.height);
    }


    public override bool button_release_event (Gdk.EventButton e) {
        // button_1 is left mouse button
        if (e.button == 1) {
            Gdk.RGBA color = get_color_at ((int) e.x_root, (int) e.y_root);
            picked (color);
        // button_3 is right mouse button
        } else if (e.button == 3) {
            cancelled ();
        }

        return true;
    }


    public override bool draw (Cairo.Context cr) {
       return false;
    }


    public override bool motion_notify_event (Gdk.EventMotion e) {
        Gdk.RGBA color = get_color_at ((int) e.x_root, (int) e.y_root);

        moved (color);

        set_magnifier_cursor ();

        return true;
    }


    public override bool scroll_event (Gdk.EventScroll e) {
        switch (e.direction) {
            case Gdk.ScrollDirection.UP:
                if (zoomlevel < max_zoomlevel) {
                    zoomlevel++;
                }
                set_magnifier_cursor ();
                break;
            case Gdk.ScrollDirection.DOWN:
                if (zoomlevel > min_zoomlevel) {
                    zoomlevel--;
                }
                set_magnifier_cursor ();
                break;
            default:
                break;
         }

         return true;
    }

    public void set_magnifier_cursor () {
        var manager = Gdk.Display.get_default ().get_default_seat ();

        // get cursor position
         int px, py;
         get_window ().get_device_position (manager.get_pointer (), out px, out py, null);

         var radius = snapsize * zoomlevel / 2;

         // get a small area (snap) meant to be zoomed
         var snapped_pixbuf = snap (px - snapsize / 2, py - snapsize / 2, snapsize, snapsize);

         // Zoom that screenshot up, and grab a snapsize-sized piece from the middle
         var scaled_pb = snapped_pixbuf.scale_simple (
            snapsize * zoomlevel + shadow_width * 2 ,
            snapsize * zoomlevel + shadow_width * 2 ,
            Gdk.InterpType.NEAREST
        );


         // Create the base surface for our cursor
         var base_surface = new Cairo.ImageSurface (
            Cairo.Format.ARGB32,
            snapsize * zoomlevel + shadow_width * 2 ,
            snapsize * zoomlevel + shadow_width * 2
        );

         var base_context = new Cairo.Context (base_surface);


         // Create the circular path on our base surface
         base_context.arc (radius + shadow_width, radius + shadow_width, radius, 0, 2 * Math.PI);

         // Paste in the screenshot
         Gdk.cairo_set_source_pixbuf (base_context, scaled_pb, 0, 0);

         // Clip to that circular path, keeping the path around for later, and paint the pasted screenshot
         base_context.save ();
         base_context.clip_preserve ();
         base_context.paint ();
         base_context.restore ();


         // Draw a shadow as outside magnifier border
         double shadow_alpha = 0.6;
         base_context.set_line_width (1);

         for (int i = 0; i <= shadow_width; i++) {
             base_context.arc (
                radius + shadow_width, radius + shadow_width,
                radius + shadow_width - i, 0, 2 * Math.PI
            );
             Gdk.RGBA shadow_color = Gdk.RGBA ();
             shadow_color.parse (DARK_BORDER_COLOR_STRING);
             shadow_color.alpha = shadow_alpha / ((shadow_width - i + 1) * (shadow_width - i + 1));
             Gdk.cairo_set_source_rgba (base_context, shadow_color);
             base_context.stroke ();
         }


        // Draw an outside bright magnifier border
        Gdk.cairo_set_source_rgba (base_context, bright_border_color);
        base_context.arc (radius + shadow_width, radius + shadow_width, radius - 1, 0, 2 * Math.PI);
        base_context.stroke ();


        // Draw inside square
        base_context.set_line_width (1);

        Gdk.cairo_set_source_rgba (base_context, dark_border_color);
        base_context.move_to (radius + shadow_width - zoomlevel, radius + shadow_width - zoomlevel);
        base_context.line_to (radius + shadow_width + zoomlevel, radius + shadow_width - zoomlevel);
        base_context.line_to (radius + shadow_width + zoomlevel, radius + shadow_width + zoomlevel);
        base_context.line_to (radius + shadow_width - zoomlevel, radius + shadow_width + zoomlevel);
        base_context.close_path ();
        base_context.stroke ();

        Gdk.cairo_set_source_rgba (base_context, bright_border_color);
        base_context.move_to (radius + shadow_width - zoomlevel + 1, radius + shadow_width - zoomlevel + 1);
        base_context.line_to (radius + shadow_width + zoomlevel - 1, radius + shadow_width - zoomlevel + 1);
        base_context.line_to (radius + shadow_width + zoomlevel - 1, radius + shadow_width + zoomlevel - 1);
        base_context.line_to (radius + shadow_width - zoomlevel + 1, radius + shadow_width + zoomlevel - 1);
        base_context.close_path ();
        base_context.stroke ();


        magnifier = new Gdk.Cursor.from_surface (
            get_screen ().get_display (),
            base_surface,
            base_surface.get_width () / 2,
            base_surface.get_height () / 2);

        // Set the cursor
        manager.grab (
            get_window (),
            Gdk.SeatCapabilities.ALL,
            true,
            magnifier,
            new Gdk.Event (Gdk.EventType.BUTTON_PRESS | Gdk.EventType.MOTION_NOTIFY | Gdk.EventType.SCROLL),
            null);

    }


    public Gdk.Pixbuf? snap (int x, int y, int w, int h) {
        var root = Gdk.get_default_root_window ();

        var screenshot = Gdk.pixbuf_get_from_window (root, x, y, w, h);
        return screenshot;
    }


    public override bool key_press_event (Gdk.EventKey e) {
        var manager = Gdk.Display.get_default ().get_default_seat ();
        int px, py;
        get_window ().get_device_position (manager.get_pointer (), out px, out py, null);

        switch (e.keyval) {
            case Gdk.Key.Escape:
                cancelled ();
                break;
            case Gdk.Key.Return:
                Gdk.RGBA color = get_color_at (px, py);
                picked (color);
                break;
            case Gdk.Key.Up:
                manager.get_pointer ().warp (get_screen (), px, py - 1);
                break;
            case Gdk.Key.Down:
                manager.get_pointer ().warp (get_screen (), px, py + 1);
                break;
            case Gdk.Key.Left:
                manager.get_pointer ().warp (get_screen (), px - 1, py);
                break;
            case Gdk.Key.Right:
                manager.get_pointer ().warp (get_screen (), px + 1, py);
                break;
        }

        key_pressed (e);

        return true;
    }

    public override bool key_release_event (Gdk.EventKey e) {
        key_released (e);

        return true;
    }

    public Gdk.RGBA get_color_at (int x, int y) {
        var root = Gdk.get_default_root_window ();
        Gdk.Pixbuf? pixbuf = Gdk.pixbuf_get_from_window (root, x, y, 1, 1);

        if (pixbuf != null) {
            // see https://hackage.haskell.org/package/gtk3-0.14.6/docs/Graphics-UI-Gtk-Gdk-Pixbuf.html
            uint8 red = pixbuf.get_pixels ()[0];
            uint8 green = pixbuf.get_pixels ()[1];
            uint8 blue = pixbuf.get_pixels ()[2];

            Gdk.RGBA color = Gdk.RGBA ();
            string spec = "rgb(" + red.to_string () + "," + green.to_string () + "," + blue.to_string () + ")";
            if (color.parse (spec)) {
                return color;
            } else {
                stdout.printf ("ERROR: Parse pixel rgb values failed.");
            }
        }

        // fallback: default RGBA color
        stdout.printf ("ERROR: Gdk.pixbuf_get_from_window failed");
        return Gdk.RGBA ();
    }


    public override void show_all () {
        base.show_all ();

        var manager = Gdk.Display.get_default ().get_default_seat ();
        var window = get_window ();

        var status = manager.grab (
            window,
            Gdk.SeatCapabilities.ALL,
            false,
            new Gdk.Cursor.for_display (window.get_display (), Gdk.CursorType.CROSSHAIR),
            new Gdk.Event (Gdk.EventType.BUTTON_PRESS | Gdk.EventType.BUTTON_RELEASE | Gdk.EventType.MOTION_NOTIFY),
            null);

        if (status != Gdk.GrabStatus.SUCCESS) {
            manager.ungrab ();
        }

        // show magnifier
        set_magnifier_cursor ();
    }

    public new void close () {
        // TODO remove the zoom level saving if we do not need it
        // save zoomlevel
        // settings.zoomlevel = zoomlevel;

        get_window ().set_cursor (null);
        base.close ();
    }
}

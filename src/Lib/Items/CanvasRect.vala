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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

using Akira.Lib.Components;

public class Akira.Lib.Items.CanvasRect : Goo.CanvasRect, Akira.Lib.Items.CanvasItem {
    public Gee.ArrayList<Component> components { get; set; }

    public CanvasRect (
        double _x,
        double _y,
        double _radius_x,
        double _radius_y,
        int _border_size,
        Gdk.RGBA _border_color,
        Gdk.RGBA _fill_color,
        Goo.CanvasItem? _parent,
        Models.CanvasArtboard? _artboard,
        bool _loaded
    ) {
        parent = _artboard != null ? _artboard : _parent;
        canvas = parent.get_canvas () as Akira.Lib.Canvas;

        // Create the rectangle.
        x = _x;
        y = _y;
        width = 1;
        height = 1;
        radius_x = _radius_x;
        radius_y = _radius_y;
    }

    construct {
        components = new Gee.ArrayList<Component> ();

        // Add all the components that this item uses.
        components.add (new Components.Type (typeof (CanvasRect)));
        components.add (new Name (this));
        components.add (new Transform (this));
    }
}

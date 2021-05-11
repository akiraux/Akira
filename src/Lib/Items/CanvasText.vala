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
 * Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
 */

using Akira.Lib.Components;

/**
 * Generate a simple Text item.
 */
public class Akira.Lib.Items.CanvasText : Goo.CanvasText, Akira.Lib.Items.CanvasItem {
    public Gee.ArrayList<Component> components { get; set; }

    public Items.CanvasArtboard? artboard { get; set; }

    public CanvasText (
        string _text,
        double _x,
        double _y,
        double _width,
        double _height,
        Goo.CanvasAnchorType _anchor = Goo.CanvasAnchorType.NW,
        string font_name,
        int font_size,
        Gdk.RGBA fill_color,
        Goo.CanvasItem? _parent,
        Items.CanvasArtboard? _artboard
    ) {
        parent = _artboard != null ? _artboard : _parent;
        artboard = _artboard;

        // Create the text item.
        x = y = 0;
        width = height = 1;
        text = _text;
        anchor = _anchor;
        font = font_name + " " + font_size.to_string ();

        init_position (this, _x, _y);

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);

        // Force the generation of the item bounds on creation.
        Goo.CanvasBounds bounds;
        this.get_bounds (out bounds);

        // Add all the components that this item uses.
        components = new Gee.ArrayList<Component> ();
        components.add (new Name (this));
        components.add (new Coordinates (this));
        components.add (new Opacity (this));
        components.add (new Rotation (this));
        components.add (new Size (this));
        components.add (new Flipped (this));
        components.add (new Layer ());
        components.add (new Fills (this, fill_color));
        components.add (new Font (this, font_name, font_size));

        check_add_to_artboard (this);
    }
}

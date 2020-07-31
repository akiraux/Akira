/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Models.CanvasText : Goo.CanvasText, Models.CanvasItem {
    // Identifiers.
    public Models.CanvasItemType item_type { get; set; }
    public string id { get; set; }
    public string name { get; set; }

    // Transform Panel attributes.
    public double opacity { get; set; }
    public double rotation { get; set; }

    // Fill Panel attributes.
    public bool has_fill { get; set; default = true; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public string color_string { get; set; }
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = true; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
    public string border_color_string { get; set; }
    public int stroke_alpha { get; set; }
    public bool hidden_border { get; set; }

    // Style Panel attributes.
    public bool size_locked { get; set; }
    public double size_ratio { get; set; }
    public bool flipped_h { get; set; }
    public bool flipped_v { get; set; }
    public bool show_border_radius_panel { get; set; }
    public bool show_fill_panel { get; set; }
    public bool show_border_panel { get; set; }

    // Layers panel attributes.
    public bool selected { get; set; }
    public bool locked { get; set; }
    public string layer_icon { get; set; default = "shape-text-symbolic"; }
    public int z_index { get; set; }

    public new Akira.Lib.Canvas canvas { get; set; }
    public Models.CanvasArtboard? artboard { get; set; }
    public Managers.GhostBoundsManager bounds_manager { get; set; }

    public double relative_x { get; set; }
    public double relative_y { get; set; }

    // Knows if an item was created or loaded for ordering purpose.
    public bool loaded { get; set; default = false; }

    public CanvasText (
        string _text = "",
        double _x = 0,
        double _y = 0,
        double _width = 0,
        double _height = 0,
        Goo.CanvasAnchorType _anchor = Goo.CanvasAnchorType.NW,
        string _font = "Open Sans 16",
        Goo.CanvasItem? _parent = null,
        Models.CanvasArtboard? _artboard = null,
        bool _loaded = false
    ) {
        Object (
            x: _x,
            y: _y,
            width: _width,
            height: _height
        );

        loaded = _loaded;
        artboard = _artboard;
        parent = _artboard != null ? _artboard : _parent;
        canvas = parent.get_canvas () as Akira.Lib.Canvas;

        item_type = Models.CanvasItemType.TEXT;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);
        if (artboard != null) {
            connect_to_artboard ();
        }

        text = _text;
        x = 0.0;
        y = 0.0;
        width = _width;
        anchor = _anchor;

        set ("font", _font);
        set ("height", _height);

        set_transform (Cairo.Matrix.identity ());

        position_item (_x, _y);

        // Create the GhostBoundsManager to keep track of the global canvas bounds.
        bounds_manager = new Managers.GhostBoundsManager (this);
    }
}

/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Lib.Models.CanvasText : Goo.CanvasText, Models.CanvasItem {
    public string id { get; set; }
    public Models.CanvasItemType item_type { get; set; }

    public CanvasText (
        string _text = "",
        double _x = 0,
        double _y = 0,
        double _width = 0,
        double _height = 0,
        Goo.CanvasAnchorType _anchor  = Goo.CanvasAnchorType.NW,
        string _font = "Open Sans 16",
        Goo.CanvasItem? parent = null
    )  {
        Object(
            parent: parent
        );

        item_type = Models.CanvasItemType.TEXT;

        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        text = _text;
        x = _x;
        y = _y;
        width = _width;
        anchor = _anchor;

        set ("font", _font);
        set ("height", _height);

        set_transform (Cairo.Matrix.identity ());

        debug (@"Created item with ID: $(id)");
    }
}

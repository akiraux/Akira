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

public class Akira.Lib.Models.CanvasEllipse : Goo.CanvasEllipse, Models.CanvasItem {
    public string id { get; set; }
    public Models.CanvasItemType item_type { get; set; }

    public CanvasEllipse (
        double _center_x = 0,
        double _center_y = 0,
        double _radius_x = 0,
        double _radius_y = 0,
        double _border_size = 1.0,
        string _border_color = "#aaa",
        string _fill_color = "#ccc",
        Goo.CanvasItem? parent = null
    )  {
        Object(
            parent: parent
        );

        item_type = Models.CanvasItemType.ELLIPSE;

        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        radius_x = _radius_x;
        radius_y = _radius_y;
        width = 1;
        height = 1;
        center_x = _center_x;
        center_y = _center_y;

        set_transform (Cairo.Matrix.identity ());

        set ("line-width", _border_size);
        set ("fill-color", _fill_color);
        set ("stroke-color", _border_color);

        debug (@"Created item with ID: $(id)");
    }
}

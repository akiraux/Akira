/*
* Copyright (c) 2020 Adam Bieńkowski
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
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Adam Bieńkowski <donadigos159@gmail.com>
*/

public class Akira.Lib.Models.CanvasImage : Goo.CanvasImage, CanvasItem {
    public string id { get; set; }
    public bool selected { get; set; }
    public double rotation { get; set; }
    public double opacity { get; set; }
    public bool has_fill { get; set; default = false; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public bool hidden_fill { get; set; }
    public bool has_border { get; set; default = false; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
    public int stroke_alpha { get; set; }
    public bool hidden_border { get; set; }
    public Models.CanvasItemType item_type { get; set; }

    public CanvasImage (Akira.Services.ImageProvider provider, Goo.CanvasItem? parent = null) {
        Object (parent: parent);

        item_type = Models.CanvasItemType.IMAGE;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);


        width = 100;
        height = 100;
        x = 0;
        y = 0;

        set_transform (Cairo.Matrix.identity ());

        provider.get_pixbuf.begin (-1, -1, (obj, res) => {
            try {
                pixbuf = provider.get_pixbuf.end (res);
            } catch (Error e) {
                warning (e.message);
                // TODO: handle error here
            }
        });
    }
}

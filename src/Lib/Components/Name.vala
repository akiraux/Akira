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

/**
 * Name component to handle generating an ID and a unique name on creation.
 */
public class Akira.Lib.Components.Name : Component {
    public string id { get; set; }
    public string name { get; set; }
    public string icon { get; set; }

    public Name (Lib.Items.CanvasItem item) {
        this.item = item;

        set_properties ();
        update_name ();
    }

    private void set_properties () {
        var type = item.get_type ();
        // Assign the proper icon for the layers panel.
        // We can't use a switch () method here because the typeof () method is not supported.
        if (type == typeof (Items.CanvasArtboard)) {
            icon = null;
            name = _("Artboard");
        }

        if (type == typeof (Items.CanvasRect)) {
            icon = "shape-rectangle-symbolic";
            name = _("Rectangle");
        }

        if (type == typeof (Items.CanvasEllipse)) {
            icon = "shape-circle-symbolic";
            name = _("Ellipse");
        }

        if (type == typeof (Items.CanvasText)) {
            icon = "shape-text-symbolic";
            name = _("Text");
        }

        if (type == typeof (Items.CanvasImage)) {
            icon = "shape-image-symbolic";
            name = _("Image");
        }
    }

    private void update_name () {
        var type = item.get_type ();

        // Make sure the initial ID includes the current count of the total amount
        // of items with the same item type in the same artboard.
        int count = 0;
        var items = ((Lib.Canvas) item.canvas).window.items_manager.free_items;

        if (item.artboard != null) {
            items = item.artboard.items;
        }

        if (item is Lib.Items.CanvasArtboard) {
            items = ((Lib.Canvas) item.canvas).window.items_manager.artboards;
        }

        foreach (var _item in items) {
            if (_item.get_type () == type) {
                count++;
            }
        }

        id = name + " " + count.to_string ();
        name = id;
    }
}

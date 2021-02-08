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
    public string id { get; set construct; }
    public string name { get; set construct; }

    public Name (Lib.Items.CanvasItem item) {
        GLib.Type item_type = item.type ();
        string[] type_slug_tokens = item_type.to_string ().split ("_");
        string type_slug = type_slug_tokens [type_slug_tokens.length - 1];

        // Make sure the initial ID is the current count of the total amount
        // of items with the same item type in the same artboard.
        int count = 0;
        var items = ((Akira.Lib.Canvas) item.canvas).window.items_manager.free_items;
        // TEMPORARILY DISABLED.
        //  var items = item.artboard != null ? item.artboard.items : item.canvas.window.items_manager.free_items;
        //  if (item is Lib.Items.CanvasArtboard) {
        //      items = item.canvas.window.items_manager.artboards;
        //  }

        foreach (var _item in items) {
            if (_item.item_type == item_type) {
                count++;
            }
        }

        this.id = capitalize (type_slug.down ()) + " " + count.to_string ();
        this.name = this.id;
    }

    /**
     * Helper method to capitalize the first letter of the item's name.
     */
    private static string capitalize (string s) {
        string back = s;
        if (s.get_char (0).islower ()) {
            back = s.get_char (0).toupper ().to_string () + s.substring (1);
        }

        return back;
    }
}

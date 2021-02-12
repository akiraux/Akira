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
 * Type component to keep track of the item type. E.g.: CanvasRect, CanvasEllipse, etc.
 */
public class Akira.Lib.Components.Type : Component {
    public GLib.Type item_type { get; set; }
    public string? icon { get; set; }

    public Type (GLib.Type type) {
        this.item_type = type;

        // Assign the proper icon for the layers panel.
        // We can't use a switch () method here because the typeof () method is not supported.
        if (type == typeof (Items.CanvasArtboard)) {
            icon = null;
        }

        if (type == typeof (Items.CanvasRect)) {
            icon = "shape-rectangle-symbolic";
        }

        if (type == typeof (Items.CanvasEllipse)) {
            icon = "shape-circle-symbolic";
        }

        if (type == typeof (Items.CanvasText)) {
            icon = "shape-text-symbolic";
        }
    }
}

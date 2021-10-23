/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * Simple Object to be handled by the LayersListBoxModel and to give easy access
 * the attributes of the Lib.Items.ModelInstance.
 */
public class Akira.Layouts.LayersPanel.LayerItemModel : GLib.Object {
    private unowned Akira.Lib.Items.ModelInstance model;

    public LayerItemModel (Akira.Lib.Items.ModelInstance model) {
        set_model (model);
    }

    private void set_model (Akira.Lib.Items.ModelInstance new_model) {
        model = new_model;
    }

    /*
     * Control the name of the item.
     */
    public string name {
        owned get {
            return model.components.name.name;
        }
    }

    /*
     * Control the hidden/visible state of the item.
     */
    // TODO.

    /*
     * Control the locked/unlocked state of the item.
     */
    public bool locked {
        get {
            return model.components.layer.locked;
        }
    }

    /*
     * Control the selected state of the item.
     */
    public bool selected {
        get {
            return model.components.layer.selected;
        }
    }
}

/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

// this class is a popover displayed when user wants to insert
// a new category in the artboard sizes panel, or a new size.
public class Akira.Widgets.ArtboardPanelInsertPopover : Gtk.Popover {
    // label for the name of category or size
    private Gtk.Label name_label;
    // input for name of category or size
    private Gtk.Entry name_input;

    // label for the width of artboard
    private Gtk.Label width_label;
    // input for width of input
    private Gtk.Entry width_input;

    // label for the height of artboard
    private Gtk.Label height_label;
    // input for height of input
    private Gtk.Entry height_input;


    // string containing the name of category of size
    public string item_name;
    // string containing the width of created artboard
    public int item_width;
    // string containing the height of created artboard
    public int item_height;

    public ArtboardPanelInsertPopover (Gtk.Widget widget) {
        set ("relative-to", widget);
        // the popover is modal so when user enters values here,
        // other widgets do not recieve inputs
        modal = true;
        position = Gtk.PositionType.BOTTOM;

        item_name = "";
        item_width = 0;
        item_height = 0;
    }

    public void initialize_popover (bool show_size) {
        Gtk.Grid grid = new Gtk.Grid ();

        name_label = new Gtk.Label ("Name");
        name_label.hexpand = true;
        name_label.get_style_context ().add_class ("size-category-item");
        name_label.visible = true;

        name_input = new Gtk.Entry ();
        name_input.hexpand = true;
        name_input.get_style_context ().add_class ("size-category-item");
        name_input.visible = true;

        width_label = new Gtk.Label ("Width");
        width_label.hexpand = true;
        width_label.get_style_context ().add_class ("size-category-item");

        width_input = new Gtk.Entry ();
        width_input.hexpand = true;
        width_input.get_style_context ().add_class ("size-category-item");

        height_label = new Gtk.Label ("Height");
        height_label.hexpand = true;
        height_label.get_style_context ().add_class ("size-category-item");

        height_input = new Gtk.Entry ();
        height_input.hexpand = true;
        height_input.get_style_context ().add_class ("size-category-item");

        name_input.activate.connect ( ()=> {
            if (name_input.text == "") {
                return;
            }

            if( are_inputs_valid(show_size) ) {
                popdown();
            }
        });

        width_input.activate.connect ( ()=> {
            if (width_input.text == "") {
                return;
            }

            if( are_inputs_valid(show_size) ) {
                popdown();
            }
        });

        height_input.activate.connect ( ()=> {
            if (name_input.text == "") {
                return;
            }

            if( are_inputs_valid(show_size) ) {
                popdown();
            }
        });

        grid.attach (name_label, 0, 0, 1, 1);
        grid.attach (name_input, 1, 0, 1, 1);

        if (show_size) {
            grid.attach (width_label, 0, 1, 1, 1);
            grid.attach (width_input, 1, 1, 1, 1);

            grid.attach (height_label, 0, 2, 1, 1);
            grid.attach (height_input, 1, 2, 1, 1);
        }

        grid.show_all ();

        add (grid);
    }

    private bool are_inputs_valid (bool show_size) {
        bool is_valid = true;

        if(name_input.text != "") {
            item_name = name_input.text;
        } else {
            is_valid = false;
        }

        if(!show_size) {
            return is_valid;
        }

        if(width_input.text != "") {
            int width = int.parse(width_input.text);

            // if width is negative or wasn't parsed correctly,
            if(width <= 0) {
                is_valid = false;
            } else {
                item_width = width;
            }
        } else {
            is_valid = false;
        }

        if(height_input.text != "") {
            int height = int.parse(height_input.text);

            if(height <= 0) {
                is_valid = false;
            } else {
                item_height = height;
            }
        } else {
            is_valid = false;
        }

        return is_valid;
    }
}

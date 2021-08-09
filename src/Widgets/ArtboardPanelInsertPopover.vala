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

    // label for the size of artboard
    private Gtk.Label size_label;
    // input for size of input
    private Gtk.Entry size_input;

    // string containing the name of category of size
    public string item_name;
    // string containing the size of created artboard
    public string item_size;

    public ArtboardPanelInsertPopover (Gtk.Widget widget) {
        set ("relative-to", widget);
        // the popover is modal so when user enters values here,
        // other widgets do not recieve inputs
        modal = true;
        position = Gtk.PositionType.BOTTOM;

        item_name = "";
        item_size = "";
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

        name_input.activate.connect ( ()=>{
            if (show_size) {

            } else {
                if (name_input.text == "") {
                    return;
                }

                item_name = name_input.text;
                popdown ();
            }
        });

        size_label = new Gtk.Label ("Size");
        size_label.hexpand = true;
        size_label.get_style_context ().add_class ("size-category-item");

        size_input = new Gtk.Entry ();
        size_input.hexpand = true;
        size_input.get_style_context ().add_class ("size-category-item");

        grid.attach (name_label, 0, 0, 1, 1);
        grid.attach (name_input, 1, 0, 1, 1);

        if (show_size) {
            grid.attach (size_label, 0, 1, 1, 1);
            grid.attach (size_input, 1, 1, 1, 1);
        }

        grid.show_all ();

        add (grid);
    }
}

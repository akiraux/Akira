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
 * The single layer row.
 */
public class Akira.Layouts.LayersList.LayerListItem : VirtualizingListBoxRow {
    public signal void row_updated (int id);

    private LayerItemModel model;

    private Gtk.StyleContext style_ctx;
    // Main grid to attach all other grid widgets.
    private Gtk.Grid grid_main;
    // Grid to collect the label and entry widgets.
    private Gtk.Grid grid_entry;

    private Gtk.Label label;
    private Gtk.Entry entry;
    private Gtk.Image icon;

    public bool is_editing = false;

    construct {
        style_ctx = get_style_context ();

        icon = new Gtk.Image () {
            margin_start = 12,
            margin_end = 9,
            vexpand = true,
            valign = Gtk.Align.CENTER,
        };
        icon.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        label = new Gtk.Label ("") {
            halign = Gtk.Align.FILL,
            xalign = 0,
            expand = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        grid_main = new Gtk.Grid ();
        grid_entry = new Gtk.Grid ();
        grid_entry.attach (label, 0, 0, 1, 1);

        grid_main.attach (icon, 0, 0, 1, 1);
        grid_main.attach (grid_entry, 1, 0, 1, 1);

        add (grid_main);
    }

    public void assign (LayerItemModel data) {
        model_item = data;
        model = (LayerItemModel) model_item;

        label.label = model.name;

        // Build a specific UI based on the node instance's type.
        if (data.is_artboard) {
            build_artboard_ui ();
        } else if (data.is_group) {
            build_group_ui ();
        } else {
            build_layer_ui ();
        }
    }

    private void build_artboard_ui () {
        // Update the general UI.
        style_ctx.remove_class ("layer");
        style_ctx.add_class ("artboard");

        // Update the label UI.
        label.get_style_context ().add_class ("artboard-name");

        // Update icon.
        icon.clear ();
    }

    /*
     * TODO...
     */
    private void build_group_ui () {}

    private void build_layer_ui () {
        // Update general UI.
        style_ctx.remove_class ("artboard");
        style_ctx.add_class ("layer");

        // Update label styling.
        label.get_style_context ().remove_class ("artboard-name");

        // Update icon.
        icon.set_from_icon_name (model.icon, Gtk.IconSize.MENU);
    }

    public override void edit () {
        if (entry != null) {
            show_entry ();
            return;
        }

        entry = new Gtk.Entry () {
            expand = true
        };
        entry.get_style_context ().add_class ("flat");

        entry.activate.connect (on_activate_entry);

        grid_entry.attach (entry, 0, 1, 1, 1);

        show_entry ();
    }

    private void on_activate_entry () {
        model.name = entry.text;
        label.label = model.name;
        row_updated (model.id);
    }

    private void show_entry () {
        entry.text = label.label;
        entry.visible = true;
        entry.no_show_all = false;
        label.visible = false;
        label.no_show_all = true;
        entry.grab_focus ();
        is_editing = true;
    }

    public override void edit_end () {
        entry.visible = false;
        entry.no_show_all = true;
        label.visible = true;
        label.no_show_all = false;
        is_editing = false;
    }
}

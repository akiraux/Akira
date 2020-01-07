/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.Partials.BordersPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Gtk.Button add_btn;
    public Gtk.ListBox borders_list_container;
    public Akira.Models.ListModel list_model;
    public Gtk.Grid title_cont;
    private Lib.Models.CanvasItem selected_item;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public BordersPanel (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.HORIZONTAL
        );
    }

    construct {
        title_cont = new Gtk.Grid ();
        title_cont.orientation = Gtk.Orientation.HORIZONTAL;
        title_cont.hexpand = true;
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Borders"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        add_btn = new Gtk.Button ();
        add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_btn.can_focus = false;
        add_btn.valign = Gtk.Align.CENTER;
        add_btn.halign = Gtk.Align.CENTER;
        add_btn.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));
        add_btn.show_all ();
        toggle_add_btn (false);

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_btn, 1, 0, 1, 1);

        list_model = new Akira.Models.ListModel (Akira.Models.ListModel.ListType.BORDER);

        borders_list_container = new Gtk.ListBox ();
        borders_list_container.margin_top = borders_list_container.margin_bottom = 5;
        borders_list_container.margin_start = 10;
        borders_list_container.margin_end = 5;
        borders_list_container.selection_mode = Gtk.SelectionMode.NONE;
        borders_list_container.get_style_context ().add_class ("fills-list");

        borders_list_container.bind_model (list_model, item => {
            return new Akira.Layouts.Partials.BorderItem (window, (Akira.Models.BordersItemModel) item);
        });

        attach (title_cont, 0, 0, 1, 1);
        attach (borders_list_container, 0, 1, 1, 1);
        show_all ();

        create_event_bindings ();
    }

    private void create_event_bindings () {
        toggled = false;
        window.event_bus.selected_items_changed.connect (on_selected_items_changed);
        window.event_bus.border_deleted.connect (() => {
            toggle_add_btn (true);
        });
        add_btn.clicked.connect (() => {
            list_model.add_border.begin (selected_item);
            selected_item.reset_colors ();
            toggle_add_btn (false);
        });
    }

    private void on_selected_items_changed (List<Lib.Models.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            selected_item = null;
            list_model.clear.begin ();
            toggle_add_btn (false);
            toggled = false;
            return;
        }

        if (selected_item == null || selected_item != selected_items.nth_data (0)) {
            toggled = true;
            selected_item = selected_items.nth_data (0);

            if (!selected_item.has_border) {
                toggle_add_btn (true);
                return;
            }

            list_model.add_border.begin (selected_item);
        }
    }

    private void toggle_add_btn (bool show) {
        add_btn.visible = show;
        add_btn.no_show_all = !show;
    }
}

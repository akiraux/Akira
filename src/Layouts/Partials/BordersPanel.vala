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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Layouts.Partials.BordersPanel : Gtk.Grid {
    private unowned Akira.Window window;

    public Gtk.Button add_btn;
    public Gtk.ListBox borders_list_container;
    private GLib.ListStore list;
    private unowned List<Lib.Items.CanvasItem>? items;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public BordersPanel (Akira.Window window) {
        this.window = window;

        var title_cont = new Gtk.Grid ();
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
        add_btn.set_tooltip_text (_("Add border"));
        add_btn.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_btn, 1, 0, 1, 1);

        list = new GLib.ListStore (typeof (Lib.Components.Border));

        borders_list_container = new Gtk.ListBox ();
        borders_list_container.margin_top = 5;
        borders_list_container.margin_bottom = 15;
        borders_list_container.margin_start = 10;
        borders_list_container.margin_end = 5;
        borders_list_container.selection_mode = Gtk.SelectionMode.NONE;
        borders_list_container.get_style_context ().add_class ("fills-list");

        borders_list_container.bind_model (list, item => {
            var border_items = new Layouts.Partials.BorderItem (window, (Lib.Components.Border) item);
            border_items.border_deleted.connect (() => {
                reload_list (items);
            });
            return border_items;
        });

        attach (title_cont, 0, 0, 1, 1);
        attach (borders_list_container, 0, 1, 1, 1);
        show_all ();

        create_event_bindings ();
    }

    private void create_event_bindings () {
        toggled = false;
        window.event_bus.selected_items_list_changed.connect (reload_list);

        add_btn.clicked.connect (() => {
            var border_color = Gdk.RGBA ();
            border_color.parse (settings.border_color);

            foreach (Lib.Items.CanvasItem item in items) {
                list.insert (0, item.borders.add_border_color (border_color, (int) settings.border_size));
            }
        });

        // Listen to the model changes when adding/removing items.
        list.items_changed.connect ((position, removed, added) => {
            window.main_window.left_sidebar.queue_resize ();
        });
    }

    private void reload_list (List<Lib.Items.CanvasItem> selected_items) {
         // Always clear the list model when a selection changes.
         list.remove_all ();

        if (selected_items.length () == 0) {
            items = null;
            toggled = false;
            return;
        }

        items = selected_items;

        bool show = false;
        foreach (Lib.Items.CanvasItem item in selected_items) {
            // Skip items that don't have a border item since there will be nothing to show.
            if (item.borders == null) {
                continue;
            }

            // At least an item has the borders component, so we can show the
            show = true;

            // Loops through all the available borders and add them tot he list model.
            // TODO: handle duplicate identical colors.
            foreach (Lib.Components.Border border in item.borders.borders) {
                list.insert (0, border);
            }
        }

        toggled = show;
    }
}

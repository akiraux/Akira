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

public class Akira.Layouts.Partials.ArtboardSizesPanel : Gtk.Grid {
    private unowned Akira.Window window;

    private Gtk.Button add_category_btn;
    private Gtk.ListBox fills_list_container;
    private unowned List<Lib.Items.CanvasItem>? items;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public ArtboardSizesPanel (Akira.Window window) {
        this.window = window;

        var title_cont = new Gtk.Grid ();
        title_cont.orientation = Gtk.Orientation.HORIZONTAL;
        title_cont.hexpand = true;
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Artboard Sizes"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        add_category_btn = new Gtk.Button ();
        add_category_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_category_btn.can_focus = false;
        add_category_btn.valign = Gtk.Align.CENTER;
        add_category_btn.halign = Gtk.Align.CENTER;
        add_category_btn.set_tooltip_text (_("Create new size category"));
        add_category_btn.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_category_btn, 1, 0, 1, 1);

        attach (title_cont, 0, 0, 1, 1);
        show_all ();

        window.event_bus.insert_item.connect((item_type) => {
            reload_list( (item_type == "artboard") );
        });
    }

    private void reload_list (bool show) {

    }
}

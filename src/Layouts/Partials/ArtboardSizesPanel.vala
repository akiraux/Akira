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
    private Gtk.ListBox size_list_container;
    private GLib.ListStore list;
    private string[] category_names = {"Desktop", "Laptop", "Mobile"};

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

        size_list_container = new Gtk.ListBox ();
        size_list_container.margin_top = 5;
        size_list_container.margin_bottom = 15;
        size_list_container.margin_start = 10;
        size_list_container.margin_end = 5;
        size_list_container.selection_mode = Gtk.SelectionMode.NONE;
        size_list_container.get_style_context ().add_class ("fills-list");

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_category_btn, 1, 0, 1, 1);

        list = new GLib.ListStore(Type.OBJECT);
        foreach(string category in category_names) {
            list.insert(0, new SizeCategoryItem(category));
        }

        size_list_container.bind_model (list, item => {
            return create_category_expander((SizeCategoryItem)item);
        });

        attach (title_cont, 0, 0, 1, 1);
        attach (size_list_container, 0, 1, 1, 1);
        show_all ();

        add_category_btn.clicked.connect(handle_add_category);

        window.event_bus.insert_item.connect((item_type) => {
            reload_list( (item_type == "artboard") );
        });
    }

    private Gtk.Expander create_category_expander(SizeCategoryItem category) {
        Gtk.Expander category_expander = new Gtk.Expander(category.size);
        category_expander.get_style_context().add_class("size-category-item");

        return category_expander;
    }

    private void handle_add_category() {
        InsertItemPopover new_category_popup = new InsertItemPopover(add_category_btn);
        new_category_popup.iniitalizePopover(false);

        new_category_popup.closed.connect(()=>{
            if(new_category_popup.item_name != "") {
                list.insert(0, new SizeCategoryItem(new_category_popup.item_name));
            }
        });

        new_category_popup.popup();
    }

    private void reload_list (bool show) {

    }
}

// this class represents a category of artboard sizes.
// since this will not be user elsewhere, it is private and has been placed here
private class SizeCategoryItem : Object {
    public string size;

    public SizeCategoryItem(string _size) {
        size = _size;
    }
}

// this class represents a popver that opens when user clicks on a "+" button to
// add a new category or artboard size.
private class InsertItemPopover : Gtk.Popover {
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

    public InsertItemPopover(Gtk.Widget widget) {
        set("relative-to", widget);
        // the popover is modal so when user enters values here,
        // other widgets do not recieve inputs
        modal = true;
        position = Gtk.PositionType.BOTTOM;

        item_name = "";
        item_size = "";
    }

    public void iniitalizePopover(bool show_size) {
        Gtk.Grid grid = new Gtk.Grid();

        name_label = new Gtk.Label("Name");
        name_label.hexpand = true;
        name_label.get_style_context().add_class("size-category-item");
        name_label.visible = true;

        name_input = new Gtk.Entry();
        name_input.hexpand = true;
        name_input.get_style_context().add_class("size-category-item");
        name_input.visible = true;

        name_input.activate.connect(()=>{
            if(show_size) {

            } else {
                if(name_input.text == "") {
                    return;
                }

                item_name = name_input.text;
                popdown();
            }
        });

        size_label = new Gtk.Label("Size");
        size_label.hexpand = true;
        size_label.get_style_context().add_class("size-category-item");

        size_input = new Gtk.Entry();
        size_input.hexpand = true;
        size_input.get_style_context().add_class("size-category-item");

        grid.attach(name_label, 0, 0, 1, 1);
        grid.attach(name_input, 1, 0, 1, 1);

        if(show_size) {
            grid.attach(size_label, 0, 1, 1, 1);
            grid.attach(size_input, 1, 1, 1, 1);
        }

        grid.show_all();

        add(grid);
    }
}

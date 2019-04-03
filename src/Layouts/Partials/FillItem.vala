/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
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
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.FillItem : Gtk.Grid {
    public signal void remove_item (Akira.Models.FillsItemModel model);

    public Akira.Models.FillsItemModel model { get; construct; }

    private Akira.Utils.BlendingMode blending_mode {
        owned get {
            return model.blending_mode;
        }
        set {
            model.blending_mode = value;
            selected_blending_mode.label = model.blending_mode.get_name ();
        }
    }

    private string color {
        owned get {
            return model.color;
        }
        set {
            print ("%s\n", selected_color.get_style_context ().to_string (Gtk.StyleContextPrintFlags.RECURSE));
        }
    }

    private new uint opacity {
        owned get {
            return model.opacity;
        }
        set {
            current_opacity.label = "%d %%".printf ((int) model.opacity);
        }
    }

    private new bool visible {
        owned get {
            return model.visible;
        }
        set {
            model.visible = value;

            if (visible_button_icon != null) {
                visible_button.remove (visible_button_icon);
            }

            visible_button_icon = new Gtk.Image .from_icon_name (
                "layer-%s-symbolic".printf(model.visible ? "visible" : "hidden"),
                Gtk.IconSize.SMALL_TOOLBAR
                );

            visible_button.add (visible_button_icon);

            visible_button_icon.show_all ();
        }
    }

    private Gtk.Grid fill_chooser;
    private Gtk.Button visible_button;
    private Gtk.Button delete_button;
    private Gtk.Button show_options_button;
    private Gtk.Image visible_button_icon;
    private Gtk.Button selected_blending_mode_cont;
    private Gtk.Label selected_blending_mode;
    private Gtk.Label current_opacity;
    private Gtk.Button selected_color;
    private Gtk.Popover blending_mode_popover;
    private Gtk.ListBox blending_mode_popover_items;

    public FillItem (Akira.Models.FillsItemModel model) {
        Object(
            model: model
            );
    }

    construct {
        create_ui ();
        create_event_bindings ();
        update_view ();
        show_all ();
    }

    private void update_view () {
        opacity = model.opacity;
        visible = model.visible;
        blending_mode = model.blending_mode;
        color = model.color;
    }

    private void create_ui () {
        selected_blending_mode = new Gtk.Label ("");

        fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;

        selected_color = new Gtk.Button ();
        selected_color.can_focus = false;
        selected_color.get_style_context ().add_class ("selected-color");

        selected_blending_mode = new Gtk.Label ("");
        selected_blending_mode.hexpand = true;
        selected_blending_mode.halign = Gtk.Align.START;

        selected_blending_mode_cont = new Gtk.Button ();
        selected_blending_mode_cont.get_style_context ().add_class ("flat");
        selected_blending_mode_cont.get_style_context ().add_class ("flat-btn");
        selected_blending_mode_cont.can_focus = false;
        selected_blending_mode_cont.hexpand = true;
        selected_blending_mode_cont.add (selected_blending_mode);

        show_options_button = new Gtk.Button ();
        show_options_button.can_focus = false;
        show_options_button.valign = Gtk.Align.CENTER;
        show_options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        show_options_button.get_style_context ().add_class ("popover-toggler");

        show_options_button.add (new Gtk.Image.from_icon_name ("pan-down-symbolic",
                                                               Gtk.IconSize.SMALL_TOOLBAR));

        current_opacity = new Gtk.Label ("");
        current_opacity.halign = Gtk.Align.CENTER;
        current_opacity.get_style_context ().add_class ("opacity");

        fill_chooser.attach(selected_color, 0, 0, 1, 1);
        fill_chooser.attach(selected_blending_mode_cont, 1, 0, 1, 1);
        fill_chooser.attach(show_options_button, 2, 0, 1, 1);
        fill_chooser.attach(current_opacity, 3, 0, 1, 1);

        fill_chooser.get_style_context ().add_class ("fill-chooser");

        visible_button = new Gtk.Button ();
        visible_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        visible_button.can_focus = false;
        visible_button.valign = Gtk.Align.CENTER;

        delete_button = new Gtk.Button ();
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
                                                         Gtk.IconSize.SMALL_TOOLBAR));

        blending_mode_popover_items = new Gtk.ListBox ();
        blending_mode_popover_items.get_style_context ().add_class ("popover-list");

        var popover_item_index = 0;

        foreach (Akira.Utils.BlendingMode mode in Akira.Utils.BlendingMode.all () ) {
            blending_mode_popover_items
                .insert (new Akira.Layouts.Partials.BlendingModeItem (mode), popover_item_index++);
        }

        blending_mode_popover = new Gtk.Popover(selected_blending_mode_cont);
        blending_mode_popover.position = Gtk.PositionType.BOTTOM;

        blending_mode_popover.add(blending_mode_popover_items);

        attach(fill_chooser, 0, 0, 1, 1);
        attach(visible_button, 1, 0, 1, 1);
        attach(delete_button, 2, 0, 1, 1);

        get_style_context ().add_class ("fill-chooser-cont");
    }

    private void create_event_bindings () {
        delete_button.clicked.connect (on_delete_item);
        visible_button.clicked.connect (toggle_visibility);
        show_options_button.clicked.connect (on_show_popover);
        blending_mode_popover_items.row_activated.connect (on_row_activated);
        blending_mode_popover_items.row_selected.connect (on_popover_item_selected);
        selected_blending_mode_cont.clicked.connect (on_show_popover);

        model.notify.connect (on_model_changed);
    }

    private void on_model_changed () {
        model.list_model.update_fills ();
    }

    private void on_row_activated (Gtk.ListBoxRow? item) {
        var fillItem = (Akira.Layouts.Partials.BlendingModeItem) item.get_child ();
        blending_mode = fillItem.mode;
        blending_mode_popover.hide ();
    }

    private void on_popover_item_selected (Gtk.ListBoxRow? item) {
    }

    private void on_show_popover () {
        if (!blending_mode_popover.visible) {
            blending_mode_popover.width_request = selected_blending_mode_cont.get_allocated_width ();

            blending_mode_popover.show_all ();
        } else {
            blending_mode_popover.hide ();
        }
    }

    private void on_delete_item () {
        remove_item (model);
    }

    private void toggle_visibility () {
        visible = !visible;
    }
}

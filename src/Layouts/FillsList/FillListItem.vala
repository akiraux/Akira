/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * The single color fill row.
 */
public class Akira.Layouts.FillsList.FillListItem : VirtualizingListBoxRow {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private FillItemModel model;

    private Widgets.ColorButton color_button;
    private Gtk.Button eyedropper_button;
    private Gtk.Button hide_button;
    private Gtk.Button delete_button;
    private Widgets.ColorField color_field;
    private Widgets.OpacityField opacity_field;
    private Widgets.ColorPicker? eyedropper = null;

    public FillListItem (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        var grid = new Gtk.Grid () {
            margin = 3
        };

        var container = new Gtk.Grid ();
        var context = container.get_style_context ();
        context.add_class ("selected-color-container");
        context.add_class ("bg-pattern");

        color_button = new Widgets.ColorButton ();
        container.add (color_button);

        eyedropper_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Pick color")
        };
        eyedropper_button.add (
            new Gtk.Image.from_icon_name ("color-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR)
        );
        eyedropper_button.get_style_context ().add_class ("color-picker-button");
        eyedropper_button.clicked.connect (on_eyedropper_click);

        grid.add (container);
        grid.add (eyedropper_button);

        color_field = new Widgets.ColorField (view_canvas);
        grid.add (color_field);

        opacity_field = new Widgets.OpacityField (view_canvas);
        grid.add (opacity_field);

        hide_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            margin_start = 3
        };
        hide_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hide_button.get_style_context ().add_class ("button-rounded");
        hide_button.clicked.connect (toggle_color_visibility);
        grid.add (hide_button);

        delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            tooltip_text = _("Remove color"),
            margin_start = 3
        };
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.get_style_context ().add_class ("button-rounded");
        delete_button.clicked.connect (delete_fill);
        grid.add (delete_button);

        add (grid);
    }

    public void assign (FillItemModel data) {
        model_item = data;
        model = (FillItemModel) model_item;
        color_button.assign (model);
        color_field.assign (model);
        opacity_field.assign (model);

        update_hide_button ();
    }

    private void toggle_color_visibility () {
        model.hidden = !model.hidden;
        update_hide_button ();
    }

    private void update_hide_button () {
        if (model.hidden) {
            hide_button.get_style_context ().add_class ("active");
            hide_button.image = new Gtk.Image.from_icon_name ("layer-hidden-symbolic", Gtk.IconSize.MENU);
            hide_button.tooltip_text = _("Show color");
            get_style_context ().add_class ("disabled");
            selectable = false;
            color_button.sensitive = false;
            eyedropper_button.sensitive = false;
            color_field.sensitive = false;
            opacity_field.sensitive = false;
            return;
        }

        hide_button.get_style_context ().remove_class ("active");
        hide_button.image = new Gtk.Image.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU);
        hide_button.tooltip_text = _("Hide color");
        get_style_context ().remove_class ("disabled");
        selectable = true;
        color_button.sensitive = true;
        eyedropper_button.sensitive = true;
        color_field.sensitive = true;
        opacity_field.sensitive = true;
    }

    private void delete_fill () {
        model.delete ();
        view_canvas.window.main_window.refresh_fills ();
    }

    private void on_eyedropper_click () {
        if (eyedropper == null) {
            eyedropper = new Widgets.ColorPicker ();
        }
        eyedropper.show_all ();

        eyedropper.picked.connect ((picked_color) => {
            model.color = picked_color;
            eyedropper.close ();
        });

        eyedropper.cancelled.connect (() => {
            eyedropper.close ();
        });
    }
}

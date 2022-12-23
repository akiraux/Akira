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
    private Widgets.ColorField color_field;
    private Widgets.OpacityField opacity_field;
    private Widgets.EyeDropperButton eyedropper_button;
    private Widgets.HideButton hide_button;
    private Gtk.Button delete_button;

    private bool? current_state = null;

    public FillListItem (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        get_style_context ().add_class ("item-property");

        var grid = new Gtk.Grid () {
            margin = 3
        };

        var container = new Gtk.Grid ();
        var context = container.get_style_context ();
        context.add_class ("selected-color-container");
        context.add_class ("bg-pattern");

        color_button = new Widgets.ColorButton ();
        container.add (color_button);

        eyedropper_button = new Widgets.EyeDropperButton () {};
        grid.add (container);
        grid.add (eyedropper_button);

        color_field = new Widgets.ColorField (view_canvas);
        grid.add (color_field);

        opacity_field = new Widgets.OpacityField (view_canvas);
        grid.add (opacity_field);

        hide_button = new Widgets.HideButton () {};
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

    ~FillListItem () {
        model.value_changed.disconnect (on_model_changed);
    }

    public void assign (FillItemModel data) {
        model_item = data;
        model = (FillItemModel) model_item;
        color_button.assign (model);
        color_field.assign (model);
        opacity_field.assign (model);
        hide_button.assign (model);
        eyedropper_button.assign (model);

        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    private void on_model_changed () {
        if (current_state == model.hidden) {
            return;
        }

        if (model.hidden) {
            get_style_context ().add_class ("disabled");
            selectable = false;
        } else {
            get_style_context ().remove_class ("disabled");
            selectable = true;
        }

        current_state = model.hidden;
    }

    private void delete_fill () {
        model.delete ();
        view_canvas.window.main_window.refresh_fills ();
    }
}

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
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private FillItemModel model;

    private Gtk.Button color_button;
    private Akira.Widgets.ColorField field;

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

        color_button = new Gtk.Button () {
            vexpand = true,
            width_request = 40,
            can_focus = false,
            tooltip_text = _("Choose color")
        };
        color_button.get_style_context ().add_class ("selected-color");
        container.add (color_button);

        var eyedropper_button = new Gtk.Button.from_icon_name ("color-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Pick color")
        };
        eyedropper_button.get_style_context ().add_class ("color-picker-button");
        // eyedropper_button.clicked.connect (on_eyedropper_click);

        grid.add (container);
        grid.add (eyedropper_button);

        field = new Akira.Widgets.ColorField (view_canvas);
        grid.add (field);

        add (grid);
    }

    public void assign (FillItemModel data) {
        model_item = data;
        model = (FillItemModel) model_item;

        set_button_color (model.color);
        field.text = Utils.Color.rgba_to_hex_string (model.color);
    }

    private void set_button_color (Gdk.RGBA color) {
        try {
            var provider = new Gtk.CssProvider ();
            var context = color_button.get_style_context ();
            var new_color = color.to_string ();

            var css = """.selected-color {
                    background-color: %s;
                    border-color: shade (%s, 0.75);
                }""".printf (new_color, new_color);

            provider.load_from_data (css, css.length);
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }
}

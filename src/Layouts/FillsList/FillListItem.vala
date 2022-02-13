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
    private FillItemModel model;

    private Gtk.Button color_button;

    construct {
        color_button = new Gtk.Button () {
            vexpand = true,
            width_request = 40,
            can_focus = false,
            tooltip_text = _("Choose color")
        };
        color_button.get_style_context ().add_class ("selected-color");

        add (color_button);
    }

    public void assign (FillItemModel data) {
        model_item = data;
        model = (FillItemModel) model_item;

        set_button_color (model.color);
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

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
 * Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Partials.RoundedColorButton : Gtk.Button {
    public RoundedColorButton (string color) {
        var context = get_style_context ();
        context.add_class ("rounded-color-button");
        context.add_class ("color-item");
        width_request = height_request = 24;
        can_focus = false;
        tooltip_text = _("Apply this color to the current selection");

        try {
            var provider = new Gtk.CssProvider ();
            var css = """.color-item {
                    background-color: %s;
                    border-color: shade (%s, 0.75);
                    border-radius:50%;
                }""".printf (color, color);

            provider.load_from_data (css, css.length);
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }
}

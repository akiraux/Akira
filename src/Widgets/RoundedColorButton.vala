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
 * Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Widgets.RoundedColorButton : Gtk.Grid {
    public signal void set_pattern (Lib.Components.Pattern pattern);

    public RoundedColorButton (Lib.Components.Pattern pattern) {
        var context = get_style_context ();
        context.add_class ("saved-color-button");
        context.add_class ("bg-pattern");
        valign = halign = Gtk.Align.CENTER;

        var btn = new Gtk.Button ();
        var btn_context = btn.get_style_context ();
        btn_context.add_class ("color-item");
        btn.width_request = btn.height_request = 24;
        btn.valign = btn.halign = Gtk.Align.CENTER;
        btn.can_focus = false;
        //  btn.tooltip_text = _("Set color to " + color);

        try {
            var provider = new Gtk.CssProvider ();
            var css_pattern = Utils.Pattern.convert_to_css_linear_gradient (pattern);
            var css = """.color-item {
                    background: %s;
                    border: none;
                }""".printf (css_pattern);

            provider.load_from_data (css, css.length);
            btn_context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }

        // Emit the set_color signal when the button is clicked.
        btn.clicked.connect (() => {
            set_pattern (pattern);
        });

        add (btn);
    }
}

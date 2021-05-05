/*
* Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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
* Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
*/

public class Akira.Partials.RoundedColorButton : Gtk.Button {
    public string background_color;

    public RoundedColorButton (string bg_color) {
        background_color = bg_color;
        can_focus = false;
        width_request = 25;
        height_request = 25;
        add_css ();
        get_style_context ().add_class ("color-item");
        show_all ();
    }

    private void add_css () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = get_style_context ();

            var css = """.color-item {
                    background-color: %s;
                    border-color: white;
                    border-radius:50%;
                }""".printf (background_color, background_color);

            provider.load_from_data (css, css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }
}

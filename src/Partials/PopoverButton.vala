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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Partials.PopoverButton : Gtk.Button {
    public PopoverButton (string text, string[]? accels = null) {
        get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);

        var label = new Gtk.Label (text);
        label.halign = Gtk.Align.START;
        label.hexpand = true;
        label.margin_start = 6;

        var grid = new Gtk.Grid ();
        grid.add (label);

        if (accels != null) {
            var accel_label = new Gtk.Label (Granite.markup_accel_tooltip (accels));
            accel_label.halign = Gtk.Align.END;
            accel_label.margin_end = 6;
            accel_label.use_markup = true;

            grid.add (accel_label);
        }

        add (grid);
    }
}

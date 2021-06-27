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

/*
 * Helper class to quickly create a simple style button with a + icon.
 */
public class Akira.Widgets.AddColorButton : Gtk.Button {
    public AddColorButton () {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        width_request = height_request = 24;
        can_focus = false;
        valign = halign = Gtk.Align.CENTER;
        image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
        tooltip_text = _("Add the current color to the library");
    }
}

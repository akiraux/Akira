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
* Authored by: Bilal Elmoussaoui <bilal.elmoussaoui@gnome.org>
*/


public class Akira.Partials.IconButton: Gtk.Grid {

    private Gtk.Label label_btn;
    public Gtk.Image image;

    public IconButton (string icon_name, string name, string[]? accels = null) {

    }

    public

    private Gtk.Image create_button_image (string icon_name) {
        var size = settings.use_symbolic ? Gtk.IconSize.SMALL_TOOLBAR : Gtk.IconSize.LARGE_TOOLBAR;
        var icon = settings.use_symbolic ? ("%s-symbolic".printf (icon_name)) : icon_name.replace ("-symbolic", "");
        image = new Gtk.Image.from_icon_name (icon_name, size);
        image.margin = 0;
        return image;
    }
}

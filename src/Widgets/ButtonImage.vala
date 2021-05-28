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

public class Akira.Widgets.ButtonImage: Gtk.Image {

    private string icon;
    private Gtk.IconSize size;

    public ButtonImage (string icon_name, Gtk.IconSize icon_size = Gtk.IconSize.LARGE_TOOLBAR) {
        icon = icon_name;
        size = icon_size;
        margin = 0;

        settings.changed["use-symbolic"].connect ( () => {
            update_image ();
        });

        update_image ();
    }

    private void update_image () {
        var size = settings.use_symbolic ? Gtk.IconSize.SMALL_TOOLBAR : size;
        var icon = settings.use_symbolic ? ("%s-symbolic".printf (icon)) : icon.replace ("-symbolic", "");
        set_from_icon_name (icon, size);
    }
}

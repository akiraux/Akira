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

public class Akira.Partials.HeaderBarButton : Gtk.Grid {

    public Gtk.Button button;
    private Gtk.Label label_btn;
    public Akira.Partials.ButtonImage image;

    public HeaderBarButton (string icon_name, string name, string[]? accels = null) {
        label_btn = new Gtk.Label (name);
        label_btn.get_style_context ().add_class ("headerbar-label");

        button = new Gtk.Button ();
        button.can_focus = false;
        button.halign = Gtk.Align.CENTER;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button.tooltip_markup = Granite.markup_accel_tooltip (accels, name);

        image = new ButtonImage (icon_name);
        button.add (image);

        attach (button, 0, 0, 1, 1);
        attach (label_btn, 0, 1, 1, 1);

        valign = Gtk.Align.CENTER;
        udpate_label ();

        settings.changed["show-label"].connect( () => {
            udpate_label ();
        });
    }

    private void udpate_label () {
        label_btn.visible = settings.show_label;
        label_btn.no_show_all = !settings.show_label;
    }
}

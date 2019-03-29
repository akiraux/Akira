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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.FillItem : Gtk.Grid {
    public signal void remove_item (uint index);

    public Gtk.Button remove_btn;

    public Akira.Models.FillsItemModel model { get; construct; }

    public FillItem (Akira.Models.FillsItemModel model) {
        Object(
            model: model
        );
    }

    construct {
        var label = new Gtk.Label ("%d. %s".printf((int) model.index, model.title));

        label.hexpand = true;
        label.halign = Gtk.Align.START;

        remove_btn = new Gtk.Button ();
		remove_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        remove_btn.can_focus = false;

        remove_btn.valign = Gtk.Align.CENTER;
        remove_btn.halign = Gtk.Align.CENTER;

        remove_btn.add (new Gtk.Image.from_icon_name ("list-remove-symbolic",
                                                   Gtk.IconSize.SMALL_TOOLBAR));
        remove_btn.clicked.connect(() => {
            remove_item (model.index);
        });

        attach(label, 0, 0, 1, 1);
        attach(remove_btn, 1, 0, 1, 1);

        show_all ();
    }
}

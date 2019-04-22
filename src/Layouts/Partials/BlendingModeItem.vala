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

public class Akira.Layouts.Partials.BlendingModeItem : Gtk.Label {
    public Akira.Utils.BlendingMode mode { get; construct; }

    public BlendingModeItem (Akira.Utils.BlendingMode mode) {
        Object (
            mode: mode
        );
    }

    construct {
        label = mode.get_name ();
        halign = Gtk.Align.START;

        get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);
    }
}

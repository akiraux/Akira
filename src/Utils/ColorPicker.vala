/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Ivan "isneezy" Vilanculo <vilanculoivan@gmail.com>
*/

public class Akira.Utils.ColorPicker {
    public signal void picked (Gdk.RGBA color);
    private Xdp.Parent parent;
    private Xdp.Portal portal;


    public ColorPicker () {
        Gtk.Application app = (Gtk.Application) GLib.Application.get_default ();
        Gtk.Window window = app.get_active_window ();

        parent = new Xdp.Parent (window);
        portal = new Xdp.Portal ();

        portal.pick_color.begin (parent, null, picked_color);
    }

    public void picked_color (GLib.Object? object, GLib.AsyncResult? result) {
        GLib.Variant v = portal.pick_color_finish (result);
        if (v == null)
            return;

        Gdk.RGBA color = Gdk.RGBA ();
        color.alpha = 1;

        VariantIter iterator = v.iterator ();
        iterator.next ("d", &color.red);
        iterator.next ("d", &color.green);
        iterator.next ("d", &color.blue);

        picked (color);
    }
}

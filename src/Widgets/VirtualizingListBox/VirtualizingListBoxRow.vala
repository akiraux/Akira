/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * Widget component to create a simple listbox row.
 */
public class VirtualizingListBoxRow : Gtk.Bin {
    public bool selectable { get; set; default = true; }
    public weak GLib.Object model_item { get; set; }

    static construct {
        set_css_name ("row");
    }

    construct {
        can_focus = true;
        set_redraw_on_allocate (true);

        get_style_context ().add_class ("activatable");
    }

    public override bool draw (Cairo.Context ct) {
        var sc = this.get_style_context ();
        // TODO: Replace this with fixed height and the width of the layers panel.
        Gtk.Allocation alloc;
        this.get_allocation (out alloc);

        sc.render_background (ct, 0, 0, alloc.width, alloc.height);
        sc.render_frame (ct, 0, 0, alloc.width, alloc.height);

        return base.draw (ct);
    }

    /*
     * Virtual method an implementation of this class can override in case it
     * needs to trigger an edit state and change the UI.
     */
    public virtual void edit () {}
}

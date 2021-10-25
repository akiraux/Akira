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
 * List model to manage all the rows added to the virtual listbox.
 */
public abstract class VirtualizingListBoxModel : GLib.ListModel, GLib.Object {
    private Gee.HashSet<weak GLib.Object> selected_rows = new Gee.HashSet<weak GLib.Object> ();

    public GLib.Type get_item_type () {
        return typeof (GLib.Object);
    }

    public abstract uint get_n_items ();
    public abstract GLib.Object? get_item (uint index);
    public abstract GLib.Object? get_item_unfiltered (uint index);

    public void unselect_all () {
        selected_rows.clear ();
    }

    public void set_item_selected (GLib.Object item, bool selected) {
        if (!selected) {
            selected_rows.remove (item);
        } else {
            selected_rows.add (item);
        }
    }

    public bool get_item_selected (GLib.Object item) {
        return selected_rows.contains (item);
    }

    public Gee.ArrayList<GLib.Object> get_items_between (GLib.Object from, GLib.Object to) {
        var items = new Gee.ArrayList<GLib.Object> ();
        var start_found = false;
        var ignore_next_break = false;
        var length = get_n_items ();
        for (int i = 0; i < length; i++) {
            var item = get_item (i);
            if ((item == from || item == to) && !start_found) {
                start_found = true;
                ignore_next_break = true;
            } else if (!start_found) {
                continue;
            }

            if (item != null) {
                items.add (item);
            }

            if ((item == to || item == from) && !ignore_next_break) {
                break;
            }

            ignore_next_break = false;
        }

        return items;
    }

    public int get_index_of (GLib.Object? item) {
        if (item == null) {
            return -1;
        }

        var length = get_n_items ();
        for (int i = 0; i < length; i++) {
            if (item == get_item (i)) {
                return i;
            }
        }

        return -1;
    }

    public int get_index_of_unfiltered (GLib.Object? item) {
        if (item == null) {
            return -1;
        }

        var length = get_n_items ();
        for (int i = 0; i < length; i++) {
            if (item == get_item_unfiltered (i)) {
                return i;
            }
        }

        return -1;
    }

    public int get_index_of_item_before (GLib.Object item) {
        if (item == get_item (0)) {
            return -1;
        }

        var length = get_n_items ();
        for (int i = 1; i < length; i++) {
            if (get_item (i) == item) {
                if (get_item (i - 1) != null) {
                    return i - 1;
                }
            }
        }

        return -1;
    }

    public int get_index_of_item_after (GLib.Object item) {
        if (item == get_item (get_n_items () - 1)) {
            return -1;
        }

        var length = get_n_items ();
        for (int i = 0; i < length - 1; i++) {
            if (get_item (i) == item) {
                if (get_item (i + 1) != null) {
                    return i + 1;
                }
            }
        }

        return -1;
    }

    public Gee.HashSet<weak GLib.Object> get_selected_rows () {
        return selected_rows;
    }
}

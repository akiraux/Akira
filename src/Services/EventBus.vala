/*
 * Copyright (c) 2018 Alecaddd (http://alecaddd.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

public class Akira.Services.EventBus : Object {
    public signal void update_icons_style ();
    public signal void align_items (string align_action);
    public signal void close_popover (string popover);
    public signal void change_sensitivity (string type);
    public signal void insert_item (string type);
    public signal void selected_items_changed (List<Lib.Models.CanvasItem> selected_items);
    public signal void zoom (double current_scale);
    public signal void request_zoom (string direction);
    public signal void coordinate_change (double x, double y);
    public signal void request_change_cursor (Gdk.CursorType? cursor_type);
    public signal void request_selection_bound_transform (string property, double amount);
    public signal void set_focus_on_canvas ();

    public EventBus () {
        Object ();
    }

    public void emit (string signal_id, string param = "") {
        switch (signal_id) {
            case "update-icons-style":
                update_icons_style ();
                break;

            case "align-items":
                align_items (param);
                break;

            case "close-popover":
                close_popover (param);
                break;

            case "change-sensitivity":
                change_sensitivity (param);
                break;

            case "insert-item":
                insert_item (param);
                break;

            case "request-zoom":
                request_zoom (param);
                break;

        }
    }

    public void test (string caller_id) {
        debug (@"Test from EventBus called by $(caller_id)");
    }
}

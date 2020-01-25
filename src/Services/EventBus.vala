/*
 * Copyright (c) 2019 Alecaddd (https://alecaddd.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
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
    public signal void item_value_changed ();
    public signal void item_coord_changed ();
    public signal void set_focus_on_canvas ();
    public signal void fill_deleted ();
    public signal void border_deleted ();
    public signal void change_z_selected (bool raise, bool total);
    public signal void z_selected_changed ();
    public signal void flip_item (bool clicked, bool vertical = false);
    public signal void move_item_from_canvas (Gdk.EventKey event);
    public signal void request_escape ();
    public signal void request_widget_redraw ();
    public signal void item_inserted (Lib.Models.CanvasItem item);
    public signal void request_delete_item (Lib.Models.CanvasItem item);
    public signal void item_deleted (Lib.Models.CanvasItem item);
    public signal void request_add_item_to_selection (Lib.Models.CanvasItem item);
    public signal void item_locked (Lib.Models.CanvasItem item);
    public signal void hover_over_item (Lib.Models.CanvasItem? item);

    public void test (string caller_id) {
        debug (@"Test from EventBus called by $(caller_id)");
    }
}

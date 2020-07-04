/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
*/

public class Akira.Layouts.RightSideBar : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Akira.Layouts.Partials.LayersPanel layers_panel;
    public Akira.Layouts.Partials.PagesPanel pages_panel;
    public Gtk.ScrolledWindow layers_scroll;
    public Gtk.ScrolledWindow pages_scroll;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    // Drag and Drop properties.
    private Gtk.Revealer motion_revealer;

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

    public RightSideBar (Akira.Window window) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            column_homogeneous: true,
            toggled: true,
            window: window
        );
    }

    construct {
        get_style_context ().add_class ("sidebar-r");
        width_request = 220;

        var pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        pane.expand = true;
        pane.wide_handle = false;
        pane.position = 600;

        layers_panel = new Akira.Layouts.Partials.LayersPanel (window);
        var layers_grid = new Gtk.Grid ();
        layers_grid.vexpand = true;
        layers_grid.add (layers_panel);

        layers_scroll = new Gtk.ScrolledWindow (null, null);
        layers_scroll.expand = true;
        layers_scroll.add (layers_grid);

        var scrolled_child = layers_scroll.get_child ();
        if (scrolled_child is Gtk.Container) {
            ((Gtk.Container) scrolled_child).set_focus_vadjustment (new Gtk.Adjustment (0, 0, 0, 0, 0, 0));
        }

        // Motion revealer for Drag and Drop on the top search bar.
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 2;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var top_panel = new Gtk.Grid ();
        top_panel.attach (build_search_bar (), 0, 0, 1, 1);
        top_panel.attach (motion_revealer, 0, 1, 1, 1);
        top_panel.attach (layers_scroll, 0, 2, 1, 1);

        pane.pack1 (top_panel, false, false);

        pages_panel = new Akira.Layouts.Partials.PagesPanel (window);
        pages_scroll = new Gtk.ScrolledWindow (null, null);
        pages_scroll.expand = true;
        pages_scroll.add (pages_panel);

        attach (pane, 0 , 0 , 1, 1);
    }

    private Gtk.Grid build_search_bar () {
        var search = new Gtk.SearchEntry ();
        search.hexpand = true;
        search.margin = 5;
        search.placeholder_text = _("Search Layer");

        search.focus_in_event.connect (handle_focus_in);
        search.focus_out_event.connect (handle_focus_out);

        search.activate.connect (() => {
            warning ("search");
        });

        var search_grid = new Gtk.Grid ();
        search_grid.get_style_context ().add_class ("border-bottom");
        search_grid.add (search);

        // Build Drag and Drop for layers moving atop the search entry.
        Gtk.drag_dest_set (search, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        search.drag_motion.connect (on_drag_motion);
        search.drag_leave.connect (on_drag_leave);
        search.drag_end.connect (on_drag_end);
        search.drag_data_received.connect (on_drag_data_received);

        // Build Drag and Drop for layers moving atop the search grid.
        Gtk.drag_dest_set (search_grid, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        search_grid.drag_motion.connect (on_drag_motion);
        search_grid.drag_leave.connect (on_drag_leave);
        search_grid.drag_end.connect (on_drag_end);
        search_grid.drag_data_received.connect (on_drag_data_received);

        return search_grid;
    }

    private bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        motion_revealer.reveal_child = true;
        return true;
    }

    private void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private void on_drag_end (Gdk.DragContext context) {
        motion_revealer.reveal_child = true;
    }

    /**
     * Handle the received layer, find the position of the targeted layer and trigger
     * a z-index update.
     */
    private void on_drag_data_received (
        Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data,
        uint target_type, uint time
    ) {
        // This works thanks to on_drag_data_get ().
        var layer = (Akira.Layouts.Partials.Layer) ((Gtk.Widget[]) selection_data.get_data ())[0];
        var artboard = layer.model.artboard;

        // Change artboard if necessary.
        window.items_manager.change_artboard (layer.model, null);

        // If the moved layer had an artboard, no need to do anything else.
        if (artboard != null) {
            return;
        }

        var items_count = (int) window.items_manager.free_items.get_n_items ();
        var pos_source = items_count - 1 - window.items_manager.free_items.index (layer.model);

        // Interrupt if item position doesn't exist.
        if (pos_source == -1) {
            return;
        }

        // z-index is the exact opposite of items placement as the last item
        // is the topmost element. Because of this, we need some trickery to
        // properly handle the list's order.
        var source = items_count - 1 - pos_source;

        // Interrupt if the item was dropped in the same position.
        if (source == 0) {
            debug ("same position");
            return;
        }

        // Remove item at source position.
        var item_to_swap = window.items_manager.free_items.remove_at (source);
        item_to_swap.parent.remove_child (item_to_swap.parent.find_child (item_to_swap));

        // Insert item at target position.
        window.items_manager.free_items.insert_at (0, item_to_swap);
        window.event_bus.z_selected_changed ();

        var root = window.main_window.main_canvas.canvas.get_root_item ();
        // Fetch the new correct position.
        var target = items_count - 1 - window.items_manager.free_items.index (item_to_swap);
        root.add_child (item_to_swap, target);
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        if (!(window is Akira.Window)) {
            return true;
        }
        window.event_bus.disconnect_typing_accel ();

        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        if (!(window is Akira.Window)) {
            return true;
        }
        window.event_bus.connect_typing_accel ();

        return false;
    }

    public void toggle () {
        toggled = !toggled;
    }
}

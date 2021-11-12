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

    private Gtk.TargetList drop_targets { get; set; default = null; }

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 },
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

        drop_targets = new Gtk.TargetList (TARGET_ENTRIES);

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

        window.event_bus.toggle_presentation_mode.connect (toggle);
    }

    private Gtk.Grid build_search_bar () {
        var search = new Gtk.SearchEntry ();
        search.hexpand = true;
        search.margin = 5;
        search.placeholder_text = _("Search Layer");

        search.focus_in_event.connect (handle_focus_in);
        search.focus_out_event.connect (handle_focus_out);

        search.activate.connect (() => {
            print ("search\n");
        });

        var search_grid = new Gtk.Grid ();
        search_grid.get_style_context ().add_class ("border-bottom");
        search_grid.add (search);

        // Build Drag and Drop for items moving atop the search entry.
        Gtk.drag_dest_set (search, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        search.drag_motion.connect (on_drag_motion);
        search.drag_leave.connect (on_drag_leave);
        search.drag_data_received.connect (on_drag_data_received);

        // Build Drag and Drop for items moving atop the search grid.
        Gtk.drag_dest_set (search_grid, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        search_grid.drag_motion.connect (on_drag_motion);
        search_grid.drag_leave.connect (on_drag_leave);
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

    /**
     * Handle the received layer, find the position of the targeted layer and trigger
     * a z-index update.
     */
    private void on_drag_data_received (
        Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data,
        uint target_type, uint time
    ) {
        int items_count, pos_source, source;

        var type = Gtk.drag_dest_find_target (this, context, drop_targets);

        if (type == Gdk.Atom.intern_static_string ("ARTBOARD")) {
            var artboard = (Layouts.Partials.Artboard) (
                (Gtk.Widget[]) selection_data.get_data ()
            )[0];

            items_count = (int) window.items_manager.artboards.get_n_items ();
            pos_source = items_count - 1 - window.items_manager.artboards.index (artboard.model);

            // Interrupt if item position doesn't exist.
            if (pos_source == -1) {
                return;
            }

            // z-index is the exact opposite of items placement as the last item
            // is the topmost element. Because of this, we need some trickery to
            // properly handle the list's order.
            source = items_count - 1 - pos_source;

            // Interrupt if the item was dropped in the same position.
            if (source == 0) {
                debug ("same position");
                return;
            }

            // Swap the position inside the List Model.
            window.items_manager.artboards.swap_items (source, 0);

            // The actual items in the canvas might not match the items in the List Model
            // due to Artboards labels, grids, and other pseudo elements. Therefore we need
            // to get the real position of the child and swap them.
            var root = artboard.model.parent;
            root.move_child (root.find_child (artboard.model), root.get_n_children ());

            window.event_bus.z_selected_changed ();

            return;
        }

        var layer = (Akira.Layouts.Partials.Layer) ((Gtk.Widget[]) selection_data.get_data ())[0];
        var layer_artboard = layer.model.artboard;

        // Change artboard if necessary.
        window.items_manager.change_artboard.begin (layer.model, null);

        // If the moved layer had an artboard, no need to do anything else.
        if (layer_artboard != null) {
            return;
        }

        // Use the existing action to push an item all the way to the top.
        window.event_bus.change_z_selected (true, true);
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

    private void toggle () {
        toggled = !toggled;
    }
}

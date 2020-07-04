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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.LayersPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    private int loop;
    private bool scroll_up = false;
    private bool scrolling = false;
    private bool should_scroll = false;

    public Gtk.Adjustment vadjustment;
    private Gtk.ListBox items_list;
    private Gtk.ListBox artboards_list;

    private const int SCROLL_STEP_SIZE = 5;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 },
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

    public LayersPanel (Akira.Window window) {
        Object (
            window: window,
            vexpand: true,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        expand = true;

        items_list = new Gtk.ListBox ();
        artboards_list = new Gtk.ListBox ();

        items_list.activate_on_single_click = false;
        items_list.selection_mode = Gtk.SelectionMode.SINGLE;

        artboards_list.activate_on_single_click = false;
        artboards_list.selection_mode = Gtk.SelectionMode.SINGLE;

        items_list.bind_model (window.items_manager.free_items, item => {
            var item_model = item as Lib.Models.CanvasItem;
            return new Akira.Layouts.Partials.Layer (window, item_model, items_list);
        });

        artboards_list.bind_model (window.items_manager.artboards, item => {
            var artboard_model = item as Akira.Lib.Models.CanvasArtboard;
            return new Akira.Layouts.Partials.Artboard (window, artboard_model);
        });

        get_style_context ().add_class ("layers-panel");

        attach (items_list, 0, 1);
        attach (artboards_list, 0, 2);

        build_drag_and_drop ();
        redraw_list ();

        window.event_bus.item_inserted.connect (redraw_list);
        window.event_bus.item_deleted.connect (redraw_list);
        window.event_bus.z_selected_changed.connect (redraw_list);
    }

    private void redraw_list () {
        reload_zebra ();
        show_all ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);

        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
        drag_data_received.connect (on_drag_data_received);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        check_scroll (y);

        if (should_scroll && !scrolling) {
            scrolling = true;
            Timeout.add (SCROLL_DELAY, scroll);
        }

        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        should_scroll = false;
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
        debug ("dropped");
    }

    private void check_scroll (int y) {
        vadjustment = window.main_window.right_sidebar.layers_scroll.vadjustment;

        if (vadjustment == null) {
            return;
        }

        double vadjustment_min = vadjustment.value;
        double vadjustment_max = vadjustment.page_size + vadjustment_min;
        double show_min = double.max (0, y - SCROLL_DISTANCE);
        double show_max = double.min (vadjustment.upper, y + SCROLL_DISTANCE);

        if (vadjustment_min > show_min) {
            should_scroll = true;
            scroll_up = true;
        } else if (vadjustment_max < show_max) {
            should_scroll = true;
            scroll_up = false;
        } else {
            should_scroll = false;
        }
    }

    private bool scroll () {
        if (should_scroll) {
            if (scroll_up) {
                vadjustment.value -= SCROLL_STEP_SIZE;
            } else {
                vadjustment.value += SCROLL_STEP_SIZE;
            }
        } else {
            scrolling = false;
        }

        return should_scroll;
    }

    public void reload_zebra () {
        loop = 0;

        items_list.@foreach (row => {
            zebra_layer ((Akira.Layouts.Partials.Layer) row);
        });

        artboards_list.@foreach (row => {
            zebra_artboard ((Akira.Layouts.Partials.Artboard) row);
        });
    }

    private void zebra_artboard (Akira.Layouts.Partials.Artboard artboard) {
        // Handle zebra striped separately for each artboard
        loop = 0;

        artboard.container.foreach (row => {
            if (!(row is Akira.Layouts.Partials.Layer)) {
                return;
            }

            zebra_layer ((Akira.Layouts.Partials.Layer) row);
        });
    }

    private void zebra_layer (Akira.Layouts.Partials.Layer layer) {
        loop++;
        layer.get_style_context ().remove_class ("even");

        if (loop % 2 == 0) {
            layer.get_style_context ().add_class ("even");
        }

        if (layer.grouped) {
            zebra_layer_group (layer);
        }
    }

    private void zebra_layer_group (Akira.Layouts.Partials.Layer layer) {
        bool open = layer.revealer.get_reveal_child ();

        layer.container.foreach (row => {
            if (!(row is Akira.Layouts.Partials.Layer) || !open) {
                return;
            }
            zebra_layer ((Akira.Layouts.Partials.Layer) row);
        });
    }
}

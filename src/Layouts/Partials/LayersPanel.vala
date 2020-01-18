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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.Partials.LayersPanel : Gtk.ListBox {
    public weak Akira.Window window { get; construct; }

    private int loop;
    private bool scroll_up = false;
    private bool scrolling = false;
    private bool should_scroll = false;
    public Gtk.Adjustment vadjustment;

    private const int SCROLL_STEP_SIZE = 5;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;
    public Akira.Layouts.Partials.Artboard artboard;

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
    };

    public LayersPanel (Akira.Window window) {
        Object (
            window: window,
            activate_on_single_click: false,
            selection_mode: Gtk.SelectionMode.SINGLE
        );
    }

    construct {
        get_style_context ().add_class ("layers-panel");
        expand = true;

        build_drag_and_drop ();
        reload_zebra ();

        window.event_bus.item_inserted.connect (on_item_inserted);
        window.event_bus.item_deleted.connect (on_item_deleted);
    }

    private void on_item_inserted (Lib.Models.CanvasItem new_item) {
        var layer = new Akira.Layouts.Partials.Layer (
            window,
            artboard,
            new_item,
            new_item.id,
            new_item.LAYER_ICON,
            false
        );

        insert (layer, 0);
        show_all ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);

        drag_data_received.connect (on_drag_data_received);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data,
        uint target_type, uint time) {
        Akira.Layouts.Partials.Artboard target;
        Gtk.Widget row;
        Akira.Layouts.Partials.Artboard source;
        int new_position;

        target = (Akira.Layouts.Partials.Artboard) get_row_at_y (y);

        if (target == null) {
            new_position = -1;
        } else {
            new_position = target.get_index ();
        }

        row = ((Gtk.Widget[]) selection_data.get_data ())[0];

        source = (Akira.Layouts.Partials.Artboard) row.get_ancestor (typeof (Akira.Layouts.Partials.Artboard));

        if (source == target) {
            return;
        }

        remove (source);
        insert (source, new_position);
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        //  var row = (Akira.Layouts.Partials.Artboard) get_row_at_y (y);

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

        @foreach (row => {
            if (!(row is Akira.Layouts.Partials.Artboard)) {
                return;
            }
            zebra_artboard ((Akira.Layouts.Partials.Artboard) row);
        });
    }

    private void zebra_artboard (Akira.Layouts.Partials.Artboard artboard) {
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

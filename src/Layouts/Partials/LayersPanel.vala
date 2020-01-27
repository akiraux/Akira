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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.LayersPanel : Gtk.ListBox {
    public weak Akira.Window window { get; construct; }

    private int loop;
    private bool scroll_up = false;
    private bool scrolling = false;
    private bool should_scroll = false;
    private string current_selected_item_id;

    private Akira.Models.ListModel list_model;
    private Gee.HashMap<string, Akira.Models.LayerModel> item_model_map;
    public Gtk.Adjustment vadjustment;

    private const int SCROLL_STEP_SIZE = 5;
    private const int SCROLL_DISTANCE = 30;
    private const int SCROLL_DELAY = 50;

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

        list_model = new Akira.Models.ListModel ();
        item_model_map = new Gee.HashMap<string, Akira.Models.LayerModel> ();

        bind_model (list_model, item => {
            // TODO: Differentiate between layer and artboard
            // based upon item "type" of some sort
            return new Akira.Layouts.Partials.Layer (window, (Akira.Models.LayerModel) item);
        });

        build_drag_and_drop ();
        reload_zebra ();

        window.event_bus.item_inserted.connect (on_item_inserted);
        window.event_bus.item_deleted.connect (on_item_deleted);
        window.event_bus.selected_items_changed.connect (on_selected_items_changed);
        window.event_bus.z_selected_changed.connect (on_z_selected_changed);

        set_sort_func (sort_by_z_index);
    }

    private int sort_by_z_index (Gtk.ListBoxRow a, Gtk.ListBoxRow b) {
        var row_a = a as Akira.Layouts.Partials.Layer;
        var row_b = b as Akira.Layouts.Partials.Layer;

        if (row_a != null && row_b != null) {
            return row_a.model.item.z_index - row_b.model.item.z_index;
        }

        return 0;
    }

    private void on_item_inserted (Lib.Models.CanvasItem new_item) {
        var model = new Akira.Models.LayerModel (new_item, list_model);
        list_model.add_item.begin (model);

        // This map is necessary for easily knowing which
        // item is related to which model, since the canvas knows only
        // real items and the layers panel only knows items model
        item_model_map.@set (new_item.id, model);

        reload_zebra ();

        show_all ();
    }

    private void on_item_deleted (Lib.Models.CanvasItem item) {
        var model = item_model_map.@get (item.id);

        list_model.remove_item.begin (model);

        reload_zebra ();
    }

    private void on_selected_items_changed (List<Lib.Models.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            var current_selected_item = item_model_map.@get (current_selected_item_id);

            if (current_selected_item != null) {
                current_selected_item.selected = false;
            }

            current_selected_item_id = null;
            return;
        }

        var selected_item = selected_items.nth_data (0);

        if (selected_item.id == current_selected_item_id) {
            return;
        }

        var new_selected_model = item_model_map.@get (selected_item.id);

        if (new_selected_model != null) {
            new_selected_model.selected = true;
        }

        var current_selected_model = item_model_map.@get (current_selected_item_id);

        if (current_selected_model != null) {
            current_selected_model.selected = false;
        }

        current_selected_item_id = selected_item.id;

        // After activating a row it is necessary to
        // put (keyboard) focus back to the canvas
        window.event_bus.set_focus_on_canvas ();
    }

    private void on_z_selected_changed () {
        debug ("On z-selected-changed");

        var n_items = list_model.get_n_items ();
        for (int i = 0; i < n_items; i++) {
            var layer = list_model.get_item (i) as Akira.Models.LayerModel;
            if (layer != null) {
                Lib.Models.CanvasItem.update_z_index (layer.item);
            }
        }

        invalidate_sort ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES, Gdk.DragAction.MOVE);

        drag_data_received.connect (on_drag_data_received);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type, uint time) {
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
                zebra_layer ((Akira.Layouts.Partials.Layer) row);
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

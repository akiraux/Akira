/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Widget component to create a simple non scrollable listbox view with a
 * factory method to assign a model to a reusable widget.
 */
public class VirtualizingSimpleListBox : Gtk.Container {
    public delegate VirtualizingListBoxRow RowFactoryMethod (GLib.Object item, VirtualizingListBoxRow? old_widget);

    public RowFactoryMethod factory_func;

    private VirtualizingListBoxModel? _model;
    public VirtualizingListBoxModel? model {
        get {
           return _model;
        }
        set {
            if (_model != null) {
                _model.items_changed.disconnect (on_items_changed);
            }

            _model = value;
            _model.items_changed.connect (on_items_changed);
            queue_resize ();
        }
    }

    // The default height of a row, used to trigger an initial scroll adjustment.
    private double? default_widget_height = null;

    private Gee.ArrayList<VirtualizingListBoxRow> current_widgets = new Gee.ArrayList<VirtualizingListBoxRow> ();
    private Gee.ArrayList<VirtualizingListBoxRow> recycled_widgets = new Gee.ArrayList<VirtualizingListBoxRow> ();
    private Gdk.Window bin_window;
    private uint shown;

    static construct {
        set_css_name ("list");
    }

    construct {
        margin_top = margin_bottom = 6;
    }

    public override void realize () {
        set_realized (true);
        Gtk.Allocation allocation;
        get_allocation (out allocation);

        var attr = Gdk.WindowAttr ();
        attr.x = allocation.x;
        attr.y = allocation.y;
        attr.width = allocation.width;
        attr.height = allocation.height;
        attr.window_type = Gdk.WindowType.CHILD;
        attr.event_mask = Gdk.EventMask.ALL_EVENTS_MASK;
        attr.wclass = Gdk.WindowWindowClass.INPUT_OUTPUT;
        attr.visual = get_visual ();

        Gdk.WindowAttributesType attr_types;
        attr_types = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y | Gdk.WindowAttributesType.VISUAL;

        var window = new Gdk.Window (get_parent_window (), attr, attr_types);

        set_window (window);
        register_window (window);

        attr.height = 1;
        vexpand = false;
        bin_window = new Gdk.Window (window, attr, attr_types);
        register_window (bin_window);
        bin_window.show ();
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        set_allocation (allocation);
        position_children ();

        if (get_realized ()) {
            get_window ().move_resize (allocation.x, allocation.y, allocation.width, allocation.height);
            update_bin_window ();
        }
    }

    public override void map () {
        base.map ();
        ensure_visible_widgets ();
    }

    public override void remove (Gtk.Widget w) {
        assert (w.get_parent () == this);
    }

    public override void forall_internal (bool include_internals, Gtk.Callback callback) {
        foreach (var child in current_widgets) {
            callback (child);
        }
    }

    public override GLib.Type child_type () {
        return typeof (VirtualizingListBoxRow);
    }

    private VirtualizingListBoxRow? get_widget (uint index) {
        var item = model.get_object (index);
        if (item == null) {
            return null;
        }

        VirtualizingListBoxRow? old_widget = null;
        if (recycled_widgets.size > 0) {
            old_widget = recycled_widgets[recycled_widgets.size - 1];
            recycled_widgets.remove (old_widget);
        }

        VirtualizingListBoxRow new_widget = factory_func (item, old_widget);
        if (model.get_item_selected (item)) {
            new_widget.set_state_flags (Gtk.StateFlags.SELECTED, false);
        } else {
            new_widget.unset_state_flags (Gtk.StateFlags.SELECTED);
        }

        new_widget.model_item = item;
        new_widget.show ();

        return new_widget;
    }

    private void on_items_changed (uint position, uint removed, uint added) {
        remove_all_widgets ();
        shown = 0;
        update_bin_window ();
        ensure_visible_widgets ();
        queue_resize ();
    }

    private int get_widget_height (Gtk.Widget w) {
        if (default_widget_height != null) {
            return (int) default_widget_height;
        }

        int min;
        w.get_preferred_height_for_width (get_allocated_width (), out min, null);

        // Store the height of a row widget as soon as we fetch the first one.
        if (default_widget_height == null) {
            default_widget_height = min;
        }
        return min;
    }

    private void position_children () {
        Gtk.Allocation allocation;
        Gtk.Allocation child_allocation = {0};

        get_allocation (out allocation);

        int y = 0;
        child_allocation.x = 0;
        if (allocation.width > 0) {
            child_allocation.width = allocation.width;
        } else {
            child_allocation.width = 1;
        }

        int? child_width = null;
        var box_width = get_allocated_width ();

        foreach (var child in current_widgets) {
            // Get the height of the row widget, which we won't fetch every time
            // if we already did it one.
            child_allocation.height = get_widget_height (child);

            // If the child_width is not defined, get it the first time. All other
            // widgets will always have the same width.
            if (child_width == null) {
                child.get_preferred_width_for_height (child_allocation.height, out child_width, null);
            }

            child_allocation.width = int.max (child_width, box_width);
            child_allocation.y = y;
            child.size_allocate (child_allocation);

            y += child_allocation.height;
        }
    }

    private void update_bin_window (int new_bin_height = -1) {
        Gtk.Allocation allocation;
        get_allocation (out allocation);

        var h = 1;
        foreach (var w in current_widgets) {
            h += get_widget_height (w);
        }

        bin_window.move_resize (0, 0, allocation.width, h);
        height_request = h;
    }

    private void remove_all_widgets () {
        foreach (var w in current_widgets) {
            w.unparent ();
        }

        recycled_widgets.add_all (current_widgets);
        current_widgets.clear ();
    }

    private void insert_child_internal (VirtualizingListBoxRow widget, int index) {
        widget.set_parent_window (bin_window);
        widget.set_parent (this);
        current_widgets.insert (index, widget);
    }

    private void insert_widgets (ref int bin_height) {
        while (shown < model.get_n_items ()) {
            var new_widget = get_widget (shown);
            if (new_widget == null) {
                shown++;
                continue;
            }

            insert_child_internal (new_widget, current_widgets.size);

            int min = get_widget_height (new_widget);
            bin_height += min;
            shown++;
        }
    }

    private void ensure_visible_widgets () {
        if (!get_mapped () || model == null) {
            return;
        }

        var bin_height = bin_window.get_height ();
        insert_widgets (ref bin_height);
        update_bin_window (bin_height);
        position_children ();
        queue_draw ();
    }

    public unowned VirtualizingListBoxRow? get_row_at_y (int y) {
        Gtk.Allocation alloc;
        foreach (var row in current_widgets) {
            row.get_allocation (out alloc);
            if (y >= alloc.y && y <= alloc.y + alloc.height) {
                unowned VirtualizingListBoxRow return_value = row;
                return return_value;
            }
        }

        return null;
    }

    public bool get_border (out Gtk.Border border) {
        border = Gtk.Border ();
        return false;
    }

    public Gee.HashSet<weak GLib.Object> get_selected_rows () {
        return model.get_selected_rows ();
    }
}

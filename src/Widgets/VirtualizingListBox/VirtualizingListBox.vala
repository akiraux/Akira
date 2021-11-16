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
 * Widget component to create a scrollable listbox view.
 */
public class VirtualizingListBox : Gtk.Container, Gtk.Scrollable {
    public delegate VirtualizingListBoxRow RowFactoryMethod (GLib.Object item, VirtualizingListBoxRow? old_widget);

    public RowFactoryMethod factory_func;

    public signal void row_activated (GLib.Object row);

    // Signal triggered when the selection of the rows changes only after a pressed
    // event. The bool `clear` is set to true only when all rows have been
    // deselected.It's up to the implementation widget to fetch the currently
    // selected rows to update the UI.
    public signal void row_selection_changed (bool clear = false);

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

    private Gtk.Adjustment? _vadjustment;
    public Gtk.Adjustment? vadjustment {
        set {
            if (_vadjustment != null) {
                _vadjustment.value_changed.disconnect (on_adjustment_value_changed);
                _vadjustment.notify["page-size"].disconnect (on_adjustment_page_size_changed);
            }

            _vadjustment = value;
            if (_vadjustment != null) {
                _vadjustment.value_changed.connect (on_adjustment_value_changed);
                _vadjustment.notify["page-size"].connect (on_adjustment_page_size_changed);
                configure_adjustment ();
            }
        }
        get {
            return _vadjustment;
        }
    }

    private int bin_y {
        get {
            int y = 0;
            if (vadjustment != null) {
                y = -(int)vadjustment.value; //vala-lint=space-before-paren
            }

            return y + (int)bin_y_diff;
        }
    }

    private bool bin_window_full {
        get {
            int bin_height = 0;
            if (get_realized ()) {
                bin_height = bin_window.get_height ();
            }

            var widget_height = get_allocated_height ();
            return (bin_y + bin_height > widget_height) || (shown_to - shown_from == model.get_n_items ());
        }
    }

    // The default height of a row, used to trigger an initial scroll adjustment.
    private double? default_widget_height = null;

    public VirtualizingListBoxRow? selected_row_widget {
        get {
            var item = selected_row;

            foreach (var child in current_widgets) {
                if (child.model_item == item) {
                    return (VirtualizingListBoxRow)child;
                }
            }

            return null;
        }
    }

    public Gtk.Adjustment hadjustment { get; set; }
    public Gtk.ScrollablePolicy hscroll_policy { get; set; }
    public Gtk.ScrollablePolicy vscroll_policy { get; set; }
    public bool activate_on_single_click { get; set; }
    public Gtk.SelectionMode selection_mode { get; set; default = Gtk.SelectionMode.MULTIPLE; }
    private double bin_y_diff { get; private set; }
    public GLib.Object selected_row { get; private set; }

    private Gee.ArrayList<VirtualizingListBoxRow> current_widgets = new Gee.ArrayList<VirtualizingListBoxRow> ();
    private Gee.ArrayList<VirtualizingListBoxRow> recycled_widgets = new Gee.ArrayList<VirtualizingListBoxRow> ();
    private Gdk.Window bin_window;
    private uint shown_to;
    private uint shown_from;
    private bool block;
    private int last_valid_widget_height = 1;
    private VirtualizingListBoxRow? active_row;
    private Gtk.GestureMultiPress multipress;

    static construct {
        set_css_name ("list");
    }

    construct {
        multipress = new Gtk.GestureMultiPress (this);
        multipress.set_propagation_phase (Gtk.PropagationPhase.BUBBLE);
        multipress.touch_only = false;
        multipress.button = Gdk.BUTTON_PRIMARY;
        multipress.pressed.connect (on_multipress_pressed);
        multipress.released.connect (on_multipress_released);
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
        bin_window = new Gdk.Window (window, attr, attr_types);
        register_window (bin_window);
        bin_window.show ();
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        bool height_changed = allocation.height != get_allocated_height ();
        bool width_changed = allocation.width != get_allocated_width ();
        set_allocation (allocation);
        position_children ();

        if (get_realized ()) {
            get_window ().move_resize (allocation.x,
                                       allocation.y,
                                       allocation.width,
                                       allocation.height);
            update_bin_window ();
        }

        if (vadjustment != null && height_changed || width_changed) {
            configure_adjustment ();
        }

        if (height_changed || width_changed) {
            ensure_visible_widgets ();
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
        print ("on_items_changed\n");
        if (position >= shown_to && bin_window_full) {
            if (vadjustment == null) {
                queue_resize ();
            } else {
                configure_adjustment ();
            }

            return;
        }

        remove_all_widgets ();
        shown_to = shown_from;
        update_bin_window ();
        ensure_visible_widgets (true);

        if (vadjustment == null) {
            queue_resize ();
        }
    }

    private inline int widget_y (int index) {
        int y = 0;
        for (int i = 0; i < index; i ++) {
            y += get_widget_height (current_widgets[i]);
        }

        return y;
    }

    private int get_widget_height (Gtk.Widget w) {
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
        if (vadjustment != null) {
            y = allocation.y;
        }

        child_allocation.x = 0;
        if (allocation.width > 0) {
            child_allocation.width = allocation.width;
        } else {
            child_allocation.width = 1;
        }

        foreach (var child in current_widgets) {
            child.get_preferred_height_for_width (get_allocated_width (), out child_allocation.height, null);
            child.get_preferred_width_for_height (child_allocation.height, out child_allocation.width, null);
            child_allocation.width = int.max (child_allocation.width, get_allocated_width ());
            child_allocation.y = y;
            child.size_allocate (child_allocation);

            y += child_allocation.height;
        }
    }

    private void update_bin_window (int new_bin_height = -1) {
        Gtk.Allocation allocation;
        get_allocation (out allocation);

        var h = (new_bin_height == -1 ? 0 : new_bin_height);

        if (new_bin_height == -1) {
            foreach (var w in current_widgets) {
                h += get_widget_height (w);
            }
        }

        if (h == 0) {
            h = 1;
        }

        if (h != bin_window.get_height () || allocation.width != bin_window.get_width ()) {
            bin_window.move_resize (0, bin_y, allocation.width, h);
        } else {
            bin_window.move (0, bin_y);
        }
    }

    private void remove_all_widgets () {
        foreach (var w in current_widgets) {
            w.unparent ();
        }

        recycled_widgets.add_all (current_widgets);
        current_widgets.clear ();
    }

    private void remove_child_internal (VirtualizingListBoxRow widget) {
        current_widgets.remove (widget);
        widget.set_state_flags (Gtk.StateFlags.NORMAL, true);
        widget.unparent ();
        recycled_widgets.add (widget);
    }

    private void on_adjustment_value_changed () {
        ensure_visible_widgets ();
    }

    private void on_adjustment_page_size_changed () {
        if (!get_mapped ()) {
            return;
        }

        double max_value = vadjustment.upper - vadjustment.page_size;

        if (vadjustment.value > max_value) {
            set_value (max_value);
        }

        configure_adjustment ();
    }

    private void insert_child_internal (VirtualizingListBoxRow widget, int index) {
        widget.set_parent_window (bin_window);
        widget.set_parent (this);
        current_widgets.insert (index, widget);
    }

    private bool remove_top_widgets (ref int bin_height) {
        bool removed = false;
        for (int i = 0; i < current_widgets.size; i++) {
            var w = current_widgets[i];
            int w_height = get_widget_height (w);
            if (bin_y + widget_y (i) + w_height < 0) {
                bin_y_diff += w_height;
                bin_height -= w_height;
                remove_child_internal (w);
                shown_from++;
                removed = true;
            } else {
                break;
            }
        }

        return removed;
    }

    private bool insert_top_widgets (ref int bin_height) {
        bool added = false;
        while (shown_from > 0 && bin_y >= 0) {
            shown_from--;
            var new_widget = get_widget (shown_from);
            if (new_widget == null) {
                continue;
            }

            insert_child_internal (new_widget, 0);
            var min = get_widget_height (new_widget);

            bin_y_diff -= min;
            bin_height += min;
            added = true;
        }

        if (bin_y > 0) {
            bin_y_diff = 0;
            block = true;
            set_value (0.0);
            block = false;
        }

        return added;
    }

    private bool remove_bottom_widgets (ref int bin_height) {
        for (int i = current_widgets.size - 1; i >= 0; i--) {
            var w = current_widgets[i];

            int widget_y = bin_y + widget_y (i);
            if (widget_y > get_allocated_height ()) {
                int w_height = get_widget_height (w);
                remove_child_internal (w);
                bin_height -= w_height;
                shown_to--;
            } else {
                break;
            }
        }

        return false;
    }

    private bool insert_bottom_widgets (ref int bin_height) {
        bool added = false;
        while (bin_y + bin_height <= get_allocated_height () && shown_to < model.get_n_items ()) {
            var new_widget = get_widget (shown_to);
            if (new_widget == null) {
                shown_to++;
                continue;
            }

            insert_child_internal (new_widget, current_widgets.size);

            int min = get_widget_height (new_widget);
            bin_height += min;
            added = true;
            shown_to ++;
        }

        return added;
    }

    private void ensure_visible_widgets (bool model_changed = false) {
        if (!get_mapped () || model == null || block) {
            return;
        }

        var widget_height = get_allocated_height ();
        var bin_height = bin_window.get_height ();
        if (bin_height == 1) {
            bin_height = 0;
        }

        if (bin_y + bin_height < 0 || bin_y >= widget_height) {
            int estimated_widget_height = estimated_widget_height ();

            remove_all_widgets ();
            bin_height = 0;

            double percentage = vadjustment.value / vadjustment.upper;
            uint top_widget_index = (uint)(model.get_n_items () * percentage);

            if (top_widget_index > model.get_n_items ()) {
                shown_to = model.get_n_items ();
                shown_from = model.get_n_items ();
                bin_y_diff = vadjustment.value + vadjustment.page_size;
            } else {
                shown_from = top_widget_index;
                shown_to = top_widget_index;
                bin_y_diff = top_widget_index * estimated_widget_height;
            }
        }

        var top_removed = remove_top_widgets (ref bin_height);
        var top_added = insert_top_widgets (ref bin_height);
        var bottom_removed = remove_bottom_widgets (ref bin_height);
        var bottom_added = insert_bottom_widgets (ref bin_height);

        var widgets_changed = top_removed || top_added || bottom_removed || bottom_added || model_changed;

        if (vadjustment != null && widgets_changed) {
            uint top_part;
            uint widget_part;
            uint bottom_part;

            uint new_upper = estimated_list_height (out top_part, out bottom_part, out widget_part);

            if (new_upper > _vadjustment.upper) {
                bin_y_diff = double.max (top_part, vadjustment.value);
            } else {
                bin_y_diff = double.min (top_part, vadjustment.value);
            }

            configure_adjustment ();

            set_value (bin_y_diff - bin_y);
            if (vadjustment.value < bin_y_diff) {
                set_value (bin_y_diff);
            }

            if (bin_y > 0) {
                bin_y_diff = vadjustment.value;
            }
        }

        configure_adjustment ();
        update_bin_window (bin_height);
        position_children ();
        queue_draw ();

        // print ("ensure_visible_widgets\n");
    }

    private int estimated_widget_height () {
        int average_widget_height = 0;
        int used_widgets = 0;

        foreach (var w in current_widgets) {
            if (w.visible) {
                average_widget_height += get_widget_height (w);
                used_widgets ++;
            }
        }

        if (used_widgets > 0) {
            average_widget_height /= used_widgets;
        } else {
            average_widget_height = last_valid_widget_height;
        }

        last_valid_widget_height = average_widget_height;

        return average_widget_height;
    }

    private void configure_adjustment () {
        int widget_height = get_allocated_height ();
        uint list_height = estimated_list_height ();

        if ((int)vadjustment.upper != uint.max (list_height, widget_height)) {
            vadjustment.upper = uint.max (list_height, widget_height);
        } else if (list_height == 0) {
            vadjustment.upper = widget_height;
        }

        if ((int)vadjustment.page_size != widget_height) {
            vadjustment.page_size = widget_height;
        }

        if (vadjustment.value > vadjustment.upper - vadjustment.page_size) {
            double v = vadjustment.upper - vadjustment.page_size;
            set_value (v);
        }
    }

    private void set_value (double v) {
        if (v == vadjustment.value) {
            return;
        }

        block = true;
        vadjustment.value = v;
        block = false;
    }

    private uint estimated_list_height (out uint top = null, out uint bottom = null, out uint visible_widgets = null) {
        if (model == null) {
            top = 0;
            bottom = 0;
            visible_widgets = 0;
            return 0;
        }

        int widget_height = estimated_widget_height ();
        uint top_widgets = shown_from;
        uint bottom_widgets = model.get_n_items () - shown_to;

        int exact_height = 0;
        foreach (var w in current_widgets) {
            int h = get_widget_height (w);
            exact_height += h;
        }

        top = top_widgets * widget_height;
        bottom = bottom_widgets * widget_height;
        visible_widgets = exact_height;

        uint h = top + bottom + visible_widgets;
        return h;
    }

    public unowned VirtualizingListBoxRow? get_row_at_y (int y) {
        Gtk.Allocation alloc;
        foreach (var row in current_widgets) {
            row.get_allocation (out alloc);
            if (y >= alloc.y + bin_y && y <= alloc.y + bin_y + alloc.height) {
                unowned VirtualizingListBoxRow return_value = row;
                return return_value;
            }
        }

        return null;
    }

    private void on_multipress_pressed (int n_press, double x, double y) {
        active_row = null;
        var row = get_row_at_y ((int)y);
        if (row != null && row.sensitive) {
            active_row = row;
            row.set_state_flags (Gtk.StateFlags.ACTIVE, false);

            if (n_press == 2 && !activate_on_single_click) {
                row_activated (row.model_item);
            }
        }
    }

    private void get_current_selection_modifiers (out bool modify, out bool extend) {
        Gdk.ModifierType state;
        Gdk.ModifierType mask;

        modify = false;
        extend = false;

        if (Gtk.get_current_event_state (out state)) {
            mask = get_modifier_mask (Gdk.ModifierIntent.MODIFY_SELECTION);
            if ((state & mask) == mask) {
                modify = true;
            }

            mask = get_modifier_mask (Gdk.ModifierIntent.EXTEND_SELECTION);
            if ((state & mask) == mask) {
                extend = true;
            }
        }
    }

    private void on_multipress_released (int n_press, double x, double y) {
        if (active_row == null) {
            unselect_all_internal ();
            row_selection_changed (true);
            return;
        }

        active_row.unset_state_flags (Gtk.StateFlags.ACTIVE);

        bool modify, extend;
        get_current_selection_modifiers (out modify, out extend);
        var sequence = multipress.get_current_sequence ();
        var event = multipress.get_last_event (sequence);
        var source = event.get_source_device ().get_source ();

        if (source == Gdk.InputSource.TOUCHSCREEN) {
            modify = !modify;
        }

        update_selection (active_row, modify, extend);
        row_selection_changed ();
    }

    private void update_selection (VirtualizingListBoxRow row, bool modify, bool extend) {
        if (selection_mode == Gtk.SelectionMode.NONE || !row.selectable) {
            return;
        }

        if (selection_mode == Gtk.SelectionMode.BROWSE) {
            select_row (row);
        } else if (selection_mode == Gtk.SelectionMode.SINGLE) {
            var was_selected = model.get_item_selected (row.model_item);
            unselect_all_internal ();
            var select = modify ? !was_selected : true;
            model.set_item_selected (row.model_item, select);
            selected_row = select ? row.model_item : null;
            if (select) {
                row.set_state_flags (Gtk.StateFlags.SELECTED, false);
            } else {
                row.unset_state_flags (Gtk.StateFlags.SELECTED);
            }
        } else {
            if (extend) {
                var selected = selected_row;
                unselect_all_internal ();
                if (selected == null) {
                    select_row (row);
                } else {
                    select_all_between (selected, row.model_item, false);
                }
            } else {
                if (modify) {
                    var selected = model.get_item_selected (row.model_item);
                    if (selected) {
                        row.unset_state_flags (Gtk.StateFlags.SELECTED);
                    } else {
                        row.set_state_flags (Gtk.StateFlags.SELECTED, false);
                    }

                    model.set_item_selected (row.model_item, !selected);
                } else {
                    unselect_all_internal ();
                    select_row (row);
                }
            }
        }
    }

    private void select_all_between (GLib.Object from, GLib.Object to, bool modify) {
        var items = model.get_items_between (from, to);
        foreach (var item in items) {
            model.set_item_selected (item, true);
        }

        foreach (VirtualizingListBoxRow row in current_widgets) {
            if (row.model_item in items) {
                row.set_state_flags (Gtk.StateFlags.SELECTED, false);
            }
        }
    }

    protected void select_row_at_index (int index) {
        var row = ensure_index_visible (index);

        if (row != null) {
            select_and_activate (row);
        }
    }

    private void select_and_activate (VirtualizingListBoxRow row) {
        select_row (row);
        row_activated (row.model_item);
    }

    private VirtualizingListBoxRow? ensure_index_visible (int index) {
        var index_max = model.get_n_items () - 1;

        if (index < 0) {
            return null;
        }

        if (index > index_max) {
            return null;
        }

        if (index == 0) {
            set_value (0.0);
            ensure_visible_widgets ();
            foreach (VirtualizingListBoxRow row in current_widgets) {
                if (index == model.get_index_of (row.model_item)) {
                    return row;
                }
            }
        }

        if (index == index_max) {
            set_value (vadjustment.upper);
            ensure_visible_widgets ();
            foreach (VirtualizingListBoxRow row in current_widgets) {
                if (index == model.get_index_of (row.model_item)) {
                    return row;
                }
            }
        }

        while (index <= shown_from) {
            vadjustment.value--;
            // ensure_visible_widgets ();
        }

        while (index + 1 >= shown_to) {
            vadjustment.value++;
            // ensure_visible_widgets ();
        }

        foreach (VirtualizingListBoxRow row in current_widgets) {
            if (index == model.get_index_of (row.model_item)) {
                return row;
            }
        }

        return null;
    }

    protected void select_row (VirtualizingListBoxRow row) {
        if (model.get_item_selected (row) || selection_mode == Gtk.SelectionMode.NONE) {
            return;
        }

        if (selection_mode != Gtk.SelectionMode.MULTIPLE) {
            unselect_all_internal ();
        }

        model.set_item_selected (row.model_item, true);
        row.set_state_flags (Gtk.StateFlags.SELECTED, false);
        selected_row = row.model_item;
    }

    protected void unselect_all () {
        unselect_all_internal ();
    }

    private bool unselect_all_internal () {
        if (selection_mode == Gtk.SelectionMode.NONE) {
            return false;
        }

        foreach (var row in current_widgets) {
            row.unset_state_flags (Gtk.StateFlags.SELECTED);
        }

        model.unselect_all ();
        selected_row = null;

        return true;
    }

    public override bool focus (Gtk.DirectionType direction) {
        var focus_child = get_focus_child () as VirtualizingListBoxRow;
        int next_focus_index = -1;

        if (focus_child != null && focus_child.model_item != null) {
            if (focus_child.child_focus (direction)) {
                return true;
            }

            if (direction == Gtk.DirectionType.UP || direction == Gtk.DirectionType.TAB_BACKWARD) {
                next_focus_index = model.get_index_of_item_before (focus_child.model_item);
            } else if (direction == Gtk.DirectionType.DOWN || direction == Gtk.DirectionType.TAB_FORWARD) {
                next_focus_index = model.get_index_of_item_after (focus_child.model_item);
            }
        } else {
            if (direction == Gtk.DirectionType.UP || direction == Gtk.DirectionType.TAB_BACKWARD) {
                next_focus_index = model.get_index_of (focus_child.model_item);
                if (next_focus_index == -1) {
                    next_focus_index = (int)model.get_n_items () - 1;
                }
            } else {
                next_focus_index = model.get_index_of (focus_child);
                if (next_focus_index == -1) {
                    next_focus_index = 0;
                }
            }
        }

        if (next_focus_index == -1) {
            if (keynav_failed (direction)) {
                return true;
            }

            return false;
        }

        var widget = ensure_index_visible (next_focus_index);
        if (widget != null) {
            update_selection (widget, false, false);
            return true;
        }

        return false;
    }

    public bool get_border (out Gtk.Border border) {
        border = Gtk.Border ();
        return false;
    }

    public Gee.HashSet<weak GLib.Object> get_selected_rows () {
        return model.get_selected_rows ();
    }
}

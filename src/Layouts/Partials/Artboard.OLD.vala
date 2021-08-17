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

public class Akira.Layouts.Partials.Artboard : Gtk.ListBoxRow {
    public weak Akira.Window window { get; construct; }

    private Gtk.TargetList drop_targets { get; set; default = null; }

    private const Gtk.TargetEntry ARTBOARD_ENTRY[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
    };

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 },
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

    private Gtk.Grid artboard_handle;
    public Gtk.Label label;
    public Gtk.Entry entry;
    public Gtk.EventBox handle;
    public Gtk.Image icon_locked;
    public Gtk.Image icon_unlocked;
    public Gtk.Image icon_hidden;
    public Gtk.Image icon_visible;
    public Gtk.ToggleButton button_locked;
    public Gtk.ToggleButton button_hidden;
    public Gtk.ToggleButton button;
    public Gtk.Image button_icon;
    public Gtk.Revealer revealer;
    public Gtk.ListBox container;

    public Akira.Lib.Items.CanvasArtboard model { get; construct; }

    // Drag and Drop properties.
    private Gtk.Revealer motion_revealer;
    public Gtk.Revealer motion_artboard_revealer;

    private bool _editing;
    public bool editing {
        get { return _editing; } set { _editing = value; }
    }

    public Artboard (Akira.Window window, Akira.Lib.Items.CanvasArtboard model) {
        Object (
            window: window,
            model: model
        );
    }

    construct {
        get_style_context ().add_class ("artboard");
        drop_targets = new Gtk.TargetList (TARGET_ENTRIES);

        label = new Gtk.Label ("");
        label.get_style_context ().add_class ("artboard-name");
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        model.name.bind_property ("name", label, "label",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        entry = new Gtk.Entry ();
        entry.margin_top = entry.margin_bottom = 2;
        entry.margin_start = 6;
        entry.expand = true;
        entry.visible = false;
        entry.no_show_all = true;
        // NOTE: We can't bind the entry to the model.name otherwise we won't be
        // able to handle the ESC key to restore the previous entry.
        entry.text = model.name.name;

        entry.activate.connect (update_on_enter);
        entry.key_release_event.connect (update_on_escape);
        entry.focus_in_event.connect (handle_focus_in);
        entry.focus_out_event.connect (update_on_leave);

        var label_grid = new Gtk.Grid ();
        label_grid.expand = true;
        label_grid.attach (label, 0, 0, 1, 1);
        label_grid.attach (entry, 1, 0, 1, 1);

        revealer = new Gtk.Revealer ();
        revealer.hexpand = true;
        revealer.reveal_child = true;

        container = new Gtk.ListBox ();
        container.get_style_context ().add_class ("artboard-container");
        container.activate_on_single_click = false;
        container.selection_mode = Gtk.SelectionMode.SINGLE;

        // Block all the events from bubbling up and triggering the Artboard's events.
        container.event.connect (() => {
            return true;
        });

        revealer.add (container);

        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 2;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.reveal_child = false;
        motion_revealer.add (motion_grid);

        var motion_artboard_grid = new Gtk.Grid ();
        motion_artboard_grid.get_style_context ().add_class ("grid-motion");
        motion_artboard_grid.height_request = 2;

        motion_artboard_revealer = new Gtk.Revealer ();
        motion_artboard_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_artboard_revealer.reveal_child = false;
        motion_artboard_revealer.add (motion_artboard_grid);

        handle = new Gtk.EventBox ();
        handle.hexpand = true;
        handle.add (label_grid);
        handle.button_press_event.connect (on_click_event);

        button_locked = new Gtk.ToggleButton ();
        button_locked.tooltip_text = _("Lock Layer");
        button_locked.get_style_context ().remove_class ("button");
        button_locked.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button_locked.get_style_context ().add_class ("layer-action");
        button_locked.valign = Gtk.Align.CENTER;
        icon_locked = new Gtk.Image.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.MENU);
        icon_unlocked = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.MENU);
        icon_unlocked.visible = false;
        icon_unlocked.no_show_all = true;

        button_hidden = new Gtk.ToggleButton ();
        button_hidden.tooltip_text = _("Hide Layer");
        button_hidden.get_style_context ().remove_class ("button");
        button_hidden.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button_hidden.get_style_context ().add_class ("layer-action");
        button_hidden.valign = Gtk.Align.CENTER;
        icon_hidden = new Gtk.Image.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU);
        icon_visible = new Gtk.Image.from_icon_name ("layer-hidden-symbolic", Gtk.IconSize.MENU);
        icon_visible.visible = false;
        icon_visible.no_show_all = true;

        var button_locked_grid = new Gtk.Grid ();
        button_locked_grid.margin_end = 6;
        button_locked_grid.attach (icon_locked, 0, 0, 1, 1);
        button_locked_grid.attach (icon_unlocked, 1, 0, 1, 1);

        var button_hidden_grid = new Gtk.Grid ();
        button_hidden_grid.margin_end = 14;
        button_hidden_grid.attach (icon_hidden, 0, 0, 1, 1);
        button_hidden_grid.attach (icon_visible, 1, 0, 1, 1);

        button_hidden.add (button_hidden_grid);
        button_locked.add (button_locked_grid);

        button = new Gtk.ToggleButton ();
        button.active = true;
        button.get_style_context ().remove_class ("button");
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button.get_style_context ().add_class ("revealer-button");
        button_icon = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button.add (button_icon);

        artboard_handle = new Gtk.Grid ();
        artboard_handle.get_style_context ().add_class ("artboard-handle");
        artboard_handle.attach (handle, 0, 0, 1, 1);
        artboard_handle.attach (button_locked, 1, 0, 1, 1);
        artboard_handle.attach (button_hidden, 2, 0, 1, 1);
        artboard_handle.attach (button, 3, 0, 1, 1);

        var grid = new Gtk.Grid ();
        grid.attach (artboard_handle, 0, 0, 1, 1);
        grid.attach (motion_revealer, 0, 1, 1, 1);
        grid.attach (revealer, 0, 2, 1, 1);
        grid.attach (motion_artboard_revealer, 0, 3, 1, 1);

        add (grid);

        get_style_context ().add_class ("artboard");

        build_drag_and_drop ();

        button.toggled.connect (() => {
            revealer.reveal_child = ! revealer.get_reveal_child ();

            if (revealer.get_reveal_child ()) {
                button.get_style_context ().remove_class ("closed");
            } else {
                button.get_style_context ().add_class ("closed");
            }
        });

        model.layer.notify["selected"].connect (() => {
            if (model.layer.selected) {
              activate ();
              return;
            }

            ((Gtk.ListBox) parent).unselect_row (this);
        });

        handle.enter_notify_event.connect (event => {
            if (model.layer.locked) {
                return true;
            }

            get_style_context ().add_class ("hover");
            window.event_bus.hover_over_layer (model);
            return false;
        });

        handle.leave_notify_event.connect (event => {
            get_style_context ().remove_class ("hover");
            window.event_bus.hover_over_layer (null);
            return false;
        });

        container.bind_model (model.items, item => {
            return new Layouts.Partials.Layer (window, ((Lib.Items.CanvasItem) item), container);
        });

        lock_actions ();
        hide_actions ();

        window.event_bus.hover_over_item.connect (on_hover_over_item);
    }

    private void on_hover_over_item (Lib.Items.CanvasItem? item) {
        if (item == model) {
            get_style_context ().add_class ("hovered");
            return;
        }

        get_style_context ().remove_class ("hovered");
    }

    private void build_drag_and_drop () {
        // Make the artboard layer a draggable widget.
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, ARTBOARD_ENTRY, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        // Make the artboard handle widget a DnD destination.
        Gtk.drag_dest_set (artboard_handle, Gtk.DestDefaults.MOTION, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        artboard_handle.drag_motion.connect (on_drag_motion);
        artboard_handle.drag_leave.connect (on_drag_leave);
        artboard_handle.drag_drop.connect (on_drag_drop);
        artboard_handle.drag_data_received.connect (on_drag_data_received);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        // Close the layers container.
        button.active = false;

        var row = (widget as Akira.Layouts.Partials.Artboard);
        Gtk.Allocation alloc;
        row.artboard_handle.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.artboard_handle.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data,
        uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Akira.Layouts.Partials.Artboard))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ARTBOARD"), 32, data
        );
    }

    public bool on_drag_motion (Gdk.DragContext context, int x, int y, uint time) {
        var target = Gtk.drag_dest_find_target (this, context, drop_targets);

        if (target == Gdk.Atom.intern_static_string ("ARTBOARD")) {
            motion_artboard_revealer.reveal_child = true;
        } else {
            motion_revealer.reveal_child = true;
        }
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        var target = Gtk.drag_dest_find_target (this, context, drop_targets);

        if (target == Gdk.Atom.intern_static_string ("ARTBOARD")) {
            motion_artboard_revealer.reveal_child = false;
        } else {
            motion_revealer.reveal_child = false;
        }
    }

    /**
     * Receive the signal when an item is dropped on top of the layer.
     * If it's a valid layer, get the correct target type and trigger on_drag_data_received ().
     */
    private bool on_drag_drop (Gtk.Widget widget, Gdk.DragContext context, int x, int y, uint time) {
        if (context.list_targets () != null) {
            var target_type = (Gdk.Atom) context.list_targets ().nth_data (0);
            Gtk.drag_get_data (widget, context, target_type, time);
        }

        return false;
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
        int items_count, pos_source, pos_target, source, target;

        var type = Gtk.drag_dest_find_target (this, context, drop_targets);
        // Used to adjust the position of swappable items if the source item
        // is dragged from the bottom up.
        int position_adjustment = 0;

        if (type == Gdk.Atom.intern_static_string ("ARTBOARD")) {
            var artboard = (Layouts.Partials.Artboard) (
                (Gtk.Widget[]) selection_data.get_data ()
            )[0];

            items_count = (int) window.items_manager.artboards.get_n_items ();
            pos_target = items_count - 1 - window.items_manager.artboards.index (model);
            pos_source = items_count - 1 - window.items_manager.artboards.index (artboard.model);

            // Interrupt if item position doesn't exist.
            if (pos_source == -1) {
                return;
            }

            // z-index is the exact opposite of items placement as the last item
            // is the topmost element. Because of this, we need some trickery to
            // properly handle the list's order.
            source = items_count - 1 - pos_source;
            target = items_count - 1 - pos_target;

            // Interrupt if the item was dropped in the same position.
            if (source == target) {
                debug ("same position");
                return;
            }

            // If the initial position is higher than the targeted dropped layer, it
            // means the layer was dragged from the bottom up, therefore we need to
            // increase the dropped target by 1 since we don't deal with location 0.
            if (source > target) {
                position_adjustment--;
                target++;
            }

            // Swap the position inside the List Model.
            window.items_manager.artboards.swap_items (source, target);

            // The actual items in the canvas might not match the items in the List Model
            // due to Artboards labels, grids, and other pseudo elements. Therefore we need
            // to get the real position of the child and swap them.
            var root = artboard.model.parent;
            root.move_child (root.find_child (artboard.model), root.find_child (model) + position_adjustment);

            window.event_bus.z_selected_changed ();

            return;
        }

        var layer = (Layer) ((Gtk.Widget[]) selection_data.get_data ())[0];

        // Change artboard if necessary.
        window.items_manager.change_artboard.begin (layer.model, model);

        // Use the existing action to push an item all the way to the top.
        window.event_bus.change_z_selected (true, true);

        model.changed (true);
    }

    private bool on_click_event (Gdk.EventButton event) {
        if (model.layer.locked) {
            return true;
        }

        switch (event.type) {
            case Gdk.EventType.@2BUTTON_PRESS:
                entry.text = label.label;
                entry.visible = true;
                entry.no_show_all = false;
                label.visible = false;
                label.no_show_all = true;

                button_locked.visible = false;
                button_locked.no_show_all = true;
                button_hidden.visible = false;
                button_hidden.no_show_all = true;

                editing = true;

                Timeout.add (200, () => {
                    entry.grab_focus ();
                    return false;
                });

                return true;

            case Gdk.EventType.BUTTON_PRESS:
                window.event_bus.request_add_item_to_selection (model);

                // Selected layers can't show hover a effect.
                get_style_context ().remove_class ("hovered");

                // Always move the focus back to the canvas.
                window.event_bus.set_focus_on_canvas ();
                window.event_bus.hover_over_layer (null);

                return true;
        }

        return false;
    }

    public void update_on_enter () {
        update_label ();
    }

    public bool update_on_leave () {
        update_label ();
        window.event_bus.connect_typing_accel ();
        return false;
    }

    public bool update_on_escape (Gdk.EventKey key) {
        if (key.keyval == Gdk.Key.Escape) {
            entry.text = label.label;

            update_label ();
            window.event_bus.request_escape ();
        }
        return false;
    }

    private void update_label () {
        entry.visible = false;
        entry.no_show_all = true;
        label.visible = true;
        label.no_show_all = false;

        editing = false;

        var new_label = entry.get_text ();
        window.event_bus.set_focus_on_canvas ();

        if (label.label == new_label) {
            return;
        }

        label.label = new_label;
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private void lock_actions () {
        button_locked.bind_property ("active", model.layer, "locked",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

        button_locked.toggled.connect (() => {
            var active = button_locked.get_active ();
            button_locked.tooltip_text = active ? _("Unlock Layer") : _("Lock Layer");

            if (active) {
                button_locked.get_style_context ().add_class ("show");
                // Disable any pointer events for a locked item.
                model.pointer_events = Goo.CanvasPointerEvents.NONE;

                // Let the UI know that this item was locked.
                window.event_bus.item_locked (model);
                ((Gtk.ListBox) parent).unselect_row (this);
                model.layer.selected = false;
            } else {
                button_locked.get_style_context ().remove_class ("show");
                // Re-enable pointer events.
                model.pointer_events = Goo.CanvasPointerEvents.ALL;
            }

            icon_unlocked.visible = active;
            icon_unlocked.no_show_all = !active;

            icon_locked.visible = !active;
            icon_locked.no_show_all = active;

            window.event_bus.set_focus_on_canvas ();
            window.event_bus.file_edited ();
        });
    }

    private void hide_actions () {
        button_hidden.bind_property ("active", model, "visibility",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                Goo.CanvasItemVisibility status = (bool) srcval.get_boolean ()
                    ? Goo.CanvasItemVisibility.INVISIBLE
                    : Goo.CanvasItemVisibility.VISIBLE;
                targetval.set_enum (status);
                return true;
            },
            (binding, srcval, ref targetval) => {
                var status = ((Goo.CanvasItemVisibility) srcval.get_enum ()) == Goo.CanvasItemVisibility.INVISIBLE;
                targetval.set_boolean (status);
                return true;
            });

        button_hidden.toggled.connect (() => {
            var active = button_hidden.get_active ();
            button_hidden.tooltip_text = active ? _("Show Layer") : _("Hide Layer");

            if (active) {
                button_hidden.get_style_context ().add_class ("show");
            } else {
                button_hidden.get_style_context ().remove_class ("show");
            }

            icon_visible.visible = active;
            icon_visible.no_show_all = ! active;

            icon_hidden.visible = ! active;
            icon_hidden.no_show_all = active;

            window.event_bus.set_focus_on_canvas ();
            window.event_bus.file_edited ();
        });
    }
}

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

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
    };

    private const Gtk.TargetEntry TARGET_ENTRIES_LAYER[] = {
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

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

    public Akira.Lib.Models.CanvasArtboard model { get; construct; }

    // Drag and Drop properties.
    public Gtk.Revealer motion_revealer;

    private bool _editing { get; set; default = false; }
    public bool editing {
        get { return _editing; } set { _editing = value; }
    }

    public Artboard (Akira.Window window, Akira.Lib.Models.CanvasArtboard model) {
        Object (
            window: window,
            model: model
        );
    }

    construct {
        get_style_context ().add_class ("artboard");

        label = new Gtk.Label ("");
        label.get_style_context ().add_class ("artboard-name");
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        model.bind_property ("name", label, "label",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        entry = new Gtk.Entry ();
        entry.margin_top = entry.margin_bottom = 2;
        entry.margin_start = 6;
        entry.expand = true;
        entry.visible = false;
        entry.no_show_all = true;
        // NOTE: We can't bind the entry to the model.name otherwise we won't be
        // able to handle the ESC key to restore the previous entry.
        entry.text = model.name;

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

        // Block all the events from bubbling up and triggering the Artbord's events.
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

        handle = new Gtk.EventBox ();
        handle.hexpand = true;
        handle.add (label_grid);
        handle.event.connect (on_handle_event);

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

        var artboard_handle = new Gtk.Grid ();
        artboard_handle.get_style_context ().add_class ("artboard-handle");
        artboard_handle.attach (handle, 0, 0, 1, 1);
        artboard_handle.attach (button_locked, 1, 0, 1, 1);
        artboard_handle.attach (button_hidden, 2, 0, 1, 1);
        artboard_handle.attach (button, 3, 0, 1, 1);

        var grid = new Gtk.Grid ();
        grid.attach (artboard_handle, 0, 0, 1, 1);
        grid.attach (motion_revealer, 0, 1, 1, 1);
        grid.attach (revealer, 0, 2, 1, 1);

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

        model.notify["selected"].connect (() => {
            if (model.selected) {
              activate ();
              return;
            }

            (parent as Gtk.ListBox).unselect_row (this);
        });

        handle.enter_notify_event.connect (event => {
            get_style_context ().add_class ("hover");
            return false;
        });

        handle.leave_notify_event.connect (event => {
            get_style_context ().remove_class ("hover");
            return false;
        });

        container.bind_model (model.items, item => {
            // TODO: Differentiate between layer and artboard
            // based upon item "type" of some sort
            var item_model = item as Akira.Lib.Models.CanvasItem;
            return new Akira.Layouts.Partials.Layer (window, item_model, container);
        });
    }

    private void build_drag_and_drop () {
        // Make this a draggable widget.
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);
        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        // Make this widget a DnD destination.
        Gtk.drag_dest_set (this, Gtk.DestDefaults.MOTION, TARGET_ENTRIES_LAYER, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_motion);
        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (Akira.Layouts.Partials.Artboard) widget.get_ancestor (typeof (Akira.Layouts.Partials.Artboard));
        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

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

        row.draw (cr);

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
        motion_revealer.reveal_child = true;
        return true;
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        motion_revealer.reveal_child = false;
    }

    private bool on_handle_event (Gdk.Event event) {
        switch (event.type) {
            case Gdk.EventType.@2BUTTON_PRESS:
                entry.text = label.label;
                entry.visible = true;
                entry.no_show_all = false;
                label.visible = false;
                label.no_show_all = true;

                editing = true;

                Timeout.add (200, () => {
                    entry.grab_focus ();
                    return false;
                });

                return true;

            case Gdk.EventType.BUTTON_PRESS:
                window.event_bus.request_add_item_to_selection (model);
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

        if (label.label == new_label) {
            return;
        }

        label.label = new_label;

        window.event_bus.set_focus_on_canvas ();
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        window.event_bus.disconnect_typing_accel ();
        return false;
    }
}

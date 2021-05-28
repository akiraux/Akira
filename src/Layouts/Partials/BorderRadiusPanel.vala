/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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
* Authored by: Bilal Elmoussaoui <bil.elmoussaoui@gmail.com>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.Partials.BorderRadiusPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Gtk.Label label;
    private Gtk.Revealer options_revealer;
    private Gtk.Grid options_grid;
    private Gtk.Adjustment radius_adj;
    private Gtk.Scale border_radius_scale;
    private Widgets.InputField border_radius_entry;
    private Gtk.ToggleButton options_button;

    private Widgets.InputField border_radius_bottom_left_entry;
    private Widgets.InputField border_radius_bottom_right_entry;
    private Widgets.InputField border_radius_top_left_entry;
    private Widgets.InputField border_radius_top_right_entry;

    private Gtk.Switch autoscale_switch;
    private Gtk.Switch uniform_switch;
    private Binding radius_binding;
    private Binding uniform_binding;
    private Binding autoscale_binding;
    private double max_value;

    private Akira.Lib.Items.CanvasRect _selected_item;
    private Akira.Lib.Items.CanvasRect selected_item {
        get {
            return _selected_item;
        } set {
            // If the same item is already selected, or the value is still null
            // we don't do anything to prevent redraw and calculations.
            if (_selected_item == value) {
                return;
            }
            disconnect_previous_item ();
            _selected_item = value;
            if (_selected_item == null || _selected_item.border_radius == null) {
                disable ();
                return;
            }
            enable ();
        }
    }

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public BorderRadiusPanel (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        var title_cont = new Gtk.Grid ();
        title_cont.get_style_context ().add_class ("option-panel");

        label = new Gtk.Label (_("Style"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);
        title_cont.attach (label, 0, 0, 1, 1);

        attach (title_cont, 0, 0, 1, 1);

        var panel_grid = new Gtk.Grid ();
        get_style_context ().add_class ("style-panel");
        panel_grid.row_spacing = 6;
        panel_grid.border_width = 12;
        panel_grid.column_spacing = 6;
        panel_grid.hexpand = true;
        attach (panel_grid, 0, 1, 1, 1);

        var border_radius_label = new Gtk.Label (_("Border Radius"));
        border_radius_label.get_style_context ().add_class ("group-title");
        border_radius_label.halign = Gtk.Align.START;
        border_radius_label.hexpand = true;
        border_radius_label.margin_bottom = 2;
        panel_grid.attach (border_radius_label, 0, 1, 3, 1);

        radius_adj = new Gtk.Adjustment (0, 0, 1.0, 10.0, 0, 0);
        border_radius_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, radius_adj);
        border_radius_scale.digits = 0;
        border_radius_scale.draw_value = false;
        border_radius_scale.valign = Gtk.Align.CENTER;
        border_radius_scale.halign = Gtk.Align.FILL;
        border_radius_scale.hexpand = true;
        panel_grid.attach (border_radius_scale, 0, 2, 1, 1);

        border_radius_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PIXEL, 7, true, true);
        border_radius_entry.entry.hexpand = false;
        border_radius_entry.entry.width_request = 64;
        border_radius_entry.valign = Gtk.Align.CENTER;
        panel_grid.attach (border_radius_entry, 1, 2, 1, 1);

        border_radius_entry.entry.bind_property (
            "value", radius_adj, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);

        var options_image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
        options_button = new Gtk.ToggleButton ();
        options_button.valign = Gtk.Align.CENTER;
        options_button.halign = Gtk.Align.END;
        options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        options_button.add (options_image);
        options_button.can_focus = false;
        options_button.set_tooltip_text (_("Border radius options"));
        panel_grid.attach (options_button, 2, 2, 1, 1);

        options_revealer = new Gtk.Revealer ();
        options_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
        panel_grid.attach (options_revealer, 0, 3, 3, 1);

        options_grid = new Gtk.Grid ();
        options_grid.border_width = 12;
        options_grid.hexpand = true;

        var border_entries_grid = new Gtk.Grid ();
        border_entries_grid.row_spacing = 12;
        border_entries_grid.border_width = 12;
        border_entries_grid.column_spacing = 12;
        border_entries_grid.hexpand = true;

        border_radius_top_left_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PIXEL, 7, true, true);
        border_radius_top_left_entry.entry.hexpand = false;
        border_radius_top_left_entry.entry.width_request = 64;
        border_radius_top_left_entry.valign = Gtk.Align.CENTER;
        border_radius_top_left_entry.halign = Gtk.Align.START;
        border_entries_grid.attach (border_radius_top_left_entry, 0, 0, 1, 1);

        border_radius_top_right_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PIXEL, 7, true, true);
        border_radius_top_right_entry.entry.hexpand = false;
        border_radius_top_right_entry.entry.width_request = 64;
        border_radius_top_right_entry.valign = Gtk.Align.CENTER;
        border_radius_top_right_entry.halign = Gtk.Align.END;
        border_entries_grid.attach (border_radius_top_right_entry, 1, 0, 1, 1);

        border_radius_bottom_left_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PIXEL, 7, true, true);
        border_radius_bottom_left_entry.entry.hexpand = false;
        border_radius_bottom_left_entry.entry.width_request = 64;
        border_radius_bottom_left_entry.valign = Gtk.Align.CENTER;
        border_radius_bottom_left_entry.halign = Gtk.Align.START;
        border_entries_grid.attach (border_radius_bottom_left_entry, 0, 1, 1, 1);

        border_radius_bottom_right_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PIXEL, 7, true, true);
        border_radius_bottom_right_entry.entry.hexpand = false;
        border_radius_bottom_right_entry.entry.width_request = 64;
        border_radius_bottom_right_entry.valign = Gtk.Align.CENTER;
        border_radius_bottom_right_entry.halign = Gtk.Align.END;
        border_entries_grid.attach (border_radius_bottom_right_entry, 1, 1, 1, 1);

        options_grid.attach (border_entries_grid, 0, 0, 1, 1);
        options_revealer.add (options_grid);

        var border_options_grid = new Gtk.Grid ();
        border_options_grid.row_spacing = 6;
        border_options_grid.border_width = 12;
        border_options_grid.column_spacing = 6;
        border_options_grid.hexpand = true;

        autoscale_switch = new Gtk.Switch ();
        autoscale_switch.valign = Gtk.Align.CENTER;
        autoscale_switch.halign = Gtk.Align.START;
        border_options_grid.attach (autoscale_switch, 0, 0, 1, 1);
        var autoscale_label = new Gtk.Label (_("Autoscale Corners"));
        autoscale_label.valign = Gtk.Align.CENTER;
        autoscale_label.halign = Gtk.Align.START;
        border_options_grid.attach (autoscale_label, 1, 0, 1, 1);

        uniform_switch = new Gtk.Switch ();
        uniform_switch.valign = Gtk.Align.CENTER;
        uniform_switch.halign = Gtk.Align.START;
        border_options_grid.attach (uniform_switch, 0, 1, 1, 1);
        var uniform_label = new Gtk.Label (_("Uniform Corners"));
        uniform_label.valign = Gtk.Align.CENTER;
        uniform_label.halign = Gtk.Align.START;
        border_options_grid.attach (uniform_label, 1, 1, 1, 1);
        options_grid.attach (border_options_grid, 0, 1, 1, 1);
        show_all ();

        bind_signals ();
    }

    private void bind_signals () {
        toggled = false;
        window.event_bus.selected_items_list_changed.connect (on_selected_items_list_changed);
        options_button.toggled.connect (() => {
            options_revealer.reveal_child = !options_revealer.child_revealed;
            window.event_bus.request_widget_redraw ();
        });

        uniform_switch.notify["active"].connect (() => {
            update_all_borders (uniform_switch.active);
        });

        //  border_radius_top_left_entry.entry.changed.connect (on_radius_change);
        //  border_radius_top_right_entry.entry.changed.connect (on_radius_change);
        //  border_radius_bottom_right_entry.entry.changed.connect (on_radius_change);
        //  border_radius_bottom_left_entry.entry.changed.connect (on_radius_change);
    }

    private void on_selected_items_list_changed (List<Lib.Items.CanvasItem> selected_items) {
        // Interrupt if we don't have an item selected or if more than 1 is selected
        // since we can't handle the border radius of multiple items at once.
        if (selected_items.length () == 0 || selected_items.length () > 1) {
            selected_item = null;
            toggled = false;
            return;
        }

        if (!(selected_items.nth_data (0) is Akira.Lib.Items.CanvasRect)) {
            selected_item = null;
            toggled = false;
            return;
        }

        if (selected_item == null || selected_item != selected_items.nth_data (0)) {
            toggled = true;
            selected_item = (Akira.Lib.Items.CanvasRect) selected_items.nth_data (0);
        }
    }

    private void on_size_change () {
        var max_size = double.min (selected_item.width, selected_item.height);
        max_value = Math.round (max_size / 2);
        radius_adj.upper = max_value;
        border_radius_entry.set_range (0, max_value);

        if (!selected_item.border_radius.autoscale) {
            return;
        }

        // Calculate the radius percentage and update the value on shape resize.
        var percentage = Math.round (border_radius_scale.get_value () / max_size * 100);
        border_radius_scale.set_value (Math.round (percentage * max_size / 100));
    }

    private void enable () {
        on_size_change ();

        uniform_switch.active = selected_item.border_radius.uniform;
        autoscale_switch.active = selected_item.border_radius.autoscale;

        // Uniform radius
        if (selected_item.border_radius.uniform) {
            radius_adj.value = selected_item.border_radius.x;
        }
        update_all_borders (selected_item.border_radius.uniform);

        // Non-Uniform radius
        //  if (!selected_item.border_radius.uniform) {
        //      border_radius_top_left_entry.entry.text = selected_item.radius_tl;
        //      border_radius_top_right_entry.entry.text = selected_item.radius_tr;
        //      border_radius_bottom_right_entry.entry.text = selected_item.radius_br;
        //      border_radius_bottom_left_entry.entry.text = selected_item.radius_bl;
        //  }

        radius_binding = radius_adj.bind_property (
            "value", selected_item.border_radius, "x",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        uniform_binding = uniform_switch.bind_property (
            "active", selected_item.border_radius, "uniform");
        autoscale_binding = autoscale_switch.bind_property (
            "active", selected_item.border_radius, "autoscale");

        selected_item.notify["width"].connect (on_size_change);
        selected_item.notify["height"].connect (on_size_change);
    }

    private void disconnect_previous_item () {
        // Disconnect the model binding if an item was previously stored.
        // This is necessary to prevent GObject Critical errors.
        if (selected_item != null) {
            selected_item.notify["width"].disconnect (on_size_change);
            selected_item.notify["height"].disconnect (on_size_change);
        }
    }

    private void update_all_borders (bool switch_active) {
        border_radius_scale.sensitive = switch_active;
        border_radius_entry.entry.sensitive = switch_active;

        border_radius_bottom_left_entry.entry.sensitive = !switch_active;
        border_radius_bottom_right_entry.entry.sensitive = !switch_active;
        border_radius_top_left_entry.entry.sensitive = !switch_active;
        border_radius_top_right_entry.entry.sensitive = !switch_active;

        string border_value = !switch_active ?
            ((int)border_radius_scale.get_value ()).to_string () :
            "";
        border_radius_bottom_left_entry.entry.text = border_value;
        border_radius_bottom_right_entry.entry.text = border_value;
        border_radius_top_left_entry.entry.text = border_value;
        border_radius_top_right_entry.entry.text = border_value;
    }

    private void disable () {
        //  border_radius_top_left_entry.entry.changed.disconnect (on_radius_change);
        //  border_radius_top_right_entry.entry.changed.disconnect (on_radius_change);
        //  border_radius_bottom_right_entry.entry.changed.disconnect (on_radius_change);
        //  border_radius_bottom_left_entry.entry.changed.disconnect (on_radius_change);

        radius_binding.unbind ();
        uniform_binding.unbind ();
        autoscale_binding.unbind ();

        autoscale_switch.active = false;
        uniform_switch.active = false;

        border_radius_scale.set_value (0);

        border_radius_entry.entry.text = "";
        border_radius_entry.entry.sensitive = false;

        border_radius_top_left_entry.entry.text = "";
        border_radius_top_left_entry.entry.sensitive = false;

        border_radius_top_right_entry.entry.text = "";
        border_radius_top_right_entry.entry.sensitive = false;

        border_radius_bottom_left_entry.entry.text = "";
        border_radius_bottom_left_entry.entry.sensitive = false;

        border_radius_bottom_right_entry.entry.text = "";
        border_radius_bottom_right_entry.entry.sensitive = false;
    }
}

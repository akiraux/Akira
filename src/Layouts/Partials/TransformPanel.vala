/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Ana Gelez <ana@gelez.xyz>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Layouts.Partials.TransformPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }
    public weak Akira.Lib.Canvas canvas;

    private Widgets.LinkedInput x;
    private Widgets.LinkedInput y;
    private Widgets.LinkedInput width;
    private Widgets.LinkedInput height;
    private Widgets.LinkedInput rotation;
    private Gtk.ToggleButton lock_changes;
    private Gtk.ToggleButton hflip_button;
    private Gtk.ToggleButton vflip_button;
    private Gtk.Adjustment opacity_adj;
    private Widgets.InputField opacity_entry;
    private Gtk.Scale scale;

    // Bindings.
    private Binding x_bind;
    private Binding y_bind;
    private Binding ratio_bind;
    private Binding width_bind;
    private Binding height_bind;
    private Binding rotation_bind;
    private Binding opacity_bind;
    private Binding hflip_bind;
    private Binding vflip_bind;

    public TransformPanel (Akira.Window main_window) {
        Object (
            window: main_window,
            orientation: Gtk.Orientation.HORIZONTAL
        );
    }

    private Lib.Items.CanvasItem? _selected_item;
    public Lib.Items.CanvasItem? selected_item {
        get {
            return _selected_item;
        } set {
            // If the same item is already selected, or the value is still null
            // we don't do anything to prevent redraw and calculations.
            if (_selected_item == value) {
                return;
            }

            disconnect_previous_item ();
            disable ();

            _selected_item = value;
            bool has_item = _selected_item != null;

            if (has_item) {
                enable ();
            }

            x.enabled = has_item;
            y.enabled = has_item;
            height.enabled = has_item;
            width.enabled = has_item;
            rotation.enabled = has_item && !(_selected_item is Lib.Items.CanvasArtboard);
            hflip_button.sensitive = has_item && !(_selected_item is Lib.Items.CanvasArtboard);
            vflip_button.sensitive = has_item && !(_selected_item is Lib.Items.CanvasArtboard);
            opacity_entry.entry.sensitive = has_item && !(_selected_item is Lib.Items.CanvasArtboard);
            scale.sensitive = has_item && !(_selected_item is Lib.Items.CanvasArtboard);
            lock_changes.sensitive = has_item;
        }
    }

    construct {
        border_width = 12;
        row_spacing = 6;
        column_spacing = 6;
        hexpand = true;

        x = new Widgets.LinkedInput (_("X"), _("Horizontal position"));
        x.input_field.set_range (-Akira.Layouts.MainCanvas.CANVAS_SIZE, Akira.Layouts.MainCanvas.CANVAS_SIZE);
        y = new Widgets.LinkedInput (_("Y"), _("Vertical position"));
        y.input_field.set_range (-Akira.Layouts.MainCanvas.CANVAS_SIZE, Akira.Layouts.MainCanvas.CANVAS_SIZE);
        width = new Widgets.LinkedInput (_("W"), _("Width"));
        width.input_field.set_range (0, Akira.Layouts.MainCanvas.CANVAS_SIZE);
        height = new Widgets.LinkedInput (_("H"), _("Height"));
        height.input_field.set_range (0, Akira.Layouts.MainCanvas.CANVAS_SIZE);

        var lock_image = new Gtk.Image.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.BUTTON);
        lock_changes = new Gtk.ToggleButton ();
        lock_changes.tooltip_text = _("Lock Ratio");
        lock_changes.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        lock_changes.get_style_context ().add_class ("label-colors");
        lock_changes.image = lock_image;
        lock_changes.can_focus = false;
        lock_changes.sensitive = false;
        lock_changes.toggled.connect (() => {
            var icon = lock_changes.active ? "changes-prevent-symbolic" : "changes-allow-symbolic";
            lock_changes.image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.BUTTON);
        });

        rotation = new Widgets.LinkedInput (_("R"), _("Rotation degrees"), "°");
        rotation.input_field.set_range (-360, 360);

        hflip_button = new Gtk.ToggleButton ();
        hflip_button.add (new Widgets.ButtonImage ("object-flip-horizontal"));
        hflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hflip_button.hexpand = false;
        hflip_button.can_focus = false;
        hflip_button.sensitive = false;
        hflip_button.halign = Gtk.Align.CENTER;
        hflip_button.valign = Gtk.Align.CENTER;
        hflip_button.tooltip_markup =
            Granite.markup_accel_tooltip ({"<Ctrl>bracketleft"}, _("Flip Horizontally"));

        vflip_button = new Gtk.ToggleButton ();
        vflip_button.add (new Widgets.ButtonImage ("object-flip-vertical"));
        vflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        vflip_button.hexpand = false;
        vflip_button.can_focus = false;
        vflip_button.sensitive = false;
        vflip_button.halign = Gtk.Align.CENTER;
        vflip_button.valign = Gtk.Align.CENTER;
        vflip_button.tooltip_markup =
            Granite.markup_accel_tooltip ({"<Ctrl>bracketright"}, _("Flip Vertically"));

        var align_grid = new Gtk.Grid ();
        align_grid.hexpand = true;
        align_grid.column_homogeneous = true;
        align_grid.attach (hflip_button, 0, 0, 1, 1);
        align_grid.attach (vflip_button, 1, 0, 1, 1);

        opacity_adj = new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0);
        scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, opacity_adj);
        scale.hexpand = true;
        scale.sensitive = false;
        scale.draw_value = false;
        scale.digits = 0;
        scale.margin_end = 20;
        opacity_entry = new Widgets.InputField (
            Widgets.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_entry.entry.bind_property (
            "value", opacity_adj, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        opacity_entry.entry.hexpand = false;
        opacity_entry.entry.width_request = 64;

        var opacity_grid = new Gtk.Grid ();
        opacity_grid.hexpand = true;
        opacity_grid.attach (scale, 0, 0, 1);
        opacity_grid.attach (opacity_entry, 1, 0, 1);

        attach (group_title (_("Position")), 0, 0, 3);
        attach (x, 0, 1, 1);
        attach (y, 2, 1, 1);
        attach (new Widgets.PanelSeparator (), 0, 2, 3);
        attach (group_title (_("Size")), 0, 3, 3);
        attach (width, 0, 4, 1);
        attach (lock_changes, 1, 4, 1);
        attach (height, 2, 4, 1);
        attach (new Widgets.PanelSeparator (), 0, 5, 3);
        attach (group_title (_("Transform")), 0, 6, 3);
        attach (rotation, 0, 7, 1);
        attach (align_grid, 2, 7, 1);
        attach (new Widgets.PanelSeparator (), 0, 8, 3);
        attach (group_title (_("Opacity")), 0, 9, 3);
        attach (opacity_grid, 0, 10, 3);

        window.event_bus.selected_items_list_changed.connect (on_selected_items_list_changed);
    }

    private void on_selected_items_list_changed (List<Lib.Items.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            selected_item = null;
            return;
        }

        selected_item = selected_items.nth_data (0);
    }

    private void disconnect_previous_item () {
        if (selected_item == null) {
            return;
        }

        // Clear the bindings.
        x_bind.unbind ();
        y_bind.unbind ();
        ratio_bind.unbind ();
        width_bind.unbind ();
        height_bind.unbind ();

        // Unbind only those defined.
        if (rotation_bind != null) {
            rotation_bind.unbind ();
        }

        if (opacity_bind != null) {
            opacity_bind.unbind ();
        }

        if (hflip_bind != null) {
            hflip_bind.unbind ();
            vflip_bind.unbind ();
        }
    }

    private void disable () {
        // Reset all the values.
        x.value = 0.0;
        y.value = 0.0;
        width.value = 0.0;
        height.value = 0.0;
        opacity_adj.value = 100.0;
        rotation.value = 0.0;
        lock_changes.active = false;
        hflip_button.active = false;
        vflip_button.active = false;
    }

    private void enable () {
        canvas = selected_item.canvas as Akira.Lib.Canvas;

        x_bind = window.coords_middleware.bind_property (
            "x", x, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
        );

        y_bind = window.coords_middleware.bind_property (
            "y", y, "value", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
        );

        ratio_bind = selected_item.size.bind_property (
            "locked", lock_changes, "active",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        width_bind = window.size_middleware.bind_property (
            "width", width, "value",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        height_bind = window.size_middleware.bind_property (
            "height", height, "value",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        // Some items like Artboards don't implement every component.
        if (selected_item.rotation != null) {
            rotation_bind = selected_item.rotation.bind_property (
                "rotation", rotation, "value",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }

        if (selected_item.opacity != null) {
            opacity_bind = selected_item.opacity.bind_property (
                "opacity", opacity_adj, "value",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }

        if (selected_item.flipped != null) {
            hflip_bind = selected_item.flipped.bind_property (
                "horizontal", hflip_button, "active",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

            vflip_bind = selected_item.flipped.bind_property (
                "vertical", vflip_button, "active",
                BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
        }
    }

    private Gtk.Label group_title (string title) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("group-title");
        title_label.halign = Gtk.Align.START;
        title_label.hexpand = true;
        title_label.margin_bottom = 2;
        return title_label;
    }
}

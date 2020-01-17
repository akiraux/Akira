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
* Authored by: Ana Gelez <ana@gelez.xyz>
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Layouts.Partials.TransformPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public bool size_lock { get; set; default = false; }
    private Akira.Partials.LinkedInput x;
    private Akira.Partials.LinkedInput y;
    private Akira.Partials.LinkedInput width;
    private Akira.Partials.LinkedInput height;
    private Akira.Partials.LinkedInput rotation;
    private Gtk.Button lock_changes;
    private Gtk.Button hflip_button;
    private Gtk.Button vflip_button;
    private Gtk.Adjustment opacity_adj;
    private Akira.Partials.InputField opacity_entry;
    private Gtk.Scale scale;

    public double size_ratio = 1.0;

    // Bindings.
    private Binding width_bind;
    private Binding height_bind;
    private Binding rotation_bind;
    private Binding opacity_bind;

    public TransformPanel (Akira.Window main_window) {
        Object (
            window: main_window,
            orientation: Gtk.Orientation.HORIZONTAL
        );
    }

    private Lib.Models.CanvasItem? _selected_item;
    public Lib.Models.CanvasItem? selected_item {
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

            bool has_item = _selected_item != null;
            x.enabled = has_item;
            y.enabled = has_item;
            height.enabled = has_item;
            width.enabled = has_item;
            rotation.enabled = has_item;
            hflip_button.sensitive = has_item;
            vflip_button.sensitive = has_item;
            opacity_entry.entry.sensitive = has_item;
            scale.sensitive = has_item;
            lock_changes.sensitive = has_item;

            if (!has_item) {
                disable ();
                return;
            }

            if (_selected_item != null ) {
                enable ();
            }
        }
    }

    construct {
        border_width = 12;
        row_spacing = 6;
        column_spacing = 6;
        hexpand = true;

        x = new Akira.Partials.LinkedInput (_("X"), _("Horizontal position"));

        y = new Akira.Partials.LinkedInput (_("Y"), _("Vertical position"));
        width = new Akira.Partials.LinkedInput (_("W"), _("Width"));
        height = new Akira.Partials.LinkedInput (_("H"), _("Height"));

        lock_changes = new Gtk.Button.from_icon_name ("changes-allow-symbolic");
        lock_changes.can_focus = false;
        lock_changes.sensitive = false;
        lock_changes.tooltip_text = _("Lock Ratio");
        lock_changes.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        lock_changes.get_style_context ().add_class ("button-rounded");
        lock_changes.get_style_context ().add_class ("label-colors");
        bind_property (
            "size-lock", lock_changes, "image", BindingFlags.SYNC_CREATE,
            (binding, val, ref res) => {
                var icon = val.get_boolean () ? "changes-prevent-symbolic" : "changes-allow-symbolic";
                var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.BUTTON);
                res = image;
                update_size_ratio ();
                return true;
            });
        lock_changes.clicked.connect (() => {
            selected_item.size_locked = !size_lock;
            size_lock = !size_lock;
        });

        rotation = new Akira.Partials.LinkedInput (_("R"), _("Rotation degrees"), "°");

        hflip_button = new Gtk.Button ();
        hflip_button.add (new Akira.Partials.ButtonImage ("object-flip-horizontal"));
        hflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hflip_button.get_style_context ().add_class ("button-rounded");
        hflip_button.hexpand = false;
        hflip_button.halign = Gtk.Align.CENTER;
        hflip_button.valign = Gtk.Align.CENTER;
        hflip_button.can_focus = false;
        hflip_button.tooltip_markup =
            Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketleft"}, _("Flip Horizontally"));
        hflip_button.clicked.connect (() => {
            flip_item (-1, 1);
        });

        vflip_button = new Gtk.Button ();
        vflip_button.add (new Akira.Partials.ButtonImage ("object-flip-vertical"));
        vflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        vflip_button.get_style_context ().add_class ("button-rounded");
        vflip_button.hexpand = false;
        vflip_button.halign = Gtk.Align.CENTER;
        vflip_button.valign = Gtk.Align.CENTER;
        vflip_button.can_focus = false;
        vflip_button.tooltip_markup =
            Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketright"}, _("Flip Vertically"));
        vflip_button.clicked.connect (() => {
            flip_item (1, -1);
        });

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
        scale.round_digits = 1;
        scale.margin_end = 30;
        opacity_entry = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_entry.entry.text = (opacity_adj.get_value ()).to_string ();
        opacity_entry.entry.bind_property (
            "text", opacity_adj, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                double src = double.parse (srcval.dup_string ());

                if (src > 100 || src < 0) {
                    opacity_entry.entry.text = (opacity_adj.get_value ()).to_string ();
                    return false;
                }

                targetval.set_double (src);
                return true;
            }, (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_string (("%0.0f").printf (src));
                return true;
            });
        opacity_entry.entry.hexpand = false;
        opacity_entry.entry.width_request = 64;

        var opacity_grid = new Gtk.Grid ();
        opacity_grid.hexpand = true;
        opacity_grid.attach (scale, 0, 0, 1);
        opacity_grid.attach (opacity_entry, 1, 0, 1);

        attach (group_title (_("Position")), 0, 0, 3);
        attach (x, 0, 1, 1);
        attach (y, 2, 1, 1);
        attach (new Akira.Partials.PanelSeparator (), 0, 2, 3);
        attach (group_title (_("Size")), 0, 3, 3);
        attach (width, 0, 4, 1);
        attach (lock_changes, 1, 4, 1);
        attach (height, 2, 4, 1);
        attach (new Akira.Partials.PanelSeparator (), 0, 5, 3);
        attach (group_title (_("Transform")), 0, 6, 3);
        attach (rotation, 0, 7, 1);
        attach (align_grid, 2, 7, 1);
        attach (new Akira.Partials.PanelSeparator (), 0, 8, 3);
        attach (group_title (_("Opacity")), 0, 9, 3);
        attach (opacity_grid, 0, 10, 3);

        window.event_bus.selected_items_changed.connect (on_selected_items_changed);
        window.event_bus.item_coord_changed.connect (on_item_coord_changed);
    }

    private void on_selected_items_changed (List<Lib.Models.CanvasItem> selected_items) {
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

        // Disconnect the signals notification.
        x.notify["value"].disconnect (x_notify_value);
        y.notify["value"].disconnect (y_notify_value);
        height_bind.unbind ();
        width_bind.unbind ();
        rotation_bind.unbind ();
        opacity_bind.unbind ();
    }

    private void disable () {
        // Reset all the values.
        x.value = 0.0;
        y.value = 0.0;
        width.value = 0.0;
        height.value = 0.0;
        opacity_adj.value = 100.0;
        rotation.value = 0.0;
        size_ratio = 1.0;
        size_lock = false;
    }

    private void enable () {
        on_item_coord_changed ();

        width.value = selected_item.get_coords ("width");
        height.value = selected_item.get_coords ("height");
        rotation.value = selected_item.rotation;
        opacity_adj.value = selected_item.opacity;
        size_lock = selected_item.size_locked;

        // Property binding doesn't work for X and Y as these attributes are not
        // directly accessible from the CanvasItem. (goocanvas shenanigans)
        x.notify["value"].connect (x_notify_value);
        y.notify["value"].connect (y_notify_value);

        width_bind = width.bind_property (
            "value", selected_item, "width",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_double (src);
                if (size_lock) {
                    height.value = GLib.Math.round (src / size_ratio);
                }
                return true;
            });

        height_bind = height.bind_property (
            "value", selected_item, "height",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_double (src);
                if (size_lock) {
                    width.value = GLib.Math.round (src * size_ratio);
                }
                return true;
            });

        rotation_bind = rotation.bind_property (
            "value", selected_item, "rotation",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_double (src);
                Utils.AffineTransform.set_rotation (src, selected_item);
                return true;
            });

        opacity_bind = opacity_adj.bind_property (
            "value", selected_item, "opacity",
            BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);

        // Connect items value changes to redraw the selection bounds.
        selected_item.notify["width"].connect (on_item_value_changed);
        selected_item.notify["height"].connect (on_item_value_changed);
        selected_item.notify["rotation"].connect (on_item_value_changed);
        selected_item.notify["opacity"].connect (selected_item.reset_colors);
    }

    private void on_item_value_changed () {
        window.event_bus.item_value_changed ();
    }

    // We need to fetch new X and Y values to update the fields.
    private void on_item_coord_changed () {
        double item_x, item_y, item_scale, item_rotation;
        selected_item.get_simple_transform (
            out item_x, out item_y, out item_scale, out item_rotation);

        x.value = item_x;
        y.value = item_y;
    }

    private void flip_item (double sx, double sy) {
    //     double x, y, width, height;
    //     selected_item.get ("x", out x, "y", out y, "width", out width, "height", out height);
    //     var center_x = x + width / 2;
    //     var center_y = y + height / 2;

    //     var transform = Cairo.Matrix.identity ();
    //     selected_item.get_transform (out transform);
    //     transform.translate (center_x, center_y);

    //     double radians = selected_item.get_data<double?> ("rotation") * (Math.PI / 180);
    //     transform.rotate (-radians);
    //     transform.scale (sx, sy);
    //     transform.rotate (radians);
    //     transform.translate (-center_x, -center_y);
    //     selected_item.set_transform (transform);
    }

    public void y_notify_value () {
        Utils.AffineTransform.set_position (null, y.value, selected_item);
        on_item_value_changed ();
    }

    public void x_notify_value () {
        Utils.AffineTransform.set_position (x.value, null, selected_item);
        on_item_value_changed ();
    }

    public void update_size_ratio () {
        size_ratio = width.value / height.value;
    }

    private Gtk.Label group_title (string title) {
        var title_label = new Gtk.Label ("%s".printf (title));
        title_label.get_style_context ().add_class ("group-title");
        title_label.halign = Gtk.Align.START;
        title_label.hexpand = true;
        title_label.margin_bottom = 2;
        return title_label;
    }
}

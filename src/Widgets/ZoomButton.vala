/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Widgets.ZoomButton : Gtk.Grid {
    public weak Akira.Window window { get; set construct; }

    private Gtk.Label label_btn;
    private Gtk.Button zoom_out_button;
    private Gtk.Button zoom_in_button;
    private Gtk.Button zoom_default_button;
    private Gtk.Popover zoom_popover;
    private Gtk.Entry zoom_input;

    public ZoomButton (Akira.Window window) {
        this.window = window;

        // Grid specific attributes.
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        valign = Gtk.Align.CENTER;
        column_homogeneous = false;
        width_request = 140;
        hexpand = false;

        // Zoom out button.
        zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
        zoom_out_button.get_style_context ().add_class ("button-zoom");
        zoom_out_button.get_style_context ().add_class ("button-zoom-start");
        zoom_out_button.can_focus = false;
        zoom_out_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>minus"}, _("Zoom Out"));

        // Default centered zoom button.
        zoom_default_button = new Gtk.Button.with_label ("100%");
        zoom_default_button.hexpand = true;
        zoom_default_button.can_focus = false;
        zoom_default_button.tooltip_markup = Granite.markup_accel_tooltip (
            {"<Ctrl>0"},
            _("Reset Zoom. Ctrl+click to input value")
        );

        // Zoom popover containing the input field.
        zoom_popover = new Gtk.Popover (zoom_default_button);
        zoom_popover.position = Gtk.PositionType.BOTTOM;

        // The zoom input field.
        zoom_input = new Gtk.Entry ();
        zoom_input.text = "100";
        zoom_input.input_purpose = Gtk.InputPurpose.NUMBER;
        zoom_input.get_style_context ().add_class ("input-zoom");
        zoom_input.get_style_context ().add_class ("input-icon-right");
        zoom_input.secondary_icon_name = "input-percentage-symbolic";
        zoom_input.secondary_icon_sensitive = false;
        zoom_input.secondary_icon_activatable = false;
        zoom_input.xalign = 1.0f;
        zoom_input.width_chars = 8;
        zoom_input.show_all ();
        zoom_popover.add (zoom_input);

        // Zoom in button.
        zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        zoom_in_button.get_style_context ().add_class ("button-zoom");
        zoom_in_button.get_style_context ().add_class ("button-zoom-end");
        zoom_in_button.can_focus = false;
        zoom_in_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>plus"}, _("Zoom In"));

        attach (zoom_out_button, 0, 0, 1, 1);
        attach (zoom_default_button, 1, 0, 1, 1);
        attach (zoom_in_button, 2, 0, 1, 1);

        // Headerbar button label.
        label_btn = new Gtk.Label (_("Zoom"));
        label_btn.get_style_context ().add_class ("headerbar-label");
        label_btn.margin_top = 4;

        attach (label_btn, 0, 1, 3, 1);

        // Mouse click signals.
        zoom_out_button.clicked.connect (zoom_out);
        zoom_default_button.button_press_event.connect (zoom_reset);
        zoom_in_button.clicked.connect (zoom_in);

        // Keyboard press signals.
        zoom_input.key_press_event.connect (handle_key_press);
        zoom_input.focus_in_event.connect (handle_focus_in);
        zoom_input.focus_out_event.connect (handle_focus_out);

        // Bind the visibility of the button label to the gsetting attribute.
        settings.bind ("show-label", label_btn, "visible", SettingsBindFlags.DEFAULT);
        settings.bind ("show-label", label_btn, "no-show-all", SettingsBindFlags.INVERT_BOOLEAN);

        // Event listeners.
        window.event_bus.set_scale.connect (on_set_scale);
    }

    /*
     * Decrease the canvas scale by 50%.
     */
    public void zoom_out () {
        window.event_bus.update_scale (-0.5);
    }

    /*
     * Increase the canvas scale by 50%.
     */
    public void zoom_in () {
        window.event_bus.update_scale (0.5);
    }

    /*
     * Reset the zoom to 100%, or reveal a popover with the numberic
     * input field for manual inputing if the user pressed the CTRL key
     * while clicking on the button.
     */
    public bool zoom_reset (Gdk.EventButton event) {
        // If the CTRL key was pressed, show the popover with the input field.
        if ((event.state & Gdk.ModifierType.CONTROL_MASK) > 0) {
            zoom_popover.popup ();
            return true;
        }

        // Otherwise reset the zoom to 100%.
        zoom_in_button.sensitive = true;
        zoom_out_button.sensitive = true;
        window.event_bus.set_scale (1);

        return true;
    }

    /*
     * Update the button and the input field when the canvas scale is changed.
     */
    private void on_set_scale (double scale) {
        var perc_scale = scale * 100;
        zoom_default_button.label = "%.0f%%".printf (perc_scale);
        zoom_input.text = perc_scale.to_string ();
    }

    /*
     * Key press events on the input field.
     */
    private bool handle_key_press (Gdk.EventKey event) {
        // Arrow UP pressed, increase value by 1.
        if (event.keyval == Gdk.Key.Up) {
            var text_value = double.parse (zoom_input.text) + 1;
            window.event_bus.set_scale (text_value / 100);
            return true;
        }

        // Arrow DOWN pressed, decreased value by 1.
        if (event.keyval == Gdk.Key.Down) {
            var text_value = double.parse (zoom_input.text) - 1;
            window.event_bus.set_scale (text_value / 100);
            return true;
        }

        // Enter pressed, update the scale and move the focus back to the canvas.
        if (event.keyval == Gdk.Key.Return) {
            var text_value = double.parse (zoom_input.text);

            // Be sure to stay within the canvas zoom in and out limits of 2% and 5000%.
            if (text_value < 2) {
                text_value = 2;
            }
            if (text_value > 5000) {
                text_value = 5000;
            }

            window.event_bus.set_scale (text_value / 100);
            window.event_bus.set_focus_on_canvas ();
            return true;
        }

        // Escape pressed, reset to the old value held by the zoom button.
        if (event.keyval == Gdk.Key.Escape) {
            zoom_input.text = zoom_default_button.label.replace ("%", "");
            window.event_bus.set_focus_on_canvas ();
            return true;
        }

        // Only allow arrows, delete, and backspace keys other than numbers.
        if (
            event.keyval == Gdk.Key.Left ||
            event.keyval == Gdk.Key.Right ||
            event.keyval == Gdk.Key.Delete ||
            event.keyval == Gdk.Key.BackSpace
        ) {
            return false;
        }

        // Gtk.Entry doesn't currently support the "number only" filter, so
        // we need to intercept the keypress and prevent typing if the value
        // is not a number, or the CTRL modifier is not pressed.
        if (
            !(event.keyval >= Gdk.Key.@0 && event.keyval <= Gdk.Key.@9) &&
            (event.state & Gdk.ModifierType.CONTROL_MASK) == 0
        ) {
            return true;
        }

        return false;
    }

    /*
     * When the input field gains focus.
     */
    private bool handle_focus_in (Gdk.EventFocus event) {
        window.event_bus.disconnect_typing_accel ();
        return false;
    }

    /*
     * When the input field loses focus.
     */
    private bool handle_focus_out (Gdk.EventFocus event) {
        window.event_bus.connect_typing_accel ();
        return false;
    }
}

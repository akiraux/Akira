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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Layouts.Partials.BorderItem : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    private Gtk.Grid color_chooser;
    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;
    private Gtk.MenuButton selected_color;
    public Akira.Partials.InputField tickness_container;
    public Gtk.Entry color_container;
    private Gtk.Popover color_popover;
    private Gtk.Grid color_picker;
    private Gtk.ColorChooserWidget color_chooser_widget;

    public Akira.Models.BordersItemModel model { get; construct; }

    private string old_color;

    // If the color is manually set from the ColorPicker.
    // If true, the ColorChooserWidget doesn't need to be updated.
    private bool color_set_manually = false;
    private string color {
        owned get {
            return model.color;
        } set {
            model.color = value;
        }
    }

    private int alpha {
        owned get {
            return model.alpha;
        } set {
            model.alpha = value;
        }
    }

    private int border_size {
        owned get {
            return model.border_size;
        } set {
            model.border_size = value;
        }
    }

    private bool hidden {
        owned get {
            return model.hidden;
        } set {
            model.hidden = value;
            set_hidden_button ();
            toggle_ui_visibility ();
        }
    }

    public BorderItem (Akira.Window window, Akira.Models.BordersItemModel model) {
        Object (
            window: window,
            model: model
        );
    }

    construct {
        create_ui ();

        // Update view BEFORE event bindings in order
        // to not trigger bindings on first assignment.
        update_view ();

        create_event_bindings ();
        show_all ();
    }

    private void update_view () {
        hidden = model.hidden;
        color = model.color;
        old_color = color;
    }

    private void create_ui () {
        margin_top = margin_bottom = 5;

        color_chooser = new Gtk.Grid ();
        color_chooser.hexpand = true;
        color_chooser.margin_end = 5;

        color_popover = new Gtk.Popover (color_picker);
        color_popover.position = Gtk.PositionType.BOTTOM;

        selected_color = new Gtk.MenuButton ();
        selected_color.remove (selected_color.get_child ());
        selected_color.vexpand = true;
        selected_color.width_request = 40;
        selected_color.can_focus = false;
        selected_color.get_style_context ().add_class ("selected-color");
        selected_color.popover = color_popover;

        var picker_container = new Gtk.Grid ();
        picker_container.margin_end = 10;
        picker_container.margin_top = picker_container.margin_bottom = 1;
        picker_container.get_style_context ().add_class ("bg-pattern");
        picker_container.add (selected_color);

        color_container = new Gtk.Entry ();
        color_container.margin_end = 10;
        color_container.width_chars = 8;
        color_container.max_length = 7;
        color_container.hexpand = true;
        color_container.text = Utils.Color.rgba_to_hex (color);

        color_container.bind_property (
            "text", model, "color",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            // this => model
            (binding, color_container_value, ref model_value) => {
                color_set_manually = false;
                var color_container_hex = color_container_value.dup_string ();

                if (!Utils.Color.is_valid_hex (color_container_hex)) {
                    model_value.set_string (Utils.Color.rgba_to_hex (old_color));
                    return false;
                }

                var new_color_rgba = Utils.Color.hex_to_rgba (color_container_hex);
                model_value.set_string (new_color_rgba);
                return true;
            },
            // model => this
            (binding, model_value, ref color_container_value) => {
                var model_rgba = model_value.dup_string ();
                old_color = model_rgba;
                color_container_value.set_string (Utils.Color.rgba_to_hex (model_rgba));
                return true;
            }
        );

        color_container.delete_text.connect ((start_pos, end_pos) => {
            if (end_pos == -1) {
                // We are replacing the string from the internal
                // Not by manually selecting the text, so we don't need to check anything
                return;
            }

            string new_text = color_container.text.splice (start_pos, end_pos);

            if (!new_text.contains ("#")) {
                GLib.Signal.stop_emission_by_name (color_container, "delete-text");
            }
        });

        color_container.insert_text.connect ((_new_text, new_text_length) => {
            string new_text = _new_text.strip ();

            if (new_text.contains ("#")) {
                new_text = new_text.substring (1, new_text.length - 1);
            }

            bool is_valid_hex = true;

            bool char_is_numeric = true;
            bool char_is_valid_alpha = true;

            char keyval;

            for (var i = 0; i < new_text.length; i++) {
                keyval = new_text [i];

                char_is_numeric = keyval >= Gdk.Key.@0 && keyval <= Gdk.Key.@9;
                char_is_valid_alpha = keyval >= Gdk.Key.A && keyval <= Gdk.Key.F;

                is_valid_hex &= keyval.isxdigit ();
            }

            if (!is_valid_hex) {
                GLib.Signal.stop_emission_by_name (color_container, "insert-text");
                return;
            }
        });

        tickness_container = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PIXEL, 7, true, true);
        tickness_container.entry.sensitive = true;
        tickness_container.entry.text = border_size.to_string ();

        tickness_container.entry.bind_property (
            "text", model, "border_size",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            // this => model
            (binding, entry_text_val, ref model_border_val) => {
                int src = int.parse (entry_text_val.dup_string ());
                if (src < 0) {
                    src = 0;
                    tickness_container.entry.text = "0";
                }
                model_border_val.set_int (src);
                return true;
            }
        );

        color_chooser.attach (picker_container, 0, 0, 1, 1);
        color_chooser.attach (color_container, 1, 0, 1, 1);
        color_chooser.attach (tickness_container, 2, 0, 1, 1);

        hidden_button = new Gtk.Button ();
        hidden_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hidden_button.get_style_context ().add_class ("button-rounded");
        hidden_button.can_focus = false;
        hidden_button.valign = Gtk.Align.CENTER;

        delete_button = new Gtk.Button ();
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.get_style_context ().add_class ("button-rounded");
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR));

        color_chooser_widget = new Gtk.ColorChooserWidget ();
        color_chooser_widget.hexpand = true;
        color_chooser_widget.show_editor = true;

        color_picker = new Gtk.Grid ();
        color_picker.get_style_context ().add_class ("color-picker");
        color_picker.attach (color_chooser_widget, 0, 0, 1, 1);
        color_picker.show_all ();
        color_popover.add (color_picker);

        attach (color_chooser, 0, 0, 1, 1);
        attach (hidden_button, 1, 0, 1, 1);
        attach (delete_button, 2, 0, 1, 1);

        set_color_chooser_color ();
        set_button_color ();
    }

    private void create_event_bindings () {
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);
        model.notify.connect (on_model_changed);
        color_chooser_widget.notify["rgba"].connect (on_color_changed);
    }

    private void on_model_changed () {
        model.item.reset_colors ();
        set_button_color ();
        set_color_chooser_color ();
    }

    private void on_color_changed () {
        color_set_manually = true;
        color = color_chooser_widget.rgba.to_string ();
        alpha = ((int)(color_chooser_widget.rgba.alpha * 255));
    }

    private void on_delete_item () {
        model.list_model.remove_item.begin (model);
        model.item.reset_colors ();
        window.event_bus.border_deleted ();
    }

    private void set_hidden_button () {
        if (hidden_button_icon != null) {
            hidden_button.remove (hidden_button_icon);
        }

        hidden_button_icon = new Gtk.Image.from_icon_name (
            "layer-%s-symbolic".printf (hidden ? "hidden" : "visible"),
            Gtk.IconSize.SMALL_TOOLBAR);

        hidden_button.add (hidden_button_icon);
        hidden_button_icon.show_all ();
    }

    private void toggle_visibility () {
        hidden = !hidden;
        toggle_ui_visibility ();
    }

    private void toggle_ui_visibility () {
        if (hidden) {
            get_style_context ().add_class ("disabled");
            return;
        }

        get_style_context ().remove_class ("disabled");
    }

    private void set_button_color () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = selected_color.get_style_context ();
            var new_color = color_chooser_widget.rgba.to_string ();

            var css = """.selected-color {
                    background-color: %s;
                    border-color: shade (%s, 0.75);
                }""".printf (new_color, new_color);

            provider.load_from_data (css, css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }

    private void set_color_chooser_color () {
        // Prevent infinite loop by checking whether the color
        // has been set manually or not
        if (color_set_manually) {
            return;
        }

        var new_rgba = Gdk.RGBA ();
        new_rgba.parse (color);
        new_rgba.alpha = (double) alpha / 255;

        color_chooser_widget.set_rgba (new_rgba);
    }
}

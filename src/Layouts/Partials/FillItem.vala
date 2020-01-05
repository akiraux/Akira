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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

public class Akira.Layouts.Partials.FillItem : Gtk.Grid {
    private Gtk.Grid fill_chooser;
    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;
    //  private Gtk.Button selected_blending_mode_cont;
    //  private Gtk.Label selected_blending_mode;
    private Gtk.MenuButton selected_color;
    public Akira.Partials.InputField opacity_container;
    public Gtk.Entry color_container;
    private Gtk.Popover color_popover;
    private Gtk.Grid color_picker;
    private Gtk.ColorChooserWidget color_chooser_widget;

    public Akira.Models.FillsItemModel model { get; construct; }

    //  private Akira.Utils.BlendingMode blending_mode {
    //      owned get {
    //          return model.blending_mode;
    //      }
    //      set {
    //          model.blending_mode = value;
    //          selected_blending_mode.label = model.blending_mode.get_name ();
    //      }
    //  }

    private string old_color;
    private bool color_set_manually = false;
    private string color {
        owned get {
            return model.color;
        } set {
            model.color = value;

            set_button_color ();
        }
    }

    private int alpha {
        owned get {
            return model.alpha;
        } set {
            model.alpha = value;

            set_button_color ();
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

    private bool updating { get; set; default = false; }

    public signal void remove_item (Akira.Models.FillsItemModel model);

    public FillItem (Akira.Models.FillsItemModel model) {
        Object (model: model);
    }

    construct {
        create_ui ();

        // Update view BEFORE event bindings in order
        // not to trigger bindings on first assignment.
        update_view ();

        create_event_bindings ();
        show_all ();
    }

    private void update_view () {
        hidden = model.hidden;
        //  blending_mode = model.blending_mode;
        color = model.color;
        old_color = color;
    }

    private void create_ui () {
        margin_top = margin_bottom = 5;

        fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;
        fill_chooser.margin_end = 5;

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
        //color_container.text = Utils.Color.rgba_to_hex (color);

        color_container.bind_property (
            "text", model, "color",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            // this => model
            (binding, color_container_value, ref model_value) => {
                var color_container_hex = color_container_value.dup_string ();

                if (!Utils.Color.is_valid_hex (color_container_hex)) {
                    model_value.set_string (Utils.Color.rgba_to_hex (old_color));
                    return false;
                }

                color_set_manually = true;

                var new_color_rgba = Utils.Color.hex_to_rgba (color_container_hex);

                model_value.set_string (new_color_rgba);
                set_button_color (color_container_hex);

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

        //  selected_blending_mode = new Gtk.Label ("");
        //  selected_blending_mode.hexpand = true;
        //  selected_blending_mode.halign = Gtk.Align.START;

        //  selected_blending_mode_cont = new Gtk.Button ();
        //  selected_blending_mode_cont.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        //  selected_blending_mode_cont.can_focus = false;
        //  selected_blending_mode_cont.hexpand = true;
        //  selected_blending_mode_cont.add (selected_blending_mode);

        opacity_container = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_container.entry.sensitive = true;
        opacity_container.entry.text = Math. round ((double) alpha / 255 * 100).to_string ();
        opacity_container.entry.bind_property (
            "text", model, "alpha",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            (binding, entry_text_val, ref model_alpha_val) => {
                double src = double.parse (entry_text_val.dup_string ());

                if (src > 100) {
                    src = 100.0;
                    opacity_container.entry.text = "100";
                } else if (src < 0) {
                    src = 0.0;
                    opacity_container.entry.text = "0";
                }

                color_set_manually = true;

                int alpha_int_value = (int) (src / 100 * 255);

                model_alpha_val.set_int (alpha_int_value);

                set_button_color (null, alpha_int_value);

                return true;
            }, (binding, model_alpha_val, ref entry_text_val) => {
                double src = (double) model_alpha_val.get_int () / 255;

                src = Math.round (src * 100);

                entry_text_val.set_string (("%f").printf (src * 100));

                return true;
            }
        );

        fill_chooser.attach (picker_container, 0, 0, 1, 1);
        fill_chooser.attach (color_container, 1, 0, 1, 1);
        //  fill_chooser.attach (selected_blending_mode_cont, 1, 0, 1, 1);
        fill_chooser.attach (opacity_container, 2, 0, 1, 1);

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

        //  blending_mode_popover_items = new Gtk.ListBox ();
        //  blending_mode_popover_items.get_style_context ().add_class ("popover-list");

        color_chooser_widget = new Gtk.ColorChooserWidget ();
        color_chooser_widget.hexpand = true;
        color_chooser_widget.show_editor = true;
        set_color_chooser_color ();

        color_picker = new Gtk.Grid ();
        color_picker.get_style_context ().add_class ("color-picker");
        color_picker.attach (color_chooser_widget, 0, 0, 1, 1);
        color_picker.show_all ();
        color_popover.add (color_picker);

        //  var popover_item_index = 0;

        //  foreach (Akira.Utils.BlendingMode mode in Akira.Utils.BlendingMode.all () ) {
        //      blending_mode_popover_items.insert (
        //          new Akira.Layouts.Partials.BlendingModeItem (mode),
        //          popover_item_index++
        //      );
        //  }

        attach (fill_chooser, 0, 0, 1, 1);
        attach (hidden_button, 1, 0, 1, 1);
        attach (delete_button, 2, 0, 1, 1);
    }

    private void create_event_bindings () {
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);

        //  blending_mode_popover_items.row_activated.connect (on_row_activated);
        //  blending_mode_popover_items.row_selected.connect (on_popover_item_selected);

        color_chooser_widget.notify["rgba"].connect (on_color_changed);
    }

    private void on_color_changed () {
        var selected_color = color_chooser_widget.rgba;

        color = selected_color.to_string ();
    }

    //  private void on_row_activated (Gtk.ListBoxRow? item) {
    //      var fillItem = (Akira.Layouts.Partials.BlendingModeItem)item.get_child ();
    //      blending_mode = fillItem.mode;
    //      popover.hide ();
    //  }

    //  private void on_popover_item_selected (Gtk.ListBoxRow? item) {
    //  }

    private void on_delete_item () {
        remove_item (model);
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
        } else {
            get_style_context ().remove_class ("disabled");
        }
    }

    private void set_button_color (string? _button_color = null, int? _alpha_int = null) {
        var button_color = color;
        var button_alpha = (double) alpha / 255;

        if (_button_color != null) {
            button_color = (string) _button_color;
        }

        if (_alpha_int != null) {
            button_alpha = (double) ((int) _alpha_int) / 255;
        }

        // Ensure button_color has alpha = 1
        // real alpha is given by item's alpha
        var button_color_rgba_no_alpha = Gdk.RGBA ();
        button_color_rgba_no_alpha.parse (button_color);

        button_color_rgba_no_alpha.alpha = 1.0;

        button_color = button_color_rgba_no_alpha.to_string ();

        try {
            var provider = new Gtk.CssProvider ();
            var context = selected_color.get_style_context ();

            var alpha_dot_separator = button_alpha.to_string ().replace (",", ".");

            var css = """.selected-color {
                    background-color: alpha (%s, %s);
                    border-color: alpha (shade (%s, 0.75), %s);
                }""".printf (button_color, alpha_dot_separator, button_color, alpha_dot_separator);

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
            color_set_manually = false;
            return;
        }

        var new_rgba = Gdk.RGBA ();

        new_rgba.parse (model.color);
        new_rgba.alpha = (double) alpha / 255;

        color_chooser_widget.set_rgba (new_rgba);
    }
}

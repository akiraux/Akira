/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 * Authored by: Ivan "isneezy" Vilanculo <ivilanculo@gmail.com>
 */

public class Akira.Layouts.Partials.FillItem : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    private Gtk.Grid fill_chooser;
    private Gtk.Button eyedropper_button;
    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;
    private Gtk.Button selected_color;
    private Akira.Partials.InputField opacity_container;
    private Akira.Partials.ColorField color_container;
    private Gtk.Popover color_popover;
    private Gtk.Grid color_picker;
    private Gtk.ColorChooserWidget? color_chooser_widget = null;
    private Akira.Utils.ColorPicker eyedropper;

    private Gtk.FlowBox global_colors_flowbox;

    public Akira.Models.FillsItemModel model { get; construct; }

    /*
     * Type of color containers to add new colors to. We can potentially create
     * an API to allow adding more containers to the color picker popup.
     */
    private enum Container {
        GLOBAL,
        DOCUMENT
    }

    private string old_color;

    // If the color or alpha are manually set from the ColorPicker.
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

    private bool hidden {
        owned get {
            return model.hidden;
        } set {
            model.hidden = value;
            set_hidden_button ();
            toggle_ui_visibility ();
        }
    }

    public FillItem (Akira.Window window, Akira.Models.FillsItemModel model) {
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

        fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;
        fill_chooser.margin_end = 5;

        var selected_color_container = new Gtk.Grid ();
        var context = selected_color_container.get_style_context ();
        context.add_class ("selected-color-container");
        context.add_class ("bg-pattern");

        selected_color = new Gtk.Button ();
        selected_color.vexpand = true;
        selected_color.width_request = 40;
        selected_color.can_focus = false;
        selected_color.get_style_context ().add_class ("selected-color");
        selected_color.set_tooltip_text (_("Choose fill color"));

        color_popover = new Gtk.Popover (selected_color);
        color_popover.position = Gtk.PositionType.BOTTOM;

        selected_color.clicked.connect (() => {
            init_color_chooser ();
            color_popover.popup ();
        });

        selected_color_container.add (selected_color);
        set_button_color ();

        eyedropper_button = new Gtk.Button ();
        eyedropper_button.get_style_context ().add_class ("color-picker-button");
        eyedropper_button.can_focus = false;
        eyedropper_button.valign = Gtk.Align.CENTER;
        eyedropper_button.set_tooltip_text (_("Pick color"));
        eyedropper_button.add (new Gtk.Image.from_icon_name ("color-select-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR));

        var picker_container = new Gtk.Grid ();
        picker_container.margin_end = 10;
        picker_container.margin_top = picker_container.margin_bottom = 1;
        picker_container.add (selected_color_container);
        picker_container.add (eyedropper_button);

        color_container = new Akira.Partials.ColorField (window);
        color_container.text = Utils.Color.rgba_to_hex (color);

        model.bind_property (
            "color", color_container, "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            // model => this
            (binding, model_value, ref color_container_value) => {
                var model_rgba = model_value.dup_string ();
                old_color = model_rgba;
                color_container_value.set_string (Utils.Color.rgba_to_hex (model_rgba));
                return true;
            },
            // this => model
            (binding, color_container_value, ref model_value) => {
                color_set_manually = false;
                var color_container_hex = color_container_value.dup_string ();
                if (!Utils.Color.is_valid_hex (color_container_hex)) {
                    model_value.set_string (Utils.Color.rgba_to_hex (old_color));
                    return false;
                }
                var new_color_rgba = Utils.Color.hex_to_rgba (color_container_hex);
                new_color_rgba.alpha = alpha / 100;
                model_value.set_string (new_color_rgba.to_string ());
                return true;
            }
        );

        opacity_container = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_container.entry.sensitive = true;
        opacity_container.entry.value = Math.round ((double) alpha / 255 * 100);

        opacity_container.entry.bind_property (
            "value", model, "alpha",
            BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                color_set_manually = false;
                targetval.set_int ((int) ((double) srcval / 100 * 255));
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_double ((srcval.get_int () * 100) / 255);
                return true;
            });

        fill_chooser.attach (picker_container, 0, 0, 1, 1);
        fill_chooser.attach (color_container, 1, 0, 1, 1);
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
        delete_button.set_tooltip_text (_("Remove fill color"));
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR));

        attach (fill_chooser, 0, 0, 1, 1);
        attach (hidden_button, 1, 0, 1, 1);
        attach (delete_button, 2, 0, 1, 1);
    }

    private void init_color_chooser () {
        if (color_chooser_widget != null) {
            return;
        }

        color_chooser_widget = new Gtk.ColorChooserWidget ();
        color_chooser_widget.hexpand = true;
        color_chooser_widget.show_editor = true;

        color_picker = new Gtk.Grid ();
        color_picker.get_style_context ().add_class ("color-picker");
        color_picker.row_spacing = 12;

        var global_colors_label = new Gtk.Label (_("Global colors"));
        global_colors_label.halign = Gtk.Align.START;
        global_colors_label.margin_start = global_colors_label.margin_end = 6;

        global_colors_flowbox = new Gtk.FlowBox ();
        global_colors_flowbox.get_style_context ().add_class ("color-grid");
        global_colors_flowbox.selection_mode = Gtk.SelectionMode.NONE;
        global_colors_flowbox.homogeneous = false;
        global_colors_flowbox.column_spacing = global_colors_flowbox.row_spacing = 6;
        global_colors_flowbox.margin_start = global_colors_flowbox.margin_end = 6;
        // Large number to allow children to spread out the available space.
        global_colors_flowbox.max_children_per_line = 100;
        global_colors_flowbox.set_sort_func (sort_colors_function);

        var add_global_color_btn = new Akira.Partials.AddColorButton ();
        add_global_color_btn.clicked.connect (() => {
            on_save_color (Container.GLOBAL);
        });
        global_colors_flowbox.add (add_global_color_btn);

        foreach (string color in settings.global_colors) {
            var btn = create_color_button (color);
            global_colors_flowbox.add (btn);
        }

        color_picker.attach (color_chooser_widget, 0, 0, 1, 1);
        color_picker.attach (global_colors_label, 0, 1, 1, 1);
        color_picker.attach (global_colors_flowbox, 0, 2, 1, 1);
        color_picker.show_all ();
        color_popover.add (color_picker);

        set_color_chooser_color ();
        color_chooser_widget.notify["rgba"].connect (on_color_changed);
    }

    private void create_event_bindings () {
        eyedropper_button.clicked.connect (on_eyedropper_click);
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);
    }

    /*
     * Add the current color to the parent flowbox.
     */
    private void on_save_color (Container parent) {
        // Store the currently active color.
        var color = color_chooser_widget.rgba.to_string ();

        // Create the new color button and connect to its signal.
        var btn = create_color_button (color);

        // Update the colors list and the schema based on the colors container.
        switch (parent) {
            case Container.GLOBAL:
                global_colors_flowbox.add (btn);
                var array = settings.global_colors;
                array += color;
                settings.global_colors = array;
                break;

            case Container.DOCUMENT:
                // TODO...
                break;
        }
    }

    private Gtk.FlowBoxChild create_color_button (string color) {
        var child = new Gtk.FlowBoxChild ();
        child.valign = child.halign = Gtk.Align.CENTER;

        var btn = new Akira.Partials.RoundedColorButton (color);
        btn.set_color.connect ((color) => {
            var rgba_color = Gdk.RGBA ();
            rgba_color.parse (color);
            color_chooser_widget.set_rgba (rgba_color);
        });

        child.add (btn);
        child.show_all ();
        return child;
    }

    private void on_eyedropper_click () {
        eyedropper = new Akira.Utils.ColorPicker ();
        eyedropper.show_all ();

        eyedropper.picked.connect ((picked_color) => {
            init_color_chooser ();
            color_chooser_widget.set_rgba (picked_color);
            eyedropper.close ();
        });

        eyedropper.cancelled.connect (() => {
            eyedropper.close ();
        });
    }

    private void on_color_changed () {
        color_set_manually = true;
        color = color_chooser_widget.rgba.to_string ();
        alpha = ((int)(color_chooser_widget.rgba.alpha * 255));
        set_button_color ();
    }

    private void on_delete_item () {
        model.model.remove_item.begin (model);
        // Actually remove the Fill component only if the user requests it.
        model.fill.remove ();
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
            hidden_button.set_tooltip_text (_("Show fill color"));
            return;
        }

        hidden_button.set_tooltip_text (_("Hide fill color"));
        get_style_context ().remove_class ("disabled");
    }

    private void set_button_color () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = selected_color.get_style_context ();

            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (color);
            new_rgba.alpha = (double) alpha / 255;
            var new_color = new_rgba.to_string ();

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

    private int sort_colors_function (Gtk.FlowBoxChild a, Gtk.FlowBoxChild b) {
        return (a is Akira.Partials.AddColorButton) ? -1 : 1;
    }
}

/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 * Helper class to quickly create a container with a color button and a color
 * picker. The color button opens up the Gtk Color chooser.
 */
public class Akira.Widgets.ColorButton : Gtk.Grid {
    private unowned Akira.Window window;
    private unowned Models.FillsItemModel model;

    private Gtk.Button color_button;
    private Gtk.Popover color_popover;
    private Gtk.ColorChooserWidget? color_chooser_widget = null;
    private Gtk.FlowBox global_colors_flowbox;

    /*
     * If the color or alpha are manually set from the ColorPicker.
     * If true, the ColorChooserWidget doesn't need to be updated.
     */
    public bool color_set_manually = false;

    /*
     * Keep track of the current color when the user is updating the string
     * and the format is not valid.
     */
    private string old_color;

    /*
     * Type of color containers to add new colors to. We can potentially create
     * an API to allow adding more containers to the color picker popup.
     */
    private enum Container {
        GLOBAL,
        DOCUMENT
    }

    public ColorButton (Akira.Window window, Models.FillsItemModel model) {
        this.window = window;
        this.model = model;
        old_color = model.color;

        margin_top = margin_bottom = 1;

        var container = new Gtk.Grid ();
        var context = container.get_style_context ();
        context.add_class ("selected-color-container");
        context.add_class ("bg-pattern");

        color_button = new Gtk.Button ();
        color_button.vexpand = true;
        color_button.width_request = 40;
        color_button.can_focus = false;
        color_button.get_style_context ().add_class ("selected-color");
        color_button.set_tooltip_text (_("Choose fill color"));

        color_popover = new Gtk.Popover (color_button);
        color_popover.position = Gtk.PositionType.BOTTOM;

        color_button.clicked.connect (() => {
            init_color_chooser ();
            color_popover.popup ();
        });

        container.add (color_button);
        set_button_color ();

        // Define the eye dropper button.
        var eyedropper_button = new Gtk.Button ();
        eyedropper_button.get_style_context ().add_class ("color-picker-button");
        eyedropper_button.can_focus = false;
        eyedropper_button.valign = Gtk.Align.CENTER;
        eyedropper_button.set_tooltip_text (_("Pick color"));
        eyedropper_button.add (
            new Gtk.Image.from_icon_name ("color-select-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR)
        );
        eyedropper_button.clicked.connect (on_eyedropper_click);

        add (container);
        add (eyedropper_button);

        var field = new ColorField (window);
        field.text = Utils.Color.rgba_to_hex (model.color);

        model.bind_property (
            "color", field, "text",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            // model => this
            (binding, model_value, ref field_value) => {
                var model_rgba = model_value.dup_string ();
                old_color = model_rgba;
                field_value.set_string (Utils.Color.rgba_to_hex (model_rgba));
                return true;
            },
            // this => model
            (binding, field_value, ref model_value) => {
                color_set_manually = false;
                var field_hex = field_value.dup_string ();
                if (!Utils.Color.is_valid_hex (field_hex)) {
                    model_value.set_string (Utils.Color.rgba_to_hex (old_color));
                    return false;
                }
                var new_color_rgba = Utils.Color.hex_to_rgba (field_hex);
                new_color_rgba.alpha = model.alpha / 100;
                model_value.set_string (new_color_rgba.to_string ());
                return true;
            }
        );

        add (field);
    }

    private void init_color_chooser () {
        if (color_chooser_widget != null) {
            return;
        }

        color_chooser_widget = new Gtk.ColorChooserWidget ();
        color_chooser_widget.hexpand = true;
        color_chooser_widget.show_editor = true;

        var color_grid = new Gtk.Grid ();
        color_grid.get_style_context ().add_class ("color-picker");
        color_grid.row_spacing = 12;

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

        var add_global_color_btn = new Widgets.AddColorButton ();
        add_global_color_btn.clicked.connect (() => {
            on_save_color (Container.GLOBAL);
        });
        global_colors_flowbox.add (add_global_color_btn);

        foreach (string color in settings.global_colors) {
            var btn = create_color_button (color);
            global_colors_flowbox.add (btn);
        }

        color_grid.attach (color_chooser_widget, 0, 0, 1, 1);
        color_grid.attach (global_colors_label, 0, 1, 1, 1);
        color_grid.attach (global_colors_flowbox, 0, 2, 1, 1);
        color_grid.show_all ();
        color_popover.add (color_grid);

        set_color_chooser_color ();
        color_chooser_widget.notify["rgba"].connect (on_color_changed);
    }

    private int sort_colors_function (Gtk.FlowBoxChild a, Gtk.FlowBoxChild b) {
        return (a is AddColorButton) ? -1 : 1;
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

    private void set_button_color () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = color_button.get_style_context ();

            var new_rgba = Gdk.RGBA ();
            new_rgba.parse (model.color);
            new_rgba.alpha = (double) model.alpha / 255;
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

    private Gtk.FlowBoxChild create_color_button (string color) {
        var child = new Gtk.FlowBoxChild ();
        child.valign = child.halign = Gtk.Align.CENTER;

        var btn = new Widgets.RoundedColorButton (color);
        btn.set_color.connect ((color) => {
            var rgba_color = Gdk.RGBA ();
            rgba_color.parse (color);
            color_chooser_widget.set_rgba (rgba_color);
        });

        child.add (btn);
        child.show_all ();
        return child;
    }

    private void set_color_chooser_color () {
        // Prevent infinite loop by checking whether the color has been manually
        // set or not.
        if (color_set_manually) {
            return;
        }

        var new_rgba = Gdk.RGBA ();
        new_rgba.parse (model.color);
        new_rgba.alpha = (double) model.alpha / 255;

        color_chooser_widget.set_rgba (new_rgba);
    }

    private void on_color_changed () {
        color_set_manually = true;
        model.color = color_chooser_widget.rgba.to_string ();
        model.alpha = ((int)(color_chooser_widget.rgba.alpha * 255));
        set_button_color ();
    }

    private void on_eyedropper_click () {
        var eyedropper = new Akira.Utils.ColorPicker ();
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
}

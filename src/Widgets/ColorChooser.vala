/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 */

/*
 * Helper class to create a container for the GtkColorChooser.
 */
public class Akira.Widgets.ColorChooser : Gtk.Grid {
    public signal void pattern_changed (Lib.Components.Pattern pattern);

    private Gtk.ColorChooserWidget chooser;
    private Gtk.FlowBox global_flowbox;
    private GradientEditor gradient_editor;
    private PatternTypeChooser pattern_chooser;

    /*
     * Type of color containers to add new colors to. We can potentially create
     * an API to allow adding more containers to the color picker popup.
     */
    private enum Container {
        GLOBAL,
        DOCUMENT
    }

    public ColorChooser (Models.ColorModel model, Window window) {
        margin_top = margin_bottom = 12;
        margin_start = margin_end = 3;
        row_spacing = 12;
        get_style_context ().add_class ("color-picker");

        pattern_chooser = new PatternTypeChooser (model, window);
        attach (pattern_chooser, 0, 0, 1, 1);

        gradient_editor = new GradientEditor (model.pattern);
        attach (gradient_editor, 0, 1, 1, 1);

        pattern_chooser.pattern_changed.connect ((pattern) => {
            gradient_editor.set_pattern (pattern);
        });

        gradient_editor.pattern_edited.connect ((pattern) => {
            model.pattern = pattern;
        });

        chooser = new Gtk.ColorChooserWidget () {
            hexpand = true,
            show_editor = true
        };
        chooser.notify["rgba"].connect (on_color_changed);

        attach (chooser, 0, 2, 1, 1);

        var global_label = new Gtk.Label (_("Global colors")) {
            halign = Gtk.Align.START,
            margin_start = margin_end = 6
        };
        attach (global_label, 0, 3, 1, 1);

        global_flowbox = new Gtk.FlowBox () {
            selection_mode = Gtk.SelectionMode.NONE,
            homogeneous = false,
            column_spacing = row_spacing = 6,
            margin_start = margin_end = 6,
            // Large number to allow children to spread out the available space.
            max_children_per_line = 100,
        };
        global_flowbox.get_style_context ().add_class ("color-grid");
        global_flowbox.set_sort_func (sort_colors_function);

        var add_global_color_btn = new AddColorButton ();
        add_global_color_btn.clicked.connect (() => {
            on_save_color (Container.GLOBAL);
        });
        global_flowbox.add (add_global_color_btn);

        foreach (string color in settings.global_colors) {
            var btn = create_color_button (color);
            global_flowbox.add (btn);
        }

        attach (global_flowbox, 0, 4, 1, 1);
        show_all ();
    }

    /*
     * Add the current color to the parent flowbox.
     */
    private void on_save_color (Container parent) {
        // Get the currently active color.
        var color = chooser.rgba.to_string ();

        // Create the new color button and connect to its signal.
        var btn = create_color_button (color);

        // Update the colors list and the schema based on the colors container.
        switch (parent) {
            case Container.GLOBAL:
                global_flowbox.add (btn);
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
        var child = new Gtk.FlowBoxChild () {
            valign = halign = Gtk.Align.CENTER
        };

        var btn = new RoundedColorButton (color);
        btn.set_color.connect ((color) => {
            var rgba_color = Gdk.RGBA ();
            rgba_color.parse (color);
            chooser.set_rgba (rgba_color);
        });

        child.add (btn);
        child.show_all ();
        return child;
    }

    private int sort_colors_function (Gtk.FlowBoxChild a, Gtk.FlowBoxChild b) {
        return (a is AddColorButton) ? -1 : 1;
    }

    public void set_pattern (Lib.Components.Pattern pattern) {
        pattern_chooser.pattern_changed (pattern);
        gradient_editor.pattern_edited (pattern);
    }

    private void on_color_changed () {
        gradient_editor.color_changed (chooser.get_rgba ());
    }
}

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
    public class SignalBlocker {
        private unowned ColorChooser chooser;

        public SignalBlocker (ColorChooser fill_chooser) {
            chooser = fill_chooser;
            chooser.block_signal += 1;
        }

        ~SignalBlocker () {
            chooser.block_signal -= 1;
        }
    }

    protected int block_signal = 0;

    public signal void color_changed (Gdk.RGBA color);

    private Gtk.ColorChooserWidget chooser;
    private Gtk.FlowBox global_flowbox;

    /*
     * Type of color containers to add new colors to. We can potentially create
     * an API to allow adding more containers to the color picker popup.
     */
    private enum Container {
        GLOBAL,
        DOCUMENT
    }

    public ColorChooser () {
        margin_top = margin_bottom = 12;
        margin_start = margin_end = 3;
        row_spacing = 12;
        get_style_context ().add_class ("color-picker");

        chooser = new Gtk.ColorChooserWidget () {
            hexpand = true,
            show_editor = true
        };
        chooser.notify["rgba"].connect (on_color_changed);

        attach (chooser, 0, 0, 1, 1);

        var global_label = new Gtk.Label (_("Global colors")) {
            halign = Gtk.Align.START,
            margin_start = margin_end = 6
        };
        attach (global_label, 0, 1, 1, 1);

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

        attach (global_flowbox, 0, 2, 1, 1);
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

    public void set_color (Gdk.RGBA color) {
        var blocker = new SignalBlocker (this);
        (blocker);
        chooser.set_rgba (color);
    }

    private void on_color_changed () {
        if (block_signal > 0) {
            return;
        }
        color_changed (chooser.get_rgba ());
    }
}

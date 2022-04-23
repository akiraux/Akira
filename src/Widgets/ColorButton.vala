/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Widget to create a reusable color button that triggers a color chooser
 * when clicked.
*/
public class Akira.Widgets.ColorButton : Gtk.Button {
    private unowned Models.ColorModel model;
    private unowned Window window;

    private Gtk.Popover color_popover;
    private Widgets.ColorChooser? color_chooser = null;

    private string? current_color = null;

    public class SignalBlocker {
        private unowned ColorButton item;

        public SignalBlocker (ColorButton fill_item) {
            item = fill_item;
            item.block_signal += 1;
        }

        ~SignalBlocker () {
            item.block_signal -= 1;
        }
    }

    protected int block_signal = 0;

    public ColorButton (Window window) {
        this.window = window;

        get_style_context ().add_class ("selected-color");
        vexpand = true;
        width_request = 40;
        can_focus = false;
        tooltip_text = _("Choose color");

        color_popover = new Gtk.Popover (this) {
            position = Gtk.PositionType.BOTTOM
        };

        clicked.connect (on_clicked);

        color_popover.closed.connect (() => {
            window.event_bus.change_gradient_nobs_visibility (true);
        });
    }

    ~ColorButton () {
        model.value_changed.disconnect (on_model_changed);
    }

    public void assign (Models.ColorModel model) {
        this.model = model;
        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    /*
     * Update the color of the button when the model changed.
     */
    private void on_model_changed () {
        sensitive = !model.hidden;

        //  var new_color = model.color.to_string ();
        var new_color = model.pattern.get_first_color ().to_string ();
        if (new_color == current_color) {
            return;
        }

        try {
            var provider = new Gtk.CssProvider ();
            var context = get_style_context ();

            var css = """.selected-color {
                    background-color: %s;
                    border-color: shade (%s, 0.75);
                }""".printf (new_color, new_color);

            provider.load_from_data (css, css.length);
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            current_color = new_color;
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }

    private void init_color_chooser () {
        if (color_chooser != null) {
            return;
        }

        color_chooser = new ColorChooser (model, window);
        color_chooser.pattern_changed.connect (pattern => {
            if (block_signal > 0) {
                return;
            }
            model.pattern = pattern;
        });
        color_popover.add (color_chooser);
    }

    private void on_clicked () {
        if (color_chooser == null) {
            init_color_chooser ();
        }

        var blocker = new SignalBlocker (this);
        (blocker);

        color_chooser.set_pattern (model.pattern);
        color_popover.popup ();

        window.event_bus.change_gradient_nobs_visibility (true);
    }
}

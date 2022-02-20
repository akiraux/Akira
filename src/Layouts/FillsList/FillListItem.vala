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
 * The single color fill row.
 */
public class Akira.Layouts.FillsList.FillListItem : VirtualizingListBoxRow {
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    private FillItemModel model;

    private Gtk.Popover color_popover;
    private Gtk.Button color_button;
    private Gtk.Button eyedropper_button;
    private Gtk.Button hide_button;
    private Gtk.Button delete_button;
    private Widgets.ColorField color_field;
    private Widgets.InputField opacity_field;
    private Widgets.ColorPicker? eyedropper = null;
    private Widgets.ColorChooser? color_chooser = null;

    public class SignalBlocker {
        private unowned FillListItem item;

        public SignalBlocker (FillListItem fill_item) {
            item = fill_item;
            item.block_signal += 1;
        }

        ~SignalBlocker () {
            item.block_signal -= 1;
        }
    }

    protected int block_signal = 0;

    public FillListItem (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        var grid = new Gtk.Grid () {
            margin = 3
        };

        var container = new Gtk.Grid ();
        var context = container.get_style_context ();
        context.add_class ("selected-color-container");
        context.add_class ("bg-pattern");

        color_button = new Gtk.Button () {
            vexpand = true,
            width_request = 40,
            can_focus = false,
            tooltip_text = _("Choose color")
        };
        color_button.get_style_context ().add_class ("selected-color");

        color_popover = new Gtk.Popover (color_button) {
            position = Gtk.PositionType.BOTTOM
        };
        color_button.clicked.connect (on_color_button_clicked);
        container.add (color_button);

        eyedropper_button = new Gtk.Button () {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            tooltip_text = _("Pick color")
        };
        eyedropper_button.add (
            new Gtk.Image.from_icon_name ("color-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR)
        );
        eyedropper_button.get_style_context ().add_class ("color-picker-button");
        eyedropper_button.clicked.connect (on_eyedropper_click);

        grid.add (container);
        grid.add (eyedropper_button);

        color_field = new Widgets.ColorField (view_canvas);
        color_field.changed.connect (on_color_changed);
        grid.add (color_field);

        opacity_field = new Widgets.InputField (
            view_canvas, Widgets.InputField.Unit.PERCENTAGE, 5, true, true);
        opacity_field.entry.sensitive = true;
        opacity_field.entry.value_changed.connect (on_opacity_changed);
        grid.add (opacity_field);

        hide_button = new Gtk.Button () {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            margin_start = 3
        };
        hide_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hide_button.get_style_context ().add_class ("button-rounded");
        hide_button.clicked.connect (toggle_color_visibility);
        grid.add (hide_button);

        delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            valign = Gtk.Align.CENTER,
            can_focus = false,
            tooltip_text = _("Remove color"),
            margin_start = 3
        };
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.get_style_context ().add_class ("button-rounded");
        delete_button.clicked.connect (delete_fill);
        grid.add (delete_button);

        add (grid);
    }

    public void assign (FillItemModel data) {
        var blocker = new SignalBlocker (this);
        (blocker);

        model_item = data;
        model = (FillItemModel) model_item;

        set_button_color ();
        set_color_field ();
        set_opacity_field ();
        update_hide_button ();
    }

    private void set_color_field () {
        color_field.text = Utils.Color.rgba_to_hex_string (model.color);
    }

    private void set_opacity_field () {
        opacity_field.entry.value = Math.round (model.alpha * 100);
    }

    private void set_button_color () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = color_button.get_style_context ();
            var new_color = model.color.to_string ();

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

    private void on_color_changed () {
        if (block_signal > 0) {
            return;
        }

        var field_hex = color_field.text;
        // Interrupt if what's written is not a valid color value.
        if (!Utils.Color.is_valid_hex (field_hex)) {
            return;
        }

        // Since we will update the color picker, prevent an infinite loop.
        var blocker = new SignalBlocker (this);
        (blocker);

        var new_rgba = Utils.Color.hex_to_rgba (field_hex);
        model.color = new_rgba;
        set_button_color ();
    }

    private void on_opacity_changed () {
        if (block_signal > 0) {
            return;
        }

        double alpha = opacity_field.entry.value / 100;
        model.alpha = alpha;

        set_button_color ();
    }

    private void toggle_color_visibility () {
        model.is_color_hidden = !model.is_color_hidden;
        update_hide_button ();
    }

    private void update_hide_button () {
        if (model.is_color_hidden) {
            hide_button.get_style_context ().add_class ("active");
            hide_button.image = new Gtk.Image.from_icon_name ("layer-hidden-symbolic", Gtk.IconSize.MENU);
            hide_button.tooltip_text = _("Show color");
            get_style_context ().add_class ("disabled");
            selectable = false;
            color_button.sensitive = false;
            eyedropper_button.sensitive = false;
            color_field.sensitive = false;
            opacity_field.sensitive = false;
            return;
        }

        hide_button.get_style_context ().remove_class ("active");
        hide_button.image = new Gtk.Image.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU);
        hide_button.tooltip_text = _("Hide color");
        get_style_context ().remove_class ("disabled");
        selectable = true;
        color_button.sensitive = true;
        eyedropper_button.sensitive = true;
        color_field.sensitive = true;
        opacity_field.sensitive = true;
    }

    private void delete_fill () {
        model.delete ();
        view_canvas.window.main_window.refresh_fills ();
    }

    private void on_eyedropper_click () {
        if (eyedropper == null) {
            eyedropper = new Widgets.ColorPicker ();
        }
        eyedropper.show_all ();

        eyedropper.picked.connect ((picked_color) => {
            var blocker = new SignalBlocker (this);
            (blocker);

            model.color = picked_color;
            set_button_color ();
            set_color_field ();
            set_opacity_field ();
            eyedropper.close ();
        });

        eyedropper.cancelled.connect (() => {
            eyedropper.close ();
        });
    }

    private void init_color_chooser () {
        if (color_chooser != null) {
            return;
        }

        color_chooser = new Widgets.ColorChooser ();

        color_chooser.color_changed.connect (color => {
            model.color = color;
            var blocker = new SignalBlocker (this);
            (blocker);

            set_button_color ();
            set_color_field ();
            set_opacity_field ();
        });
        color_popover.add (color_chooser);
    }

    private void on_color_button_clicked () {
        if (color_chooser == null) {
            init_color_chooser ();
        }

        var blocker = new SignalBlocker (this);
        (blocker);
        color_chooser.set_color (model.color);
        color_popover.popup ();
    }
}

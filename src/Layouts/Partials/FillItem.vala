/*
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

    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;
    private Widgets.InputField opacity_container;
    private Widgets.ColorField color_container;

    public Akira.Models.FillsItemModel model { get; construct; }

    private string old_color;

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

        var fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;
        fill_chooser.margin_end = 5;

        var color_button = new Widgets.ColorButton (model);

        color_container = new Widgets.ColorField (window);
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
                color_button.color_set_manually = false;
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

        opacity_container = new Widgets.InputField (
            Widgets.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_container.entry.sensitive = true;
        opacity_container.entry.value = Math.round ((double) alpha / 255 * 100);

        opacity_container.entry.bind_property (
            "value", model, "alpha",
            BindingFlags.BIDIRECTIONAL,
            (binding, srcval, ref targetval) => {
                color_button.color_set_manually = false;
                targetval.set_int ((int) ((double) srcval / 100 * 255));
                return true;
            },
            (binding, srcval, ref targetval) => {
                targetval.set_double ((srcval.get_int () * 100) / 255);
                return true;
            });

        fill_chooser.attach (color_button, 0, 0, 1, 1);
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

    private void create_event_bindings () {
        // eyedropper_button.clicked.connect (on_eyedropper_click);
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);
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
}

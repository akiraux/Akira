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
    public Gtk.Entry opacity_container;
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

    private string color {
        owned get {
            return model.color;
        } set {
            model.color = value;

            set_button_color ();
        }
    }

    private double alpha {
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
        // not to trigger bindings on first assignment
        update_view ();

        create_event_bindings ();
        show_all ();
    }

    private void update_view () {
        alpha = model.alpha;
        hidden = model.hidden;
        //  blending_mode = model.blending_mode;
        color = model.color;
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
        color_container.text = color;
        color_container.bind_property (
            "text", model, "color",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        color_container.key_release_event.connect (() => {
            if (!color_container.text.contains ("#")) {
                var builder = new StringBuilder ();
                builder.append ("#");
                builder.append (color_container.text);
                color_container.text = builder.str;
                color_container.set_position (-1);
            }
            return false;
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
        opacity_container.text = (alpha * 100).to_string ();
        opacity_container.bind_property (
            "text", model, "alpha",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
            (binding, srcval, ref targetval) => {
                double src = double.parse (srcval.dup_string ());
                if (src > 100) {
                    opacity_container.text = "100";
                    return false;
                }
                targetval.set_double (src / 100);
                return true;
            }, (binding, srcval, ref targetval) => {
                double src = (double) srcval;
                targetval.set_string (("%0.1f").printf (src * 100));
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

        model.notify.connect (on_model_changed);
    }

    private void on_color_changed () {
        var selectedColor = color_chooser_widget.rgba;

        color = "#%02X%02X%02X".printf (
            (int) (selectedColor.red * 255),
            (int) (selectedColor.green * 255),
            (int) (selectedColor.blue * 255));

        alpha = selectedColor.alpha;
    }

    private void on_model_changed () {
        model.list_model.update_fills ();
        set_color_chooser_color ();
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

    private void set_button_color () {
        try {
            var provider = new Gtk.CssProvider ();
            var context = selected_color.get_style_context ();

            var alpha_dot_separator = alpha.to_string ().replace (",", ".");

            var css = """.selected-color {
                    background-color: alpha (%s, %s);
                    border-color: alpha (shade (%s, 0.75), %s);
                }""".printf (color, alpha_dot_separator, color, alpha_dot_separator);

            provider.load_from_data (css, css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }

    private void set_color_chooser_color () {
        if (!Regex.match_simple ("#[0-9A-F]{6}|#[0-9A-F]{3}", model.color.up ())) {
            return;
        }

        var newRGBA = Gdk.RGBA ();
        newRGBA.parse (model.color);
        newRGBA.alpha = alpha;

        color_chooser_widget.set_rgba (newRGBA);
    }
}

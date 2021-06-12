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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 * Authored by: Ivan "isneezy" Vilanculo <ivilanculo@gmail.com>
 */

public class Akira.Layouts.Partials.BorderItem : Gtk.Grid {
    private unowned Akira.Window window;
    private unowned Lib.Components.Border border;

    private Gtk.Button hidden_button;
    private Gtk.Button delete_button;
    private Gtk.Image hidden_button_icon;

    private bool hidden {
        owned get {
            return border.hidden;
        } set {
            border.hidden = value;
            set_hidden_button ();
            toggle_ui_visibility ();
        }
    }

    public signal void border_deleted ();

    public BorderItem (Akira.Window window, Lib.Components.Border border) {
        this.window = window;
        this.border = border;

        create_ui ();
        hidden = border.hidden;

        create_event_bindings ();
        show_all ();
    }

    private void create_ui () {
        margin_top = margin_bottom = 5;

        var fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;
        fill_chooser.margin_end = 5;

        fill_chooser.add (new Widgets.ColorRow (window, new Models.ColorModel (null, border)));

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
        delete_button.set_tooltip_text (_("Remove border color"));
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR));

        attach (fill_chooser, 0, 0, 1, 1);
        attach (hidden_button, 1, 0, 1, 1);
        attach (delete_button, 2, 0, 1, 1);
    }

    private void create_event_bindings () {
        delete_button.clicked.connect (on_delete_item);
        hidden_button.clicked.connect (toggle_visibility);
    }

    private void on_delete_item () {
        border.remove ();
        border_deleted ();
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
            hidden_button.set_tooltip_text (_("Show border"));
            return;
        }

        hidden_button.set_tooltip_text (_("Hide border"));
        get_style_context ().remove_class ("disabled");
    }
}

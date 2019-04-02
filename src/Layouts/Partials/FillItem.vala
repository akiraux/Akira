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
    public signal void remove_item (Akira.Models.FillsItemModel model);

    public Akira.Models.FillsItemModel model { get; construct; }

    private string blending_mode {
        owned get {
            var blending_mode_tokens = model.blending_mode
                .to_string ()
                .split("_");

            // Get everything but BLENDING_MODE
            blending_mode_tokens = blending_mode_tokens[2:blending_mode_tokens.length];

            var formatted_blending_mode = "";

            foreach (var elem in blending_mode_tokens) {
                elem = elem[0].toupper ().to_string() +
                    elem[1:elem.length].down();

                formatted_blending_mode += elem;
            }

            return formatted_blending_mode;
        }
    }

    private string opacity {
        owned get {
            return "%d %%".printf ((int) model.opacity);
        }
    }

    private Gtk.Grid fill_chooser;
    private Gtk.Button visible_button;
    private Gtk.Button delete_button;
    private Gtk.Button show_options_button;
    private Gtk.Label selected_blending_mode;
    private Gtk.Label current_opacity;
    private Gtk.Button selected_color;

    public FillItem (Akira.Models.FillsItemModel model) {
        Object(
            model: model
        );
    }

    construct {
        selected_blending_mode = new Gtk.Label ("%s".printf(blending_mode));

        fill_chooser = new Gtk.Grid ();
        fill_chooser.hexpand = true;

        selected_color = new Gtk.Button ();
        selected_color.can_focus = false;
        selected_color.get_style_context ().add_class ("selected-color");

        selected_blending_mode = new Gtk.Label (blending_mode);
        selected_blending_mode.hexpand = true;
        selected_blending_mode.halign = Gtk.Align.START;

        show_options_button = new Gtk.Button ();
        show_options_button.can_focus = false;
        show_options_button.valign = Gtk.Align.CENTER;
        show_options_button.add (new Gtk.Image.from_icon_name ("pan-down-symbolic",
                                                Gtk.IconSize.SMALL_TOOLBAR));
        show_options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        show_options_button.get_style_context ().add_class ("popover-toggler");

        current_opacity = new Gtk.Label (opacity);
        current_opacity.halign = Gtk.Align.CENTER;
        current_opacity.get_style_context ().add_class ("opacity");

        fill_chooser.attach(selected_color, 0, 0, 1, 1);
        fill_chooser.attach(selected_blending_mode, 1, 0, 1, 1);
        fill_chooser.attach(show_options_button, 2, 0, 1, 1);
        fill_chooser.attach(current_opacity, 3, 0, 1, 1);

        fill_chooser.get_style_context ().add_class ("fill-chooser");

        visible_button = new Gtk.Button ();
        visible_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        visible_button.can_focus = false;
        visible_button.valign = Gtk.Align.CENTER;
        visible_button.add (new Gtk.Image.from_icon_name ("layer-visible-symbolic",
                                                   Gtk.IconSize.LARGE_TOOLBAR));

        delete_button = new Gtk.Button ();
        delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_button.can_focus = false;
        delete_button.valign = Gtk.Align.CENTER;
        delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
                                                   Gtk.IconSize.LARGE_TOOLBAR));

        attach(fill_chooser, 0, 0, 1, 1);
        attach(visible_button, 1, 0, 1, 1);
        attach(delete_button, 2, 0, 1, 1);

        get_style_context ().add_class ("fill-chooser-cont");

        show_all();
    }
}

/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */

public class Akira.Widgets.AlignBoxButton : Gtk.Button {
    public signal void triggered (AlignBoxButton emitter);

    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public string icon { get; construct; }
    public Utils.ItemAlignment.AlignmentDirection alignment_direction { get; construct; }
    public ButtonImage btn_image;

    public AlignBoxButton (Lib.ViewCanvas view_canvas, Utils.ItemAlignment.AlignmentDirection alignment_direction, string icon_name, string tooltip, string[] accels) {
        Object (
            view_canvas: view_canvas,
            icon: icon_name,
            alignment_direction: alignment_direction,
            tooltip_markup: Granite.markup_accel_tooltip (accels, tooltip)
        );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        get_style_context ().add_class ("button-rounded");
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.CENTER;
        can_focus = false;
        sensitive = false;

        btn_image = new ButtonImage (icon, Gtk.IconSize.SMALL_TOOLBAR);
        add (btn_image);
        connect_signals ();
    }

    private void connect_signals () {
        clicked.connect (() => {
            view_canvas.window.event_bus.selection_align (alignment_direction);
        });

        view_canvas.window.event_bus.selection_modified.connect (() => {
            unowned var selection = view_canvas.selection_manager.selection;
            sensitive = selection.count () > 1;
        });
    }
}

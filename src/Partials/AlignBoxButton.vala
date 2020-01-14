/*
 * Copyright (c) 2019 Alecaddd (http://alecaddd.com)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */
public class Akira.Partials.AlignBoxButton : Gtk.Button {
    public signal void triggered (Akira.Partials.AlignBoxButton emitter);

    public weak Akira.Window window { get; construct; }

    public string icon { get; construct; }
    public string action { get; construct; }
    public Akira.Partials.ButtonImage btn_image;

    public AlignBoxButton (Akira.Window window, string action_name, string icon_name, string tooltip, string[] accels) {
        Object (
            window: window,
            icon: icon_name,
            action: action_name,
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
            window.event_bus.align_items (action);
        });
    }
}

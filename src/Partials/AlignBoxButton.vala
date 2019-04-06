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
    public Gtk.Image btn_image;

    public AlignBoxButton (Akira.Window main_window, string action_name, string icon_name, string tooltip) {
        Object (
            window: main_window,
            icon: icon_name,
            action: action_name,
            tooltip_text: tooltip
        );
    }

    construct {
        can_focus = false;
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        sensitive = false;

        update_icon_style ();
        connect_signals ();
    }

    private void update_icon_style () {
        var size = settings.use_symbolic == true ? Gtk.IconSize.SMALL_TOOLBAR :
                                                   Gtk.IconSize.LARGE_TOOLBAR;
        var new_icon = settings.use_symbolic == true ? ("%s-symbolic".printf (icon)) :
                                                       icon.replace ("-symbolic", "");

        if (btn_image != null) {
            remove (btn_image);
        }

        btn_image = new Gtk.Image.from_icon_name (new_icon, size);
        add (btn_image);

        show_all ();
    }

    private void connect_signals () {
        window.event_bus.update_icons_style.connect (() => {
            update_icon_style ();
        });

        clicked.connect (() => {
            window.event_bus.emit ("align-items", action);
        });
    }
}

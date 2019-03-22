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

    public string icon_name { get; construct; }
    public string action { get; construct; }
    public string tooltip_text { get; construct; }

    private Gtk.Image image;

    public AlignBoxButton (Akira.Window window, string action, string icon_name, string tooltip_text) {
        Object (
            window: window,
            icon_name: icon_name,
            action: action,
            tooltip_text: tooltip_text
            );
    }

    construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        can_focus = false;

        update_icon_style ();

        connect_signals ();
    }

    private void update_icon_style () {
        var new_icon_size = settings.use_symbolic == true
            ? Gtk.IconSize.SMALL_TOOLBAR
            : Gtk.IconSize.LARGE_TOOLBAR;

        var new_icon_name = settings.use_symbolic == true
            ? icon_name + "-symbolic"
            : icon_name;

        if (image != null) {
            remove (image);
        }

        image = new Gtk.Image.from_icon_name (new_icon_name, new_icon_size);
        add (image);
        image.show_all ();
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

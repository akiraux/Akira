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
public class Akira.Partials.AlignBoxButton : Gtk.Grid {
    public string icon_name;
    public string action;

    public Gtk.IconSize icon_size;

    private Gtk.Button button;
    private Gtk.Image image;

    public signal void triggered (Akira.Partials.AlignBoxButton emitter);

    public AlignBoxButton (
        string action,
        string icon_name,
        string title) {
        this.action = action;

        this.tooltip_text = title;

        can_focus = false;
        hexpand = true;

        this.icon_name = icon_name;
        this.icon_size = Gtk.IconSize.LARGE_TOOLBAR;

        if (settings.use_symbolic) {
          this.icon_name = icon_name + "-symbolic";
          this.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        }

        image = new Gtk.Image.from_icon_name (this.icon_name, this.icon_size);
        image.margin = 0;

        button = new Gtk.Button ();
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        button.can_focus = false;
        button.halign = Gtk.Align.CENTER;

        button.add (image);

        attach (button, 0, 0, 1, 1);

        connect_signals ();
    }

    private void update_icon_style () {
        var new_icon_size = settings.use_symbolic == true
            ? Gtk.IconSize.SMALL_TOOLBAR
            : Gtk.IconSize.LARGE_TOOLBAR;

        var new_icon_name = settings.use_symbolic == true
            ? this.icon_name + "-symbolic"
            : this.icon_name;

        this.button.remove (this.image);
        this.image = new Gtk.Image.from_icon_name (new_icon_name, new_icon_size);
        this.button.add (image);

        image.show_all ();
    }

    private void connect_signals () {
        event_bus.update_icons_style.connect (() => {
            update_icon_style ();
        });

        button.clicked.connect (() => {
            event_bus.emit ("align_items", action);
        });
    }
}

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
    public string icon_style {
        set {
            if (this.image != null) {
                this.image.icon_name = this.get_icon_full_name ();
                this.image.show_all ();
            }
        }
    }

    public Gtk.IconSize icon_size;

    private Gtk.Button button;
    private Gtk.Image image;

    public signal void triggered (Akira.Partials.AlignBoxButton emitter);

    public AlignBoxButton (
        string action,
        string icon_name,
        string title,
        Gtk.IconSize icon_size = Gtk.IconSize.SMALL_TOOLBAR) {

        this.action = action;
        this.icon_name = icon_name;
        this.icon_size = icon_size;

        this.tooltip_text = title;

        this.icon_style = settings.icon_style;

        can_focus = false;
        hexpand = true;

        image = new Gtk.Image.from_icon_name (this.get_icon_full_name (), icon_size);
        image.margin = 0;

        image.show_all ();

        button = new Gtk.Button ();

        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button.get_style_context ().add_class ("align-box-button");

        button.can_focus = false;
        button.halign = Gtk.Align.CENTER;

        button.add (image);

        attach (button, 0, 0, 1, 1);

        this.button.clicked.connect (() => {
            this.triggered (this);
        });
    }

    public string get_icon_full_name () {
        string full_icon_name = this.icon_name;

        switch (settings.icon_style) {
            case "filled":
            case "lineart":
                // Don't to anything, as of now, change to
                // proper icon style suffix when icons are ready
                break;

            case "symbolic":
                full_icon_name += "-symbolic";
                break;
        }

        return full_icon_name;
    }
}

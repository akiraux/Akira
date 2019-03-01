/*
 * Copyright (c) 2018 Alecaddd (http://alecaddd.com)
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
  public Gtk.IconSize icon_size;
  public string action;

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

    can_focus = false;
    hexpand = true;

    image = new Gtk.Image.from_icon_name (this.get_icon_full_name (), icon_size);
    image.margin = 0;

    button = new Gtk.Button ();
    button.can_focus = false;
    button.halign = Gtk.Align.CENTER;

    button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    button.get_style_context ().add_class ("button");

    button.add (image);

    attach (button, 0, 0, 1, 1);

    this.button.clicked.connect (() => {
      this.triggered (this);
    });
  }

  public void change_icon_style () {
    button.remove (image);

    image = new Gtk.Image.from_icon_name (this.get_icon_full_name (), this.icon_size);

    button.add (image);
    image.show_all ();
  }

  public string get_icon_full_name () {
    var icon_full_name = "";
    //this.icon_size = Gtk.IconSize.LARGE_TOOLBAR;

    switch (settings.icon_style) {
      case "filled":
        icon_full_name = this.icon_name;
        break;
      case "lineart":
        icon_full_name = this.icon_name;
        break;
      case "symbolic":
        icon_full_name = this.icon_name + "-symbolic";
        break;
    }

    return icon_full_name;
  }
}

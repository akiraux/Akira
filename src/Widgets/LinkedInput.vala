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
* Authored by: Ana Gelez <ana@gelez.xyz>
*/
public class Akira.Widgets.LinkedInput : Gtk.Box {
  public bool digit_only { get; construct set; default = true; }

  public string label { get; construct set; }

  /**
  * Indicates wheter the label or the entry should be first
  */
  public bool reversed { get; construct set; }

  public string text { get; set; default = ""; }

  public LinkedInput (string label, bool reversed = false, bool digit_only = true) {
    Object (
      label: label,
      reversed: reversed
    );
  }

  construct {
    orientation = Gtk.Orientation.HORIZONTAL;
    valign = Gtk.Align.CENTER;
    get_style_context ().add_class ("linked");
    if (text == "" && digit_only) {
      text = "0";
    }

    var label = new Gtk.Label (label);
    label.get_style_context ().add_class ("entry-label");
    label.width_request = 24;

    var entry = new Gtk.Entry ();
    bind_property ("text", entry, "text", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
    entry.width_request = 48;
    entry.width_chars = 0;

    if (reversed) {
      entry.xalign = 1.0f;
      add (entry);
      add (label);
    } else {
      add (label);
      add (entry);
    }
  }
}

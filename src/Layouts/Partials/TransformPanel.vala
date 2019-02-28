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
public class Akira.Layouts.Partials.TransformPanel : Gtk.Grid {
  construct {
    border_width = 12;
    row_spacing = 6;
    column_spacing = 6;
		hexpand = true;

    attach (group_title (_("Position")), 0, 0);
    attach (new Akira.Widgets.LinkedInput (C_("The horizontal coordinate", "X")), 0, 1, 1);
    attach (new Akira.Widgets.LinkedInput (C_("The vertical coordinate", "Y")), 2, 1, 2);

    attach (group_title (_("Size")), 0, 2);
    attach (new Akira.Widgets.LinkedInput (C_("The first letter of Width", "W")), 0, 3, 1);
    var lock_changes = new Gtk.Button.from_icon_name ("changes-allow-symbolic");
    lock_changes.get_style_context ().add_class ("flat");
    attach (lock_changes, 1, 3);
    attach (new Akira.Widgets.LinkedInput (C_("The first letter of Heigth", "H")), 2, 3, 2);

    attach (group_title (_("Transform")), 0, 4);
    attach (new Akira.Widgets.LinkedInput (C_("The first letter of Rotation", "R")), 0, 5, 1);

    var hflip_button = new Gtk.Button.from_icon_name ("object-flip-horizontal", Gtk.IconSize.LARGE_TOOLBAR);
    hflip_button.get_style_context ().add_class ("flat");
		hflip_button.hexpand = true;
    var vflip_button = new Gtk.Button.from_icon_name ("object-flip-vertical", Gtk.IconSize.LARGE_TOOLBAR);
    vflip_button.get_style_context ().add_class ("flat");
		vflip_button.hexpand = true;

    var flip_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		flip_box.hexpand = true;
    flip_box.add (hflip_button);
    flip_box.add (vflip_button);
    attach (flip_box, 2, 5, 2);

    attach (group_title (_("Opacity")), 0, 6);
    var opacity = new Gtk.Adjustment (0, 0, 100, 0.5, 0, 0);
    var scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, opacity);
		scale.hexpand = true;
    scale.draw_value = false;
    scale.sensitive = true;
    scale.round_digits = 1;
    attach (scale, 0, 7, 3);
    var opacity_entry = new Akira.Widgets.LinkedInput ("%", true);
    opacity_entry.bind_property (
      "text", opacity, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE,
      (binding, val, ref res) => {
        res = double.parse ((string)val);
        return true;
      },
      (binding, val, ref res) => {
        res = "%.1f".printf ((double)val);
        return true;
      }
    );
    attach (opacity_entry, 3, 7);
  }

  Gtk.Label group_title (string title) {
    var title_label = new Gtk.Label ("<b>%s</b>".printf (title));
    title_label.use_markup = true;
    title_label.halign = Gtk.Align.START;
    title_label.margin_top = 6;
    return title_label;
  }
}

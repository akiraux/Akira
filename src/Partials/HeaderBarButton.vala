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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Partials.HeaderBarButton : Gtk.Grid {
	public Gtk.Button button;
	public Gtk.Image image;

	public HeaderBarButton (string icon_name, string name, string[]? accels) {
		image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);

		button = new Gtk.Button ();
		button.can_focus = false;
		button.halign = Gtk.Align.CENTER;
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.tooltip_markup = Granite.markup_accel_tooltip (accels, name);
		button.add (image);

		attach (button, 0, 0, 1, 1);
	}

	public void update_image (string icon_name) {
		button.remove (image);
		image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);
		button.add (image);
		image.show_all ();
	}
}

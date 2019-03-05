/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Partials.HeaderBarButton : Gtk.Grid {
	public bool labeled {
		get {
			return label_btn.visible;
		} set {
			label_btn.visible = value;
			label_btn.no_show_all = !value;
		}
	}

	private Gtk.Label label_btn;
	public Gtk.Button button;
	public Gtk.Image image;

	public HeaderBarButton (string icon_name, string name, string[]? accels = null) {
		label_btn = new Gtk.Label (name);
		label_btn.get_style_context ().add_class ("headerbar-label");

		var size = settings.use_symbolic == true ? Gtk.IconSize.SMALL_TOOLBAR : Gtk.IconSize.LARGE_TOOLBAR;
		var icon = settings.use_symbolic == true ? ("%s-symbolic".printf (icon_name)) : icon_name;

		image = new Gtk.Image.from_icon_name (icon, size);
		image.margin = 0;

		button = new Gtk.Button ();
		button.can_focus = false;
		button.halign = Gtk.Align.CENTER;
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.add (image);
		button.tooltip_markup = Granite.markup_accel_tooltip (accels, name);

		attach (button, 0, 0, 1, 1);
		attach (label_btn, 0, 1, 1, 1);
		valign = Gtk.Align.CENTER;
	}

	public void toggle () {
		labeled = !labeled;
	}

	public void show_labels () {
		labeled = true;
	}

	public void hide_labels () {
		labeled = false;
	}

	public void update_image () {
		var size = settings.use_symbolic == true ? Gtk.IconSize.SMALL_TOOLBAR : Gtk.IconSize.LARGE_TOOLBAR;
		var new_icon = settings.use_symbolic == true ? ("%s-symbolic".printf (image.icon_name)) : image.icon_name.replace ("-symbolic", "");
		button.remove (image);
		image = new Gtk.Image.from_icon_name (new_icon, size);
		button.add (image);
		image.show_all ();
	}
}

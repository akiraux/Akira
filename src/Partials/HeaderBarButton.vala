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

public class Akira.Partials.HeaderBarButton : Gtk.Button {
	public bool labelled {
		get {
			return label_btn.visible;
		} set {
			label_btn.visible = value;
			label_btn.no_show_all = !value;

			if (value) {
				get_style_context ().add_class ("headerbar-button");
			} else {
				get_style_context ().remove_class ("headerbar-button");
			}
		}
	}

	private Gtk.Label label_btn;

	public HeaderBarButton (string icon_name, string name, string tooltip) {
		can_focus = false;

		Gtk.Image image;
		var grid = new Gtk.Grid ();
		label_btn = new Gtk.Label (name);
		label_btn.margin_top = 2;

		image = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.LARGE_TOOLBAR);
		image.margin = 0;

		grid.attach (image, 0, 0, 1, 1);
		grid.attach (label_btn, 0, 1, 1, 1);
		add (grid);

		get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		get_style_context ().add_class ("headerbar-button");
		set_tooltip_text (tooltip);
	}

	public void toggle () {
		labelled = !labelled;
	}

	public void show_labels () {
		labelled = true;
	}

	public void hide_labels () {
		labelled = false;
	}
}
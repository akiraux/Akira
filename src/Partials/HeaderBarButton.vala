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
	public bool labelled {
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

	public HeaderBarButton (string icon_name, string name, string tooltip) {
		label_btn = new Gtk.Label (name);
		label_btn.get_style_context ().add_class ("headerbar-label");

		var size = settings.icon_style == "symbolic" ? Gtk.IconSize.SMALL_TOOLBAR : Gtk.IconSize.LARGE_TOOLBAR;

		image = new Gtk.Image.from_icon_name (icon_name, size);
		image.margin = 0;

		button = new Gtk.Button ();
		button.can_focus = false;
		button.halign = Gtk.Align.CENTER;
		button.margin_top = 10;
		button.set_tooltip_text (tooltip);
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
		button.add (image);

		attach (button, 0, 0, 1, 1);
		attach (label_btn, 0, 1, 1, 1);

		button.margin_bottom = 3;
		margin_bottom = 6;
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

	public void update_image (string icon_name) {
		var size = settings.icon_style == "symbolic" ? Gtk.IconSize.SMALL_TOOLBAR : Gtk.IconSize.LARGE_TOOLBAR;
		button.remove (image);
		image = new Gtk.Image.from_icon_name (icon_name, size);
		button.add (image);
		image.show_all ();
	}
}
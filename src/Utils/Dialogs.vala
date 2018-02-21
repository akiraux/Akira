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

public class Akira.Utils.Dialogs : Object {
	public weak Akira.Window window { get; construct; }

	public Dialogs (Akira.Window main_window) {
		Object (
			window: main_window
		);
	}

	public bool message_dialog (string title, string description, string icon, string primary_button) {
		var dialog = new Granite.MessageDialog.with_image_from_icon_name (title, description, icon, Gtk.ButtonsType.CANCEL);
		dialog.transient_for = window;
		
		var button = new Gtk.Button.with_label (primary_button);
		button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
		dialog.add_action_widget (button, Gtk.ResponseType.ACCEPT);

		dialog.show_all ();
		if (dialog.run () == Gtk.ResponseType.ACCEPT) {
			dialog.destroy ();
			return true;
		}
		
		dialog.destroy ();
		return false;
	}
}
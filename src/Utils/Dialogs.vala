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

public class Akira.Utils.Dialogs : Object {
    public weak Akira.Window window { get; construct; }

    public Dialogs (Akira.Window window) {
        Object (
            window: window
        );
    }

    public Granite.MessageDialog message_dialog (
        string title,
        string description,
        string icon,
        string primary_button,
        string? secondary_button = null
    ) {
        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
            title, description, icon, Gtk.ButtonsType.CANCEL);
        dialog.transient_for = window;

        if (secondary_button != null) {
            var button2 = new Gtk.Button.with_label (secondary_button);
            button2.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            dialog.add_action_widget (button2, 2);
        }

        var button = new Gtk.Button.with_label (primary_button);
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        dialog.add_action_widget (button, Gtk.ResponseType.ACCEPT);

        return dialog;
    }
}

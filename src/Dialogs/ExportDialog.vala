/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Dialogs.ExportDialog : Gtk.Dialog {
    public weak Akira.Window window { get; construct; }

    public ExportDialog (Akira.Window window) {
        Object (
            window: window,
            border_width: 0,
            deletable: true,
            resizable: true,
            modal: true
        );
    }

    construct {
        transient_for = window;
        use_header_bar = 1;
        default_width = 900;
        default_height = 600;

        var sidebar_header = new Gtk.Grid ();
        sidebar_header.vexpand = true;
        sidebar_header.get_style_context ().add_class ("sidebar-l");
        sidebar_header.width_request = 300;

        var close_button =  new Gtk.Button.from_icon_name (
            "window-close-symbolic",
            Gtk.IconSize.MENU
        );
        close_button.margin = 6;
        close_button.clicked.connect (() => {
            close ();
        });

        sidebar_header.add (close_button);

        var main_header = new Gtk.Grid ();
        main_header.vexpand = true;
        main_header.get_style_context ().add_class ("layers-panel");

        var pane_header = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane_header.pack1 (sidebar_header, false, false);
        pane_header.pack2 (main_header, false, false);
        pane_header.get_style_context ().add_class ("export-titlebar");

        // Hack to remove the default header area and replace it with
        // a custom widget.
        var header_area = get_header_bar ();
        header_area.destroy ();
        set_titlebar (pane_header);

        // Another hack to remove the bottom action area.
        var button = add_button("OK", 3);
        var button_area = button.get_parent ();
        button_area.destroy ();

        var sidebar = new Gtk.Grid ();
        sidebar.vexpand = true;
        sidebar.get_style_context ().add_class ("sidebar-l");
        sidebar.width_request = 300;
        sidebar.add (new Gtk.Label ("Sidebar"));

        var main = new Gtk.Grid ();
        main.vexpand = true;
        main.get_style_context ().add_class ("layers-panel");
        main.add (new Gtk.Label ("Main"));

        var pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.pack1 (sidebar, false, false);
        pane.pack2 (main, true, false);

        var content_area = get_content_area ();
        content_area.border_width = 0;
        content_area.add (pane);

        pane.bind_property ("position", pane_header, "position", BindingFlags.SYNC_CREATE);

        pane_header.notify.connect (() => {
            pane_header.position = pane.position;
        });
    }
}

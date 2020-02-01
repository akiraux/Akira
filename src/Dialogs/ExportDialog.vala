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

    private Gtk.Grid sidebar;
    public Gtk.FileChooserButton folder_button;

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
        sidebar_header.width_request = 280;

        var close_button =  new Gtk.Button.from_icon_name (
            "window-close-symbolic",
            Gtk.IconSize.MENU
        );
        close_button.margin_top = close_button.margin_bottom = 6;
        close_button.margin_right = close_button.margin_left = 4;
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

        sidebar = new Gtk.Grid ();
        sidebar.get_style_context ().add_class ("sidebar-export");
        sidebar.width_request = 280;

        var main = new Gtk.Grid ();
        main.vexpand = true;
        main.get_style_context ().add_class ("layers-panel");

        var pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.pack1 (sidebar, false, false);
        pane.pack2 (main, true, false);

        var content_area = get_content_area ();
        content_area.border_width = 0;
        content_area.add (pane);

        pane.bind_property ("position", pane_header, "position");

        pane_header.notify["position"].connect (() => {
            pane_header.position = pane.position;
        });

        Idle.add (() => {
            build_export_sidebar ();
        });
    }

    private void build_export_sidebar () {
        var folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES);

        // Folder location
        var folder_label = new Gtk.Label (_("Select Destination Folder"));
        folder_label.get_style_context ().add_class ("h4");
        folder_label.halign = Gtk.Align.START;
        sidebar.attach (folder_label, 0, 0, 1, 1);

        folder_button = new Gtk.FileChooserButton (_("Select Folder"), Gtk.FileChooserAction.SELECT_FOLDER);
        folder_button.set_current_folder (folder_dir);
        folder_button.hexpand = true;
        sidebar.attach (folder_button, 0, 1, 1, 1);

        // Quality spinbutton

        // File format

        // Scale

        // Buttons

        sidebar.show_all ();
    }
}

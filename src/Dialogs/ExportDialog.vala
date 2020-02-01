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
    public Gtk.Adjustment quality_adj;
    public Gtk.Scale quality_scale;
    public Akira.Partials.InputField quality_entry;

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
        default_width = 1000;
        default_height = 600;

        var sidebar_header = new Gtk.Grid ();
        sidebar_header.vexpand = true;
        sidebar_header.get_style_context ().add_class ("sidebar-l");
        sidebar_header.width_request = 340;

        var close_button =  new Gtk.Button.from_icon_name (
            "window-close-symbolic",
            Gtk.IconSize.MENU
        );
        close_button.margin = 5;
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
        sidebar.width_request = 340;
        build_export_sidebar ();

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
    }

    private void build_export_sidebar () {
        var folder_dir = Environment.get_user_special_dir (UserDirectory.PICTURES);

        // Folder location
        sidebar.attach (section_title (_("Select Destination Folder")), 0, 0, 2, 1);

        folder_button = new Gtk.FileChooserButton (
            _("Select Folder"),
            Gtk.FileChooserAction.SELECT_FOLDER
        );
        folder_button.set_current_folder (folder_dir);
        folder_button.hexpand = true;
        folder_button.margin_bottom = 20;
        sidebar.attach (folder_button, 0, 1, 2, 1);

        // Quality spinbutton
        sidebar.attach (section_title (_("Quality")), 0, 2, 2, 1);

        quality_adj = new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0);
        quality_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, quality_adj);
        quality_scale.hexpand = true;
        quality_scale.draw_value = false;
        quality_scale.round_digits = 1;
        quality_scale.margin_end = 10;
        quality_scale.margin_bottom = 20;
        sidebar.attach (quality_scale, 0, 3, 1, 1);

        quality_entry = new Akira.Partials.InputField (
            Akira.Partials.InputField.Unit.PERCENTAGE, 7, true, true);
        quality_entry.entry.sensitive = true;
        quality_entry.entry.hexpand = false;
        quality_entry.entry.value = 100;
        quality_entry.margin_bottom = 20;

        quality_entry.entry.bind_property (
            "value", quality_adj, "value",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE);
        sidebar.attach (quality_entry, 1, 3, 1, 1);

        // File format
        var format_title = section_title (_("Format"));
        format_title.margin_bottom = 20;
        sidebar.attach (format_title, 0, 4, 1, 1);

        var file_format = new Gtk.ComboBoxText ();
        file_format.append ("png", "PNG");
        file_format.append ("jpg", "JPG");
        file_format.set_active_id ("png");
        file_format.margin_bottom = 20;
        sidebar.attach (file_format, 1, 4, 1, 1);

        // Resolution
        var size_title = section_title (_("Size"));
        size_title.margin_bottom = 20;
        sidebar.attach (size_title, 0, 5, 1, 1);

        var file_size = new Gtk.ComboBoxText ();
        file_size.append ("1", "1x");
        file_size.append ("2", "2x");
        file_size.append ("4", "4x");
        file_size.set_active_id ("1");
        file_size.margin_bottom = 20;
        sidebar.attach (file_size, 1, 5, 1, 1);

        // Buttons
        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.halign = Gtk.Align.START;
        sidebar.attach (cancel_button, 0, 6, 1, 1);

        var export_button = new Gtk.Button.with_label (_("Export"));
        export_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        export_button.halign = Gtk.Align.END;
        sidebar.attach (export_button, 1, 6, 1, 1);

    }

    private Gtk.Label section_title (string title) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("group-title");
        title_label.halign = Gtk.Align.START;
        title_label.valign = Gtk.Align.CENTER;
        title_label.hexpand = true;
        title_label.margin_bottom = 5;

        return title_label;
    }
}

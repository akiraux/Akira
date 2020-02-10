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
    public Gtk.Adjustment compression_adj;
    public Gtk.Scale compression_scale;
    public Gtk.ComboBoxText file_format;
    public Gtk.Label jpg_title;
    public Gtk.Label png_title;
    public Gtk.Label alpha_title;
    public Gtk.Switch alpha_switch;

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
        default_width = settings.export_width;
        default_height = settings.export_height;

        var sidebar_header = new Gtk.Grid ();
        sidebar_header.vexpand = true;
        sidebar_header.get_style_context ().add_class ("sidebar-export-header");
        sidebar_header.height_request = 30;

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
        var button = add_button ("OK", 3);
        var button_area = button.get_parent ();
        button_area.destroy ();

        sidebar = new Gtk.Grid ();
        sidebar.get_style_context ().add_class ("sidebar-export");
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

        settings.bind ("export-paned", pane, "position", SettingsBindFlags.DEFAULT);

        update_format_ui ();
    }

    private void build_export_sidebar () {
        var grid = new Gtk.Grid ();
        grid.expand = true;
        grid.column_spacing = 12;
        grid.margin_start = grid.margin_end = grid.margin_bottom = 12;
        grid.row_spacing = 6;

        // Folder location.
        grid.attach (section_title (_("Export to:")), 0, 0, 1, 1);

        folder_button = new Gtk.FileChooserButton (
            _("Select Folder"),
            Gtk.FileChooserAction.SELECT_FOLDER
        );
        folder_button.set_current_folder (
            Environment.get_user_special_dir (UserDirectory.PICTURES)
        );
        folder_button.hexpand = true;
        grid.attach (folder_button, 1, 0, 1, 1);

        // File format.
        var format_title = section_title (_("Format:"));
        grid.attach (format_title, 0, 2, 1, 1);

        file_format = new Gtk.ComboBoxText ();
        file_format.append ("png", "PNG");
        file_format.append ("jpg", "JPG");
        file_format.changed.connect (update_format_ui);
        grid.attach (file_format, 1, 2, 1, 1);
        settings.bind ("export-format", file_format, "active_id", SettingsBindFlags.DEFAULT);

        // Quality spinbutton.
        jpg_title = section_title (_("Quality:"));
        grid.attach (jpg_title, 0, 3, 1, 1);

        quality_adj = new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0);
        quality_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, quality_adj);
        quality_scale.hexpand = true;
        quality_scale.draw_value = true;
        quality_scale.digits = 0;
        grid.attach (quality_scale, 1, 3, 1, 1);
        settings.bind ("export-quality", quality_adj, "value", SettingsBindFlags.DEFAULT);

        // Compression spinbutton.
        png_title = section_title (_("Compression:"));
        grid.attach (png_title, 0, 4, 1, 1);

        compression_adj = new Gtk.Adjustment (0.0, 0, 9.0, 1, 0, 0);
        compression_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, compression_adj);
        compression_scale.hexpand = true;
        compression_scale.draw_value = true;
        compression_scale.digits = 0;
        for (int i = 1; i <= 9; i++) {
            compression_scale.add_mark (i, Gtk.PositionType.BOTTOM, null);
        }
        grid.attach (compression_scale, 1, 4, 1, 1);
        settings.bind ("export-compression", compression_adj, "value", SettingsBindFlags.DEFAULT);

        alpha_title = section_title (_("Transparency:"));
        grid.attach (alpha_title, 0, 5, 1, 1);

        alpha_switch = new Gtk.Switch ();
        alpha_switch.valign = Gtk.Align.CENTER;
        alpha_switch.halign = Gtk.Align.START;
        grid.attach (alpha_switch, 1, 5, 1, 1);
        settings.bind ("export-alpha", alpha_switch, "active", SettingsBindFlags.DEFAULT);

        // Resolution.
        var size_title = section_title (_("Scale:"));
        grid.attach (size_title, 0, 6, 1, 1);

        var scale_button = new Granite.Widgets.ModeButton ();
        scale_button.halign = Gtk.Align.FILL;
        scale_button.append_text ("1×");
        scale_button.append_text ("2×");
        scale_button.append_text ("4×");
        scale_button.set_active (settings.export_scale);
        settings.bind ("export-scale", scale_button, "selected", SettingsBindFlags.DEFAULT);
        grid.attach (scale_button, 1, 6, 1, 1);

        // Buttons.
        var action_area = new Gtk.Grid ();
        action_area.column_spacing = 6;
        action_area.halign = Gtk.Align.END;
        action_area.valign = Gtk.Align.END;
        action_area.vexpand = true;
        grid.attach (action_area, 0, 7, 2, 1);

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.halign = Gtk.Align.START;
        action_area.add (cancel_button);
        cancel_button.clicked.connect (() => {
            close ();
        });

        var export_button = new Gtk.Button.with_label (_("Export"));
        export_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        export_button.halign = Gtk.Align.END;
        action_area.add (export_button);

        sidebar.add (grid);
    }

    private void update_format_ui () {
        jpg_title.visible = (file_format.active_id == "jpg");
        quality_scale.visible = (file_format.active_id == "jpg");
        quality_entry.visible = (file_format.active_id == "jpg");

        png_title.visible = (file_format.active_id == "png");
        compression_scale.visible = (file_format.active_id == "png");
        alpha_title.visible = (file_format.active_id == "png");
        alpha_switch.visible = (file_format.active_id == "png");
    }

    private Gtk.Label section_title (string title) {
        var title_label = new Gtk.Label (title);
        title_label.halign = Gtk.Align.END;

        return title_label;
    }
}

/*
* Copyright (c) 2020-2022 Alecaddd (https://alecaddd.com)
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
    public unowned Lib.ViewCanvas canvas { get; construct; }
    public unowned Lib.Managers.ExportManager manager { get; construct; }

    public GLib.ListStore list_store;

    private Gtk.FlowBox export_grid;
    private Gtk.Grid sidebar;
    public Gtk.FileChooserButton folder_button;
    public Gtk.Adjustment quality_adj;
    public Gtk.Scale quality_scale;
    public Gtk.Adjustment compression_adj;
    public Gtk.Scale compression_scale;
    public Gtk.ComboBoxText file_format;
    public Gtk.Label jpg_title;
    public Gtk.Label png_title;
    public Gtk.Label alpha_title;
    public Gtk.Switch alpha_switch;

    private Gtk.Overlay main_overlay;
    private Granite.Widgets.Toast notification;
    private Granite.Widgets.OverlayBar overlaybar;

    public ExportDialog (Lib.ViewCanvas view_canvas, Lib.Managers.ExportManager export_manager) {
        Object (
            canvas: view_canvas,
            manager: export_manager,
            border_width: 0,
            deletable: true,
            resizable: true,
            modal: true
        );
    }

    construct {
        transient_for = canvas.window;
        use_header_bar = 1;
        default_width = settings.export_width;
        default_height = settings.export_height;

        var sidebar_header = new Gtk.Grid () {
            vexpand = true,
            height_request = 30
        };
        sidebar_header.get_style_context ().add_class ("sidebar-export-header");

        var main_header = new Gtk.Grid () {
            vexpand = true
        };

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

        main_overlay = new Gtk.Overlay ();
        notification = new Granite.Widgets.Toast (_(""));
        overlaybar = new Granite.Widgets.OverlayBar (main_overlay);
        overlaybar.active = true;

        var main = new Gtk.Grid () {
            expand = true
        };

        list_store = new GLib.ListStore (typeof (Akira.Models.ExportModel));

        export_grid = new Gtk.FlowBox () {
            activate_on_single_click = false,
            max_children_per_line = 1,
            selection_mode = Gtk.SelectionMode.NONE,
            column_spacing = 12,
            row_spacing = 12
        };
        export_grid.get_style_context ().add_class ("export-panel");

        export_grid.bind_model (list_store, model => {
            return new Widgets.ExportWidget (model as Akira.Models.ExportModel);
        });

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            expand = true
        };
        scrolled.get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        scrolled.add (export_grid);
        main.add (scrolled);

        main_overlay.add (main);
        main_overlay.add_overlay (notification);

        var pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        pane.pack1 (sidebar, false, false);
        pane.pack2 (main_overlay, true, false);

        var content_area = get_content_area ();
        content_area.border_width = 0;
        content_area.add (pane);

        pane.bind_property ("position", pane_header, "position");

        pane_header.notify["position"].connect (() => {
            pane_header.position = pane.position;
        });

        settings.bind ("export-paned", pane, "position", SettingsBindFlags.DEFAULT);
        // GTK issue: combobox need to be added to a parent and be visible before
        // we can use bind () to prevent a critical error.
        settings.bind ("export-format", file_format, "active_id",
            SettingsBindFlags.DEFAULT | GLib.SettingsBindFlags.GET_NO_CHANGES);

        manager.busy.connect (on_busy);
        manager.show_preview.connect (on_show_preview);
        manager.free.connect (on_free);
        manager.export_finished.connect (on_export_finished);
    }

    private void build_export_sidebar () {
        var grid = new Gtk.Grid () {
            expand = true,
            column_spacing = 12,
            margin_start = 12,
            margin_end = 12,
            margin_bottom = 12,
            row_spacing = 6
        };

        // Folder location.
        grid.attach (section_title (_("Export to:")), 0, 0, 1, 1);

        if (settings.export_folder == "") {
            settings.export_folder = Environment.get_user_special_dir (UserDirectory.PICTURES);
        }

        folder_button = new Gtk.FileChooserButton (_("Select Folder"), Gtk.FileChooserAction.SELECT_FOLDER);
        folder_button.set_current_folder (settings.export_folder);
        folder_button.hexpand = true;
        grid.attach (folder_button, 1, 0, 1, 1);
        folder_button.selection_changed.connect (() => {
            settings.export_folder = folder_button.get_filename ();
        });

        // File format.
        var format_title = section_title (_("Format:"));
        grid.attach (format_title, 0, 2, 1, 1);

        file_format = new Gtk.ComboBoxText ();
        file_format.append ("png", "PNG");
        file_format.append ("jpg", "JPG");
        file_format.changed.connect (update_format_ui);
        grid.attach (file_format, 1, 2, 1, 1);
        settings.changed["export-format"].connect (() => {
            manager.generate_preview ();
        });

        // Quality spinbutton.
        jpg_title = section_title (_("Quality:"));
        grid.attach (jpg_title, 0, 3, 1, 1);

        quality_adj = new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0);
        quality_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, quality_adj) {
            hexpand = true,
            draw_value = true,
            digits = 0
        };
        grid.attach (quality_scale, 1, 3, 1, 1);
        quality_scale.button_release_event.connect (() => {
            settings.export_quality = (int) quality_adj.value;
            return false;
        });

        // Compression spinbutton.
        png_title = section_title (_("Compression:"));
        grid.attach (png_title, 0, 4, 1, 1);

        compression_adj = new Gtk.Adjustment (0.0, 0, 9.0, 1, 0, 0);
        compression_scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, compression_adj) {
            hexpand = true,
            draw_value = true,
            digits = 0
        };
        for (int i = 1; i <= 9; i++) {
            compression_scale.add_mark (i, Gtk.PositionType.BOTTOM, null);
        }
        grid.attach (compression_scale, 1, 4, 1, 1);
        compression_scale.button_release_event.connect (() => {
            settings.export_compression = (int) compression_adj.value;
            return false;
        });

        alpha_title = section_title (_("Transparency:"));
        grid.attach (alpha_title, 0, 5, 1, 1);

        alpha_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.START
        };
        grid.attach (alpha_switch, 1, 5, 1, 1);
        settings.bind ("export-alpha", alpha_switch, "active",
            SettingsBindFlags.DEFAULT | SettingsBindFlags.GET_NO_CHANGES);
        settings.changed["export-alpha"].connect (() => {
            manager.generate_preview ();
        });

        // Resolution.
        var size_title = section_title (_("Scale:"));
        grid.attach (size_title, 0, 6, 1, 1);

        var scale_button = new Granite.Widgets.ModeButton () {
            halign = Gtk.Align.FILL
        };
        scale_button.append_text ("0.5×");
        scale_button.append_text ("1×");
        scale_button.append_text ("2×");
        scale_button.append_text ("4×");
        scale_button.set_active (settings.export_scale);
        settings.bind ("export-scale", scale_button, "selected",
            SettingsBindFlags.DEFAULT | SettingsBindFlags.GET_NO_CHANGES);
        grid.attach (scale_button, 1, 6, 1, 1);
        settings.changed["export-scale"].connect (() => {
            manager.generate_preview ();
        });

        // Buttons.
        var action_area = new Gtk.Grid () {
            column_spacing = 6,
            halign = Gtk.Align.END,
            valign = Gtk.Align.END,
            vexpand = true
        };
        grid.attach (action_area, 0, 7, 2, 1);

        var cancel_button = new Gtk.Button.with_label (_("Cancel")) {
            halign = Gtk.Align.START
        };
        action_area.add (cancel_button);
        cancel_button.clicked.connect (() => {
            close ();
        });

        var export_button = new Gtk.Button.with_label (_("Export")) {
            halign = Gtk.Align.END
        };
        export_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        action_area.add (export_button);
        export_button.clicked.connect (() => {
            manager.export_images.begin ();
        });

        sidebar.add (grid);
    }

    public void update_format_ui () {
        jpg_title.visible = (file_format.active_id == "jpg");
        quality_scale.visible = (file_format.active_id == "jpg");

        png_title.visible = (file_format.active_id == "png");
        compression_scale.visible = (file_format.active_id == "png");
        alpha_title.visible = (file_format.active_id == "png");
        alpha_switch.visible = (file_format.active_id == "png");
    }

    public async void on_show_preview (Gee.HashMap<int, Gdk.Pixbuf> pixbufs) {
        list_store.remove_all ();
        foreach (var entry in pixbufs.entries) {
            var model = new Models.ExportModel (entry.key, entry.value);
            list_store.append (model);
        }
    }

    private Gtk.Label section_title (string title) {
        var title_label = new Gtk.Label (title) {
            halign = Gtk.Align.END
        };

        return title_label;
    }

    private async void on_busy (string message) {
        overlaybar.label = message;
        overlaybar.visible = true;
        sidebar.@foreach ((child) => {
            child.sensitive = false;
        });
    }

    private async void on_free () {
        sidebar.@foreach ((child) => {
            child.sensitive = true;
        });
        overlaybar.visible = false;
    }

    public void on_export_finished (string message) {
        notification.title = message;
        notification.send_notification ();
    }
}

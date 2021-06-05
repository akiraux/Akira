/*
 * Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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

public class Akira.Layouts.HeaderBar : Gtk.HeaderBar {
    public weak Akira.Window window { get; construct; }

    private Lib.Items.CanvasItem selected_item;

    public Widgets.HeaderBarButton new_document;
    public Widgets.HeaderBarButton save_file;
    public Widgets.HeaderBarButton save_file_as;
    public Gtk.Grid recent_files_grid;

    public Widgets.MenuButton menu;
    public Widgets.MenuButton items;
    public Widgets.ZoomButton zoom;
    public Widgets.HeaderBarButton group;
    public Widgets.HeaderBarButton ungroup;
    public Widgets.HeaderBarButton move_up;
    public Widgets.HeaderBarButton move_down;
    public Widgets.HeaderBarButton move_top;
    public Widgets.HeaderBarButton move_bottom;
    public Widgets.HeaderBarButton preferences;
    public Widgets.HeaderBarButton path_difference;
    public Widgets.HeaderBarButton path_exclusion;
    public Widgets.HeaderBarButton path_intersect;
    public Widgets.HeaderBarButton path_union;

    public Gtk.PopoverMenu popover_insert;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public HeaderBar (Akira.Window window) {
        Object (
            toggled: true,
            window: window
        );
    }

    construct {
        set_show_close_button (true);
        title = _("Untitled");

        menu = new Widgets.MenuButton ("document-open", _("Menu"), null);
        var menu_popover = build_main_menu_popover ();
        menu.button.popover = menu_popover;

        items = new Widgets.MenuButton ("insert-object", _("Insert"), null);
        var items_popover = build_items_popover ();
        items.button.popover = items_popover;

        zoom = new Widgets.ZoomButton (window);

        group =new Widgets.HeaderBarButton (window, "object-group",
            _("Group"), {"<Ctrl>g"}, "multiple");
        ungroup = new Widgets.HeaderBarButton (window, "object-ungroup",
            _("Ungroup"), {"<Ctrl><Shift>g"}, "group");

        move_up = new Widgets.HeaderBarButton (window, "selection-raise",
            _("Up"), {"<Ctrl>Up"}, "single");
        move_up.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_MOVE_UP;

        move_down = new Widgets.HeaderBarButton (window, "selection-lower",
            _("Down"), {"<Ctrl>Down"}, "single");
        move_down.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_MOVE_DOWN;

        move_top = new Widgets.HeaderBarButton (window, "selection-top",
            _("Top"), {"<Ctrl><Shift>Up"}, "single");
        move_top.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_MOVE_TOP;

        move_bottom = new Widgets.HeaderBarButton (window, "selection-bottom",
            _("Bottom"), {"<Ctrl><Shift>Down"}, "single");
        move_bottom.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_MOVE_BOTTOM;

        preferences = new Widgets.HeaderBarButton (window, "open-menu",
            _("Settings"), {"<Ctrl>comma"});
        preferences.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_PREFERENCES;
        preferences.sensitive = true;

        var export = new Widgets.MenuButton ("document-export", _("Export"), null);
        var export_popover = build_export_popover ();
        export.button.popover = export_popover;
        export.sensitive = true;

        var layout = new Widgets.MenuButton ("document-layout", _("Layout"), null);
        var layout_popover = build_layout_popover ();
        layout.button.popover = layout_popover;
        layout.sensitive = true;

        path_difference = new Widgets.HeaderBarButton (window, "path-difference",
            _("Difference"), null, "multiple");
        path_exclusion = new Widgets.HeaderBarButton (window, "path-exclusion",
            _("Exclusion"), null, "multiple");
        path_intersect = new Widgets.HeaderBarButton (window, "path-intersection",
            _("Intersect"), null, "multiple");
        path_union = new Widgets.HeaderBarButton (window, "path-union",
            _("Union"), null, "multiple");

        pack_start (menu);
        pack_start (items);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_start (zoom);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_start (group);
        pack_start (ungroup);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_start (move_up);
        pack_start (move_down);
        pack_start (move_top);
        pack_start (move_bottom);
        pack_start (new Gtk.Separator (Gtk.Orientation.VERTICAL));

        pack_end (preferences);
        pack_end (layout);
        pack_end (export);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_end (path_difference);
        pack_end (path_exclusion);
        pack_end (path_intersect);
        pack_end (path_union);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));

        build_signals ();
    }

    private Gtk.PopoverMenu build_main_menu_popover () {
        var grid = new Gtk.Grid ();
        grid.margin_top = 6;
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 240;
        grid.name = "main";

        var new_window_button = create_model_button (
            _("New Window"),
            "window-new-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_NEW_WINDOW);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = separator.margin_bottom = 3;

        var open_button = create_model_button (
            _("Open"),
            "document-open-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_OPEN);

        recent_files_grid = new Gtk.Grid ();
        recent_files_grid.margin_top = 6;
        recent_files_grid.margin_bottom = 3;
        recent_files_grid.orientation = Gtk.Orientation.VERTICAL;
        recent_files_grid.width_request = 220;
        recent_files_grid.name = "files-menu";

        var open_recent_button = new Gtk.ModelButton ();
        open_recent_button.text = _("Open Recent");
        open_recent_button.menu_name = "files-menu";
        fetch_recent_files.begin ();

        var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator2.margin_top = separator2.margin_bottom = 3;

        var save_button = create_model_button (
            _("Save"),
            "document-save-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_SAVE);

        var save_as_button = create_model_button (
            _("Save As"),
            "document-save-as-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_SAVE_AS);

        var separator3 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator3.margin_top = separator3.margin_bottom = 3;

        var quit_button = create_model_button (
            _("Quit"),
            "system-shutdown-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_QUIT);

        grid.add (new_window_button);
        grid.add (separator);
        grid.add (open_button);
        grid.add (open_recent_button);
        grid.add (separator2);
        grid.add (save_button);
        grid.add (save_as_button);
        grid.add (separator3);
        grid.add (quit_button);
        grid.show_all ();

        var popover = new Gtk.PopoverMenu ();
        popover.add (grid);
        popover.add (recent_files_grid);
        popover.child_set_property (grid, "submenu", "main");
        popover.child_set_property (recent_files_grid, "submenu", "files-menu");

        return popover;
    }

    private Gtk.PopoverMenu build_items_popover () {
        var grid = new Gtk.Grid ();
        grid.margin_top = 6;
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 200;
        grid.name = "main";

        var artboard = create_model_button (
            _("Artboard"),
            "window-new-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_ARTBOARD_TOOL);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = separator.margin_bottom = 3;

        // Create the shapes submenu
        var shapes_grid = new Gtk.Grid ();
        shapes_grid.margin_top = 6;
        shapes_grid.margin_bottom = 3;
        shapes_grid.orientation = Gtk.Orientation.VERTICAL;
        shapes_grid.width_request = 200;
        shapes_grid.name = "shapes-menu";

        var back_button = new Gtk.ModelButton ();
        back_button.text = _("Add Items");
        back_button.inverted = true;
        back_button.menu_name = "main";

        var sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        sub_separator.margin_top = sub_separator.margin_bottom = 3;

        var rectangle = create_model_button (
            _("Rectangle"),
            "shape-rectangle-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_RECT_TOOL);

        var ellipse = create_model_button (
            _("Ellipse"),
            "shape-circle-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_ELLIPSE_TOOL);

        shapes_grid.add (back_button);
        shapes_grid.add (sub_separator);
        shapes_grid.add (rectangle);
        shapes_grid.add (ellipse);
        shapes_grid.show_all ();

        var shapes_button = new Gtk.ModelButton ();
        shapes_button.text = _("Shapes");
        shapes_button.menu_name = "shapes-menu";

        var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator2.margin_top = separator2.margin_bottom = 3;

        var vector = create_model_button (_("Vector"), "segment-curve", "V");

        var pencil = create_model_button (_("Pencil"), "edit-symbolic", "P");

        var text = create_model_button (
            _("Text"),
            "shape-text-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_TEXT_TOOL);

        var image = create_model_button (
            _("Image"),
            "image-x-generic-symbolic",
            Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_IMAGE_TOOL);

        grid.add (artboard);
        grid.add (separator);
        grid.add (shapes_button);
        grid.add (separator2);
        grid.add (vector);
        grid.add (pencil);
        grid.add (text);
        grid.add (image);
        grid.show_all ();

        popover_insert = new Gtk.PopoverMenu ();
        popover_insert.add (grid);
        popover_insert.add (shapes_grid);
        popover_insert.child_set_property (grid, "submenu", "main");
        popover_insert.child_set_property (shapes_grid, "submenu", "shapes-menu");

        return popover_insert;
    }

    private Gtk.PopoverMenu build_export_popover () {
        var grid = new Gtk.Grid ();
        grid.margin_top = 6;
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 240;
        grid.name = "main";

        var export_selection = create_model_button (
            _("Export Current Selection"),
            null,
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_EXPORT_SELECTION);

        var export_artboards = create_model_button (
            _("Export Artboards"),
            null,
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_EXPORT_ARTBOARDS);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = separator.margin_bottom = 3;

        var export_area_grab = create_model_button (
            _("Highlight Area to Export"),
            null,
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_EXPORT_GRAB
        );

        grid.add (export_selection);
        grid.add (export_artboards);
        grid.add (separator);
        grid.add (export_area_grab);
        grid.show_all ();

        var popover = new Gtk.PopoverMenu ();
        popover.add (grid);

        return popover;
    }

    private Gtk.PopoverMenu build_layout_popover () {
        var grid = new Gtk.Grid ();
        grid.margin_top = 6;
        grid.margin_bottom = 3;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 240;
        grid.name = "main";

        var pixel_grid = create_model_button (
            _("Toggle Pixel Grid"),
            null,
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_TOGGLE_PIXEL_GRID);

        var presentation_mode = create_model_button (
            _("Presentation Mode"),
            null,
            Akira.Services.ActionManager.ACTION_PREFIX
            + Akira.Services.ActionManager.ACTION_PRESENTATION);

        grid.add (pixel_grid);
        grid.add (presentation_mode);
        grid.show_all ();

        var popover = new Gtk.PopoverMenu ();
        popover.add (grid);

        return popover;
    }

    private void build_signals () {
        window.event_bus.toggle_presentation_mode.connect (toggle);
        window.event_bus.file_edited.connect (on_file_edited);
        window.event_bus.file_saved.connect (on_file_saved);
        window.event_bus.selected_items_list_changed.connect (on_selected_items_changed);
        window.event_bus.selected_items_changed.connect (on_selected_items_changed);
        window.event_bus.z_selected_changed.connect (update_button_sensitivity);
        window.event_bus.update_recent_files_list.connect (fetch_recent_files);
    }

    private void toggle () {
        toggled = !toggled;
        if (!toggled) {
            window.event_bus.canvas_notification (_("Presentation Mode enabled."));
        }
    }

    /**
     * Fetch the recently opened files from GSettings and add them to the list
     * if those files still exists.
     */
    public async void fetch_recent_files () {
        recent_files_grid.@foreach (child => {
            recent_files_grid.remove (child);
        });

        // Add default buttons.
        var back_button = new Gtk.ModelButton ();
        back_button.text = _("Main Menu");
        back_button.inverted = true;
        back_button.menu_name = "main";
        back_button.expand = true;

        var sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        sub_separator.margin_top = sub_separator.margin_bottom = 3;

        recent_files_grid.add (back_button);
        recent_files_grid.add (sub_separator);

        // Loop a first time to clear missing files and prevent wrong accelerators.
        string[] all_files = {};
        for (var i = 0; i <= settings.recently_opened.length; i++) {
            // Skip if the record is empty.
            if (settings.recently_opened[i] == null) {
                continue;
            }

            // Skip if the file doesn't exist.
            var file = File.new_for_path (settings.recently_opened[i]);
            if (!file.query_exists ()) {
                continue;
            }

            all_files += settings.recently_opened[i];
        }

        // Update the GSettings to prevent loading an unavailable file.
        settings.set_strv ("recently-opened", all_files);

        for (var i = 0; i <= all_files.length; i++) {
            // Skip if the record is empty.
            if (all_files[i] == null) {
                continue;
            }

            // Store the full path in a variable before the split() method explodes the string.
            var full_path = all_files[i];

            // Get the file name.
            string[] split_string = all_files[i].split ("/");
            var file_name = split_string[split_string.length - 1].replace (".akira", "");

            var button = new Gtk.ModelButton ();

            // Add quick accelerators only for the first 3 items.
            string? accels = null;
            if (i < 3) {
                switch (i) {
                    case 0:
                        accels = Akira.Services.ActionManager.ACTION_PREFIX
                            + Akira.Services.ActionManager.ACTION_LOAD_FIRST;
                        break;
                    case 1:
                        accels = Akira.Services.ActionManager.ACTION_PREFIX
                            + Akira.Services.ActionManager.ACTION_LOAD_SECOND;
                        break;
                    case 2:
                        accels = Akira.Services.ActionManager.ACTION_PREFIX
                            + Akira.Services.ActionManager.ACTION_LOAD_THIRD;
                        break;
                }

                button.get_child ().destroy ();
                var label = new Granite.AccelLabel.from_action_name (file_name, accels);
                button.add (label);
                button.action_name = accels;
            } else {
                button.text = file_name;

                // Define the open action on click only for those files that don't
                // have an accelerator to prevent double calls.
                button.clicked.connect (() => {
                    var file = File.new_for_path (full_path);
                    if (!file.query_exists ()) {
                        window.event_bus.canvas_notification (
                            _("Unable to open file at '%s'").printf (full_path)
                        );
                        return;
                    }

                    File[] files = {};
                    files += file;
                    window.app.open (files, "");
                });
            }

            button.tooltip_text = all_files[i];

            recent_files_grid.add (button);
        }

        recent_files_grid.show_all ();
    }

    private void on_file_edited () {
        if (title.has_suffix ("*")) {
            return;
        }

        title = ("%s*").printf (title);
    }

    private void on_file_saved (string? file_name) {
        if (file_name == null) {
            title = title.has_suffix ("*") ? title.slice (0, title.length - 1) : title;
            return;
        }

        title = file_name.has_suffix (".akira") ? file_name.replace (".akira", "") : file_name;
    }

    private void on_selected_items_changed (List<Lib.Items.CanvasItem> selected_items) {
        if (selected_items.length () == 0) {
            selected_item = null;
            update_button_sensitivity ();
            return;
        }

        if (selected_item == null || selected_item != selected_items.nth_data (0)) {
            selected_item = selected_items.nth_data (0);
            update_button_sensitivity ();
        }
    }

    private void update_button_sensitivity () {
        var z_buttons_sensitive = selected_item != null && !(selected_item is Lib.Items.CanvasArtboard);

        move_up.sensitive = z_buttons_sensitive;
        move_down.sensitive = z_buttons_sensitive;
        move_top.sensitive = z_buttons_sensitive;
        move_bottom.sensitive = z_buttons_sensitive;

        if (!z_buttons_sensitive || selected_item.get_canvas () == null) {
            return;
        }

        var item_position = window.items_manager.get_item_z_index (selected_item);

        if (item_position == 0) {
            move_down.sensitive = false;
            move_bottom.sensitive = false;
        }

        // Account for nobs and select effect.
        if (item_position == window.items_manager.get_item_top_position (selected_item)) {
            move_up.sensitive = false;
            move_top.sensitive = false;
        }
    }

    private Gtk.ModelButton create_model_button (string text, string? icon, string? accels = null) {
        var button = new Gtk.ModelButton ();
        button.get_child ().destroy ();
        var label = new Granite.AccelLabel.from_action_name (text, accels);

        if (icon != null) {
            var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU);
            image.margin_end = 6;
            label.attach_next_to (
                image,
                label.get_child_at (0, 0),
                Gtk.PositionType.LEFT
            );
        }

        button.add (label);
        button.action_name = accels;

        return button;
    }
}

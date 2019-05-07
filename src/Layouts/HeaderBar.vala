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

public class Akira.Layouts.HeaderBar : Gtk.HeaderBar {
    public weak Akira.Window window { get; construct; }

    public Akira.Partials.HeaderBarButton new_document;
    public Akira.Partials.HeaderBarButton save_file;
    public Akira.Partials.HeaderBarButton save_file_as;
    public Gtk.Grid recent_files_grid;

    public Akira.Partials.MenuButton menu;
    public Akira.Partials.MenuButton items;
    public Akira.Partials.ZoomButton zoom;
    public Akira.Partials.HeaderBarButton group;
    public Akira.Partials.HeaderBarButton ungroup;
    public Akira.Partials.HeaderBarButton move_up;
    public Akira.Partials.HeaderBarButton move_down;
    public Akira.Partials.HeaderBarButton move_top;
    public Akira.Partials.HeaderBarButton move_bottom;
    public Akira.Partials.HeaderBarButton preferences;
    public Akira.Partials.HeaderBarButton export;
    public Akira.Partials.HeaderBarButton layout;
    public Akira.Partials.HeaderBarButton path_difference;
    public Akira.Partials.HeaderBarButton path_exclusion;
    public Akira.Partials.HeaderBarButton path_intersect;
    public Akira.Partials.HeaderBarButton path_union;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public HeaderBar (Akira.Window main_window) {
        Object (
            toggled: true,
            window: main_window
        );
    }

    construct {
        set_show_close_button (true);

        menu = new Akira.Partials.MenuButton ("document-open", _("Menu"), null);
        var menu_popover = build_main_menu_popover ();
        menu.button.popover = menu_popover;

        items = new Akira.Partials.MenuButton ("insert-object", _("Insert"), null);
        var items_popover = build_items_popover ();
        items.button.popover = items_popover;

        zoom = new Akira.Partials.ZoomButton (window);

        group = new Akira.Partials.HeaderBarButton ("object-group", _("Group"), {"<Ctrl>g"});
        ungroup = new Akira.Partials.HeaderBarButton ("object-ungroup", _("Ungroup"), {"<Ctrl><Shift>g"});

        move_up = new Akira.Partials.HeaderBarButton ("selection-raise", _("Up"), {"<Ctrl>Up"});
        move_down = new Akira.Partials.HeaderBarButton ("selection-lower", _("Down"), {"<Ctrl>Down"});
        move_top = new Akira.Partials.HeaderBarButton ("selection-top", _("Top"), {"<Ctrl><Shift>Up"});
        move_bottom = new Akira.Partials.HeaderBarButton ("selection-bottom", _("Bottom"), {"<Ctrl><Shift>Down"});

        preferences = new Akira.Partials.HeaderBarButton ("open-menu", _("Settings"), {"<Ctrl>comma"});
        preferences.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_PREFERENCES;

        export = new Akira.Partials.HeaderBarButton ("document-export", _("Export"), {"<Ctrl><Shift>E"});
        export.button.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_EXPORT;

        path_difference = new Akira.Partials.HeaderBarButton ("path-difference", _("Difference"), null);
        path_exclusion = new Akira.Partials.HeaderBarButton ("path-exclusion", _("Exclusion"), null);
        path_intersect = new Akira.Partials.HeaderBarButton ("path-intersection", _("Intersect"), null);
        path_union = new Akira.Partials.HeaderBarButton ("path-union", _("Union"), null);

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

        var new_window_button = new Akira.Partials.PopoverButton (
            _("New Window"), "window-new-symbolic", {"<Ctrl>n"});
        new_window_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_NEW_WINDOW;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = separator.margin_bottom = 3;

        var open_button = new Akira.Partials.PopoverButton (
            _("Open"), "document-open-symbolic", {"<Ctrl>o"});
        open_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_OPEN;

        recent_files_grid = new Gtk.Grid ();
        recent_files_grid.margin_top = 6;
        recent_files_grid.margin_bottom = 3;
        recent_files_grid.orientation = Gtk.Orientation.VERTICAL;
        recent_files_grid.width_request = 220;
        recent_files_grid.name = "files-menu";

        var back_button = new Gtk.ModelButton ();
        back_button.text = _("Main Menu");
        back_button.inverted = true;
        back_button.menu_name = "main";
        back_button.expand = true;

        var sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        sub_separator.margin_top = sub_separator.margin_bottom = 3;

        recent_files_grid.add (back_button);
        recent_files_grid.add (sub_separator);
        recent_files_grid.show_all ();
        fetch_recent_files ();

        var open_recent_button = new Gtk.ModelButton ();
        open_recent_button.text = _("Open Recent");
        open_recent_button.menu_name = "files-menu";

        var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator2.margin_top = separator2.margin_bottom = 3;

        var save_button = new Akira.Partials.PopoverButton (
            _("Save"), "document-save-symbolic", {"<Ctrl>s"});
        save_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_SAVE;

        var save_as_button = new Akira.Partials.PopoverButton (
            _("Save As"), "document-save-as-symbolic", {"<Ctrl><Shift>s"});
        save_as_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_SAVE_AS;

        var separator3 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator3.margin_top = separator3.margin_bottom = 3;

        var quit_button = new Akira.Partials.PopoverButton (
            _("Quit"), "system-shutdown-symbolic", {"<Ctrl>q"});
        quit_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_QUIT;

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

        var artboard = new Akira.Partials.PopoverButton (_("Artboard"), "window-new-symbolic", {"A"});

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

        var rectangle = new Akira.Partials.PopoverButton (_("Rectangle"), "shape-rectangle-symbolic", {"R"});
        rectangle.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_ADD_RECT;

        var ellipse = new Akira.Partials.PopoverButton (_("Ellipse"), "shape-circle-symbolic", {"E"});
        ellipse.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_ADD_ELLIPSE;

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

        var vector = new Akira.Partials.PopoverButton (_("Vector"), "segment-curve", {"V"});

        var pencil = new Akira.Partials.PopoverButton (_("Pencil"), "edit-symbolic", {"P"});

        var text = new Akira.Partials.PopoverButton (_("Text"), "shape-text-symbolic", {"T"});
        text.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_ADD_TEXT;

        var image = new Akira.Partials.PopoverButton (_("Image"), "image-x-generic-symbolic", {"I"});

        grid.add (artboard);
        grid.add (separator);
        grid.add (shapes_button);
        grid.add (separator2);
        grid.add (vector);
        grid.add (pencil);
        grid.add (text);
        grid.add (image);
        grid.show_all ();

        var popover = new Gtk.PopoverMenu ();
        popover.add (grid);
        popover.add (shapes_grid);
        popover.child_set_property (grid, "submenu", "main");
        popover.child_set_property (shapes_grid, "submenu", "shapes-menu");

        return popover;
    }

    private void build_signals () {
        // TODO: deal with signals not part of accelerators
    }

    public void button_sensitivity () {
        /* TODO: dinamically toggle button sensitivity
         * based on document status or actor selected.
         */
    }

    public void update_icons_style () {
        menu.update_image ();
        items.update_image ();
        export.update_image ();
        preferences.update_image ();
        group.update_image ();
        ungroup.update_image ();
        move_up.update_image ();
        move_down.update_image ();
        move_top.update_image ();
        move_bottom.update_image ();
        path_difference.update_image ();
        path_exclusion.update_image ();
        path_intersect.update_image ();
        path_union.update_image ();
    }

    public void toggle () {
        toggled = !toggled;
    }

    /**
     * TODO: Fetch the recently opened files from GSettings
     * and add them to the grid
     */
    public void fetch_recent_files () {
        recent_files_grid.show_all ();
    }
}

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
    public Akira.Partials.MenuButton toolset;
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

        var menu_popover_grid = new Gtk.Grid ();
        menu_popover_grid.margin_bottom = 3;
        menu_popover_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_popover_grid.width_request = 220;

        var new_window_button = new Akira.Partials.PopoverButton (
            _("Open New Window"), {"<Ctrl>n"});
        new_window_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_NEW_WINDOW;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_top = separator.margin_bottom = 3;

        var open_button = new Akira.Partials.PopoverButton (
            _("Open"), {"<Ctrl>o"});
        open_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_OPEN;

        // Create the recent files submenu
        var recent_files_popover = new Gtk.PopoverMenu ();
        recent_files_popover.name = "files-menu";

        recent_files_grid = new Gtk.Grid ();
        recent_files_grid.margin_bottom = 3;
        recent_files_grid.orientation = Gtk.Orientation.VERTICAL;
        recent_files_grid.width_request = 220;

        var main_menu_button = new Gtk.ModelButton ();
        main_menu_button.text = _("Main Menu");
        main_menu_button.inverted = true;

        var sub_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        sub_separator.margin_top = sub_separator.margin_bottom = 3;

        recent_files_grid.add (main_menu_button);
        recent_files_grid.add (sub_separator);
        recent_files_popover.add (recent_files_grid);

        fetch_recent_files ();

        var open_recent_button = new Gtk.ModelButton ();
        open_recent_button.text = _("Open Recent");
        open_recent_button.menu_name = "files-menu";

        var separator2 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator2.margin_top = separator2.margin_bottom = 3;

        var save_button = new Akira.Partials.PopoverButton (
            _("Save"), {"<Ctrl>s"});
        save_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_SAVE;

        var save_as_button = new Akira.Partials.PopoverButton (
            _("Save As"), {"<Ctrl><Shift>s"});
        save_as_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_SAVE_AS;

        var separator3 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator3.margin_top = separator3.margin_bottom = 3;

        var quit_button = new Akira.Partials.PopoverButton (
            _("Quit"), {"<Ctrl>q"});
        quit_button.action_name = Akira.Services.ActionManager.ACTION_PREFIX +
            Akira.Services.ActionManager.ACTION_QUIT;

        menu = new Akira.Partials.MenuButton ("document-open", _("Menu"), null);
        var menu_popover = new Gtk.PopoverMenu ();
        menu_popover.name = "main-menu";
        menu.button.popover = menu_popover;
        main_menu_button.menu_name = "main-menu";

        menu_popover_grid.add (new_window_button);
        menu_popover_grid.add (separator);
        menu_popover_grid.add (open_button);
        menu_popover_grid.add (open_recent_button);
        menu_popover_grid.add (separator2);
        menu_popover_grid.add (save_button);
        menu_popover_grid.add (save_as_button);
        menu_popover_grid.add (separator3);
        menu_popover_grid.add (quit_button);
        menu_popover_grid.show_all ();

        menu_popover.add (menu_popover_grid);

        var tools = new Gtk.Menu ();
        tools.add (new Gtk.MenuItem.with_label(_("Artboard")));
        tools.add (new Gtk.SeparatorMenuItem ());
        tools.add (new Gtk.MenuItem.with_label(_("Vector")));
        tools.add (new Gtk.MenuItem.with_label(_("Pencil")));
        var shapes_item = new Gtk.MenuItem.with_label(_("Shapes"));
        var shapes_submenu = new Gtk.Menu ();
        shapes_item.submenu = shapes_submenu;
        var rect_item = new Gtk.MenuItem.with_label(_("Rect"));
        rect_item.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_ADD_RECT;
        shapes_submenu.add (rect_item);
        var ellipse_item = new Gtk.MenuItem.with_label(_("Ellipse"));
        ellipse_item.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_ADD_ELLIPSE;
        shapes_submenu.add (ellipse_item);
        tools.add (shapes_item);
        tools.add (new Gtk.SeparatorMenuItem ());
        var text_item = new Gtk.MenuItem.with_label(_("Text"));
        text_item.action_name = Akira.Services.ActionManager.ACTION_PREFIX + Akira.Services.ActionManager.ACTION_ADD_TEXT;
        tools.add (text_item);
        tools.add (new Gtk.MenuItem.with_label(_("Image")));
        tools.show_all ();

        toolset = new Akira.Partials.MenuButton ("insert-object", _("Insert"), null);
        toolset.button.popup = tools;

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
        pack_start (toolset);
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

    private void build_signals () {
        // deal with signals not part of accelerators
    }

    public void button_sensitivity () {
        // dinamically toggle button sensitivity based on document status or actor selected.
    }

    public void update_icons_style () {
        menu.update_image ();
        toolset.update_image ();
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

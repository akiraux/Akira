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

public class Akira.Window : Gtk.ApplicationWindow {
    public FileFormat.AkiraFile? akira_file = null;
    public FileFormat.FileManager file_manager;

    public weak Akira.Application app { get; construct; }
    public Akira.Services.EventBus event_bus;
    public Akira.Lib.Managers.ItemsManager items_manager;

    public Akira.Services.ActionManager action_manager;
    public Akira.Layouts.HeaderBar headerbar;
    public Akira.Layouts.MainWindow main_window;
    public Akira.Utils.Dialogs dialogs;

    public Akira.StateManagers.CoordinatesMiddleware coords_middleware;
    public Akira.StateManagers.SizeMiddleware size_middleware;

    public SimpleActionGroup actions { get; construct; }
    public Gtk.AccelGroup accel_group { get; construct; }

    public bool edited { get; set; default = false; }

    public bool use_new_components = true;

    public Window (Akira.Application akira_app) {
        Object (
            application: akira_app,
            app: akira_app,
            icon_name: "com.github.akiraux.akira"
        );
    }

    construct {
        accel_group = new Gtk.AccelGroup ();
        add_accel_group (accel_group);

        event_bus = new Akira.Services.EventBus ();
        action_manager = new Akira.Services.ActionManager (app, this);

        headerbar = new Akira.Layouts.HeaderBar (this);

        if (use_new_components) {
            main_window = new Akira.Layouts.MainWindow (this);
        }
        else {
            items_manager = new Akira.Lib.Managers.ItemsManager (this);
            file_manager = new Akira.FileFormat.FileManager (this);
            main_window = new Akira.Layouts.MainWindow (this);
            coords_middleware = new Akira.StateManagers.CoordinatesMiddleware (this);
            size_middleware = new Akira.StateManagers.SizeMiddleware (this);
            dialogs = new Akira.Utils.Dialogs (this);
        }

        build_ui ();

        move (settings.pos_x, settings.pos_y);

        show_app ();

        // Let the canvas grab the focus after the app is visible.
        main_window.focus_canvas ();

        event_bus.file_edited.connect (on_file_edited);
        event_bus.file_saved.connect (on_file_saved);
    }

    private void build_ui () {
        set_titlebar (headerbar);
        set_border_width (0);
        if (Constants.PROFILE == "development") {
            headerbar.get_style_context ().add_class ("devel");
        }

        delete_event.connect ((e) => {
            return before_destroy ();
        });

        add (main_window);
    }

    private void apply_user_settings () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/com/github/akiraux/akira/stylesheet.css");

        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        resize (settings.window_width, settings.window_height);
        main_window.pane.position = settings.left_paned;
        main_window.pane2.position = settings.right_paned;
    }

    private void on_file_edited () {
        edited = true;
    }

    private void on_file_saved () {
        edited = false;
    }

    public bool before_destroy () {
        update_status ();

        if (!edited) {
            close_current_file ();
            app.get_active_window ().destroy ();
            on_destroy ();
        }

        if (edited) {
            var dialog = dialogs.message_dialog (
                _("Are you sure you want to quit?"),
                _("All unsaved data will be lost and impossible to recover."),
                "system-shutdown",
                _("Quit without saving!"),
                _("Save file")
            );

            dialog.show_all ();

            dialog.response.connect ((id) => {
                switch (id) {
                    case Gtk.ResponseType.ACCEPT:
                        dialog.destroy ();
                        close_current_file ();
                        app.get_active_window ().destroy ();
                        on_destroy ();
                        break;
                    case 2:
                        dialog.destroy ();
                        file_manager.save_file ();
                        break;
                    default:
                        dialog.destroy ();
                        break;
                }
            });

            dialog.run ();
        }

        return true;
    }

    public void on_destroy () {
        uint length = app.windows.length ();

        if (length == 0) {
            app.quit ();
        }
    }

    private void update_status () {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.pos_x = x;
        settings.pos_y = y;
        settings.window_width = width;
        settings.window_height = height;
        settings.left_paned = main_window.pane.get_position ();
        settings.right_paned = main_window.pane2.get_position ();
    }

    public void show_app () {
        apply_user_settings ();
        show_all ();
        show ();
        present ();
    }

    public void open_file (File file) {
        akira_file = new FileFormat.AkiraFile (file, this);

        akira_file.prepare ();
        akira_file.load_file ();
    }

    public void save_new_file (File file, bool overwrite = false) {
        akira_file = new FileFormat.AkiraFile (file, this);
        akira_file.overwrite = overwrite;

        akira_file.prepare ();
        akira_file.save_file ();
    }

    private void close_current_file () {
        if (akira_file != null) {
            akira_file.close ();
        }
    }
}

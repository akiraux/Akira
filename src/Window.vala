/*
* Copyright (c) 2011-2017 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Window : Gtk.ApplicationWindow {
    public weak Akira.Application app { get; construct; }

    public Akira.Layouts.HeaderBar headerbar;
    public Akira.Layouts.MainWindow main_window;
    public Akira.Utils.Dialogs dialogs;

    public SimpleActionGroup actions { get; construct; }
    public Gtk.AccelGroup accel_group { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_NEW_WINDOW = "action_new_window";
    public const string ACTION_OPEN = "action_open";
    public const string ACTION_SAVE = "action_save";
    public const string ACTION_SAVE_AS = "action_save_as";
    public const string ACTION_PRESENTATION = "action_presentation";
    public const string ACTION_LABELS = "action_labels";
    public const string ACTION_QUIT = "action_quit";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] action_entries = {
        { ACTION_NEW_WINDOW, action_new_window },
        { ACTION_OPEN, action_open },
        { ACTION_SAVE, action_save },
        { ACTION_SAVE_AS, action_save_as },
        { ACTION_PRESENTATION, action_presentation },
        { ACTION_LABELS, action_labels },
        { ACTION_QUIT, action_quit }
    };

    public bool edited { get; set; default = false; }
    public bool confirmed { get; set; default = false; }

    public Window (Akira.Application akira_app) {
        Object (
            application: akira_app,
            app: akira_app,
            icon_name: "com.github.alecaddd.akira"
        );
    }

    static construct {
        action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
        action_accelerators.set (ACTION_OPEN, "<Control>o");
        action_accelerators.set (ACTION_SAVE, "<Control>s");
        action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
        action_accelerators.set (ACTION_PRESENTATION, "<Control>period");
        action_accelerators.set (ACTION_LABELS, "<Control>l");
        action_accelerators.set (ACTION_QUIT, "<Control>q");
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (action_entries, this);
        insert_action_group ("win", actions);

        foreach (var action in action_accelerators.get_keys ()) {
            app.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
        }
        
        accel_group = new Gtk.AccelGroup ();
        add_accel_group (accel_group);

        headerbar = new Akira.Layouts.HeaderBar (this);
        main_window = new Akira.Layouts.MainWindow ();
        dialogs = new Akira.Utils.Dialogs (this);

        build_ui ();

        move (settings.pos_x, settings.pos_y);
        resize (settings.window_width, settings.window_height);

        show_app ();
    }

    private void build_ui () {
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/com/github/alecaddd/akira/stylesheet.css");
        
        Gtk.StyleContext.add_provider_for_screen (
            Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        set_titlebar (headerbar);
        add (main_window);

        set_border_width (0);

        delete_event.connect ((e) => {
            return before_destroy ();
        });
    }

    public bool before_destroy () {
        if (!edited) {
            app.get_active_window ().destroy ();
            on_destroy ();
        }
        if (edited) {
            confirmed = dialogs.message_dialog (_("Are you sure you want to quit?"), _("All unsaved data will be lost and impossible to recover."), "system-shutdown", _("Yes, Quit!"));

            if (confirmed) {
                app.get_active_window ().destroy ();
                on_destroy ();
            }
        }
        return true;
    }

    public void on_destroy () {
        uint length = app.windows.length ();

        if (length == 0) {
            Gtk.main_quit ();
        }
    }

    // This is a test, TBR!
    private void action_labels () {
        headerbar.toggle ();
        headerbar.menu.toggle ();
        headerbar.layout.toggle ();
        headerbar.ruler.toggle ();
        headerbar.toolset.toggle ();
        headerbar.settings.toggle ();
        headerbar.toggle ();
    }
    // END of test

    private void action_quit () {
        before_destroy ();
    }

    private void action_presentation () {
        headerbar.toggle ();
        main_window.statusbar.toggle ();
        main_window.left_sidebar.toggle ();
        main_window.right_sidebar.toggle ();
    }

    private void action_new_window () {
        app.new_window ();
    }

    private void action_open () {
        warning ("open");
    }

    private void action_save () {
        warning ("save");
    }

    private void action_save_as () {
        warning ("save_as");
    }

    protected override bool delete_event (Gdk.EventAny event) {
        int width, height, x, y;

        get_size (out width, out height);
        get_position (out x, out y);

        settings.pos_x = x;
        settings.pos_y = y;
        settings.window_width = width;
        settings.window_height = height;

        return false;
    }

    public void show_app () {
        show_all ();
        show ();
        present ();
    }
}
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
    private Akira.Application app;

    public Akira.Services.Shortcuts shortcuts;
    public Akira.Widgets.HeaderBar headerbar;
    public Akira.Widgets.MainWindow main_window;
    public Akira.Utils.Dialogs dialogs;

    public bool edited { get; set; default = false; }
    public bool confirmed { get; set; default = false; }

    public Window (Akira.Application app) {
        Object (application: app);
        this.app = app;
        //  install_ctrl_actions (this);
    }

    construct {
        headerbar = new Akira.Widgets.HeaderBar ();
        main_window = new Akira.Widgets.MainWindow ();
        shortcuts = new Akira.Services.Shortcuts (this);
        dialogs = new Akira.Utils.Dialogs (this);

        build_ui ();
        handle_signals ();
        key_press_event.connect ( (e) => shortcuts.handle (e));

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

    public void handle_signals () {
        headerbar.new_window.connect (new_window);
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

    public void new_window () {
        app.new_window ();
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

    //  private void install_ctrl_actions (Akira.Window win) {
    //      Gee.HashMap<string,VoidFunc> actions = new Gee.HashMap<string,VoidFunc> ();
    //      fill_actions (ref actions, win);
    //      int i = 0;
    //      int sz = actions.size;

    //      while (i < sz) {
    //          string k = actions.keys.to_array ()[i];
    //          var f = actions[k];
    //          var action_name = "win." + k;

    //          var action = new GLib.SimpleAction (action_name, null);
    //          action.activate.connect (() => warning ("IT WORKS!"));
    //          app.add_action (action);

    //          var accel_name = Gtk.accelerator_name (k.data[0], Gdk.ModifierType.CONTROL_MASK);
    //          app.add_accelerator (accel_name, action_name, null);

    //          i++;
    //      }
    //  }

    //  private void fill_actions (ref Gee.HashMap<string,VoidFunc> actions, Akira.Window win) {
    //      actions["q"] = () => warning ("IT WORKS!");
    //  }
}
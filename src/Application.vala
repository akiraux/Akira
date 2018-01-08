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

namespace Akira {
    public Akira.Services.Settings settings;
}

public class Akira.Application : Granite.Application {
    public GLib.List <Window> windows;

    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;
        build_data_dir = Constants.DATADIR;
        build_pkg_data_dir = Constants.PKGDATADIR;
        build_release_name = Constants.RELEASE_NAME;
        build_version = Constants.VERSION;
        build_version_info = Constants.VERSION_INFO;

        settings = new Akira.Services.Settings ();
        windows = new GLib.List <Window> ();

        program_name = "Akira";
        exec_name = "com.github.alecaddd.akira";
        app_launcher = "com.github.alecaddd.akira.desktop";
        application_id = "com.github.alecaddd.akira";
    }

    public void new_window () {
        new Akira.Window (this).present ();
    }

    public override void window_added (Gtk.Window window) {
        windows.append (window as Window);
        base.window_added (window);
    }

    public override void window_removed (Gtk.Window window) {
        windows.remove (window as Window);
        base.window_removed (window);
    }

    protected override void activate () {
        var window = new Akira.Window (this);
        this.add_window (window);
        //  install_ctrl_actions ();
    }

    //  private void install_ctrl_actions () {
    //      Gee.HashMap<string,VoidFunc> actions = new Gee.HashMap<string,VoidFunc> ();
    //      fill_actions (ref actions);
    //      int i = 0;
    //      int sz = actions.size;

    //      while (i < sz) {
    //          string k = actions.keys.to_array ()[i];
    //          var f = actions[k];
    //          var action_name = k;

    //          var action = new GLib.SimpleAction (action_name, null);
    //          action.activate.connect (() => warning ("close"));
    //          this.add_action (action);

    //          var accel_name = Gtk.accelerator_name (k.data[0], Gdk.ModifierType.CONTROL_MASK);
    //          this.add_accelerator (accel_name, action_name, null);

    //          i++;
    //      }
    //  }

    //  private void fill_actions (ref Gee.HashMap<string,VoidFunc> actions) {
    //      actions["q"] = () => warning ("close");
    //  }
}
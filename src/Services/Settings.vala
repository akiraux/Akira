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
*              Bilal Elmoussaoui <bil.elmoussaoui@gmail.com>
*/

public class Akira.Services.Settings : GLib.Settings {
    public int pos_x {
        get { return get_int ("pos-x"); }
        set { set_int ("pos-x", value); }
    }
    public int pos_y {
        get { return get_int ("pos-y"); }
        set { set_int ("pos-y", value); }
    }
    public int window_width {
        get { return get_int ("window-width"); }
        set { set_int ("window-width", value); }
    }
    public int window_height {
        get { return get_int ("window-height"); }
        set { set_int ("window-height", value); }
    }
    public int right_paned {
        get { return get_int ("right-paned"); }
        set { set_int ("right-paned", value); }
    }
    public int left_paned {
        get { return get_int ("left-paned"); }
        set { set_int ("left-paned", value); }
    }
    public bool dark_theme {
        get { return get_boolean ("dark-theme"); }
        set { set_boolean ("dark-theme", value); }
    }
    public bool show_label {
        get { return get_boolean ("show-label"); }
        set { set_boolean ("show-label", value); }
    }
    public bool use_symbolic {
        get { return get_boolean ("use-symbolic"); }
        set { set_boolean ("use-symbolic", value); }
    }
    public string fill_color {
        owned get { return get_string ("fill-color"); }
        set { set_string ("fill-color", value); }
    }
    public bool set_border {
        get { return get_boolean ("set-border"); }
        set { set_boolean ("set-border", value); }
    }
    public int border_size {
        get { return get_int ("border-size"); }
        set { set_int ("border-size", value); }
    }
    public string border_color {
        owned get { return get_string ("border-color"); }
        set { set_string ("border-color", value); }
    }
    public bool open_quick {
        get { return get_boolean ("open-quick"); }
        set { set_boolean ("open-quick", value); }
    }

    public Settings () {
        Object (schema_id: Constants.APP_ID);
    }
}

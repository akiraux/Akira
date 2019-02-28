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

public class Akira.Partials.ZoomButton : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public bool labelled {
		get {
			return label_btn.visible;
		} set {
			label_btn.visible = value;
			label_btn.no_show_all = !value;
		}
	}

    private Gtk.Label label_btn;
    public Gtk.Button zoom_out_button;
    public Gtk.Button zoom_default_button;
    public Gtk.Button zoom_in_button;

    public ZoomButton (Akira.Window main_window) {
		Object (
            window: main_window
		);
	}

	construct {
        get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);
		valign = Gtk.Align.CENTER;
        column_homogeneous = false;
        width_request = 140;
        hexpand = false;
        margin = 12;

		zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
        zoom_out_button.clicked.connect (zoom_out);
        zoom_out_button.get_style_context ().add_class ("raised");

        zoom_default_button = new Gtk.Button.with_label ("100%");
        zoom_default_button.hexpand = true;
        zoom_default_button.clicked.connect (zoom_reset);

        zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
        zoom_in_button.clicked.connect (zoom_in);
        zoom_in_button.get_style_context ().add_class ("raised");

        add (zoom_out_button);
        add (zoom_default_button);
        add (zoom_in_button);
	}
    
    public void toggle () {
		labelled = !labelled;
	}

	public void show_labels () {
		labelled = true;
		//  button.margin_top = 10;
		//  button.margin_bottom = 3;
		margin_bottom = 6;
	}

	public void hide_labels () {
		labelled = false;
		//  button.margin = 0;
		margin_bottom = 0;
    }
    
    public void zoom_out () {
        var zoom = int.parse (zoom_default_button.label) - 10;
        if (zoom < 0) {
            zoom_out_button.sensitive = false;
            return;
        }

        zoom_out_button.sensitive = true;
        zoom_default_button.label = "%.0f%%".printf (zoom);
        window.main_window.main_canvas.canvas.set_scale (window.main_window.main_canvas.canvas.get_scale () - 0.1);
        window.main_window.main_canvas.canvas.reset_select ();
    }

    public void zoom_in () {
        var zoom = int.parse (zoom_default_button.label) + 10;
        if (zoom > 1000) {
            zoom_in_button.sensitive = false;
            return;
        }

        zoom_in_button.sensitive = true;
        zoom_default_button.label = "%.0f%%".printf (zoom);
        window.main_window.main_canvas.canvas.set_scale (window.main_window.main_canvas.canvas.get_scale () + 0.1);
        window.main_window.main_canvas.canvas.reset_select ();
    }

    public void zoom_reset () {
        zoom_in_button.sensitive = true;
        zoom_out_button.sensitive = true;
        zoom_default_button.label = "100%";
        window.main_window.main_canvas.canvas.set_scale (1);
        window.main_window.main_canvas.canvas.reset_select ();
    }
}
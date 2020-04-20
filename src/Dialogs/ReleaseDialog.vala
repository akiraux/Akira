/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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

public class Akira.Dialogs.ReleaseDialog : Gtk.Dialog {
    public weak Akira.Window window { get; construct; }

    public ReleaseDialog (Akira.Window window) {
        Object (
            window: window,
            border_width: 10,
            deletable: true,
            resizable: false,
            modal: true
        );
    }

    construct {
        transient_for = window;
        default_width = 824;

        var banner_grid = new Gtk.Grid ();
        banner_grid.get_style_context ().add_class ("banner");
        banner_grid.halign = Gtk.Align.CENTER;
        banner_grid.width_request = 800;
        banner_grid.height_request = 267;

        var disclaimer = new Gtk.Label (
            _("WARNING!\nAkira is still under development and not ready for production. Missing features, random bugs, and black holes opening in your kitchen are to be expected."
            )
        );
        disclaimer.justify = Gtk.Justification.CENTER;
        disclaimer.margin_top = disclaimer.margin_bottom = 6;
        disclaimer.margin_start = disclaimer.margin_end = 3;
        disclaimer.max_width_chars = 80;
        disclaimer.wrap = true;

        var warning_grid = new Gtk.Grid ();
        warning_grid.halign = Gtk.Align.CENTER;
        warning_grid.margin_top = warning_grid.margin_bottom = 12;
        warning_grid.get_style_context ().add_class ("warning-message");
        warning_grid.add (disclaimer);

        var app_version = new Gtk.Label ("v" + Constants.VERSION + " - alpha");
        app_version.get_style_context ().add_class ("h2");
        app_version.selectable = true;

        var version_date = new Gtk.Label ("Apr 26th, 2020");
        version_date.get_style_context ().add_class ("dim-label");

        var header_grid = new Gtk.Grid ();
        header_grid.halign = Gtk.Align.CENTER;
        header_grid.margin_bottom = 12;
        header_grid.attach (app_version, 0, 0);
        header_grid.attach (version_date, 0, 1);

        // <p>Experimental Alpha Release, say Hi to Akira!</p>
        // <ul>
        //   <li>Create Artboards and nested basic shapes</li>
        //   <li>Manage the fill and border properties of shapes</li>
        //   <li>Import images</li>
        //   <li>Export custom areas, selections, and artboards</li>
        //   <li>So many crashes and missing features you wouldn't believe, but hey, this is an experimental alpha…</li>
        // </ul>

        // Button grid at the bottom of the dialog.
        var button_grid = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_grid.halign = Gtk.Align.CENTER;
        button_grid.spacing = 6;
        button_grid.margin_top = 12;

        var donate_button = new Gtk.Button.with_label (_("Make a Donation"));
        donate_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/akiraux/Akira#-support", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        var translate_button = new Gtk.Button.with_label (_("Suggest Translations"));
        translate_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/akiraux/Akira/issues", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        var bug_button = new Gtk.Button.with_label (_("Report a Problem"));
        bug_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/akiraux/Akira/issues", null);
            } catch (Error e) {
                warning (e.message);
            }
        });

        button_grid.add (donate_button);
        button_grid.add (translate_button);
        button_grid.add (bug_button);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.hexpand = true;

        grid.attach (banner_grid, 0, 0);
        grid.attach (warning_grid, 0, 1);
        grid.attach (header_grid, 0, 2);
        grid.attach (button_grid, 0, 8);

        var content_area = get_content_area ();
        content_area.border_width = 12;
        content_area.add (grid);
    }
}

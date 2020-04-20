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

        var banner = new Gtk.Grid ();
        banner.get_style_context ().add_class ("banner");
        banner.halign = Gtk.Align.CENTER;
        banner.width_request = 800;
        banner.height_request = 267;

        var disclaimer = new Gtk.Label (
            _("WARNING!\nAkira is still under development and not ready for production. Missing features, random bugs, and black holes opening in your kitchen are to be expected."
            )
        );
        disclaimer.justify = Gtk.Justification.CENTER;
        disclaimer.margin_top = disclaimer.margin_bottom = 6;
        disclaimer.margin_start = disclaimer.margin_end = 3;
        disclaimer.max_width_chars = 80;
        disclaimer.wrap = true;

        var warning = new Gtk.Grid ();
        warning.halign = Gtk.Align.CENTER;
        warning.margin_top = disclaimer.margin_bottom = 12;
        warning.get_style_context ().add_class ("warning-message");
        warning.add (disclaimer);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.hexpand = true;

        grid.attach (banner, 0, 0);
        grid.attach (warning, 0, 1);

        var content_area = get_content_area ();
        content_area.border_width = 12;
        content_area.add (grid);
    }
}

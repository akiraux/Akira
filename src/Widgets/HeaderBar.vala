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

public class Akira.Widgets.HeaderBar : Gtk.Box {
    private Gtk.HeaderBar headerbar;
    private Gtk.Box toolbar;
    private Gee.ArrayList<Gtk.Button> buttons;

    private Gtk.Button new_document;
    private Gtk.Button save_file;
    private Gtk.Button save_file_as;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public signal void new_window ();

    public HeaderBar () {
        Object (orientation: Gtk.Orientation.VERTICAL, toggled: true);
    }

    construct {
        headerbar = new Gtk.HeaderBar ();

        headerbar.set_title (APP_NAME);
        headerbar.set_show_close_button (true);

        pack_start (headerbar, true, true, 0);

        toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        toolbar.margin_start = 15;
        toolbar.margin_end = 15;
        toolbar.margin_top = 5;
        toolbar.margin_bottom = 15;

        buttons = new Gee.ArrayList<Gtk.Button> ();
        buttons.add (new_document = new Akira.Partials.HeaderBarButton ("document-new", _("New Document (Ctrl+n)")));
        buttons.add (save_file = new Akira.Partials.HeaderBarButton ("document-save", _("Save (Ctrl+s)")));
        buttons.add (save_file_as = new Akira.Partials.HeaderBarButton ("document-save-as", _("Save As (Ctrl+⇧+s)")));

        foreach (Gtk.Button button in buttons) {
            toolbar.add (button);
        }
        toolbar.add (new Akira.Partials.Spacer (40));

        save_file.sensitive = false;

        var icon_mode = new Granite.Widgets.ModeButton ();
        icon_mode.append_icon ("view-grid-symbolic", Gtk.IconSize.BUTTON);
        icon_mode.append_icon ("view-list-symbolic", Gtk.IconSize.BUTTON);
        icon_mode.append_icon ("view-column-symbolic", Gtk.IconSize.BUTTON);

        toolbar.add (icon_mode);

        pack_start (toolbar, true, true, 0);

        build_signals ();
    }

    private void build_signals () {
        new_document.clicked.connect (() => {
            new_window ();
        });
    }

    public void button_sensitivity () {
        // dinamically toggle button sensitivity based on document status or actor selected.
    }

    public void toggle () {
        toggled = !toggled;
    }
}

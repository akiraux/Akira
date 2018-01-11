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

public class Akira.Widgets.HeaderBar : Gtk.HeaderBar {
    private const string TOOLS_DIR = "/com/github/alecaddd/akira/tools/";

    public Akira.Partials.HeaderBarButton new_document;
    public Akira.Partials.HeaderBarButton save_file;
    public Akira.Partials.HeaderBarButton save_file_as;

    public Akira.Partials.MenuButton menu;
    public Akira.Partials.MenuButton toolset;
    public Akira.Partials.MenuButton settings;
    public Akira.Partials.HeaderBarButton layout;
    public Akira.Partials.HeaderBarButton ruler;

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
        Object (toggled: true);
    }

    construct {
        set_title (APP_NAME);
        set_show_close_button (true);

        var menu_items = new Gtk.Menu ();
        menu_items.add (new Gtk.MenuItem.with_label(_("Open")));
        menu_items.add (new Gtk.MenuItem.with_label(_("Save")));
        menu_items.add (new Gtk.MenuItem.with_label(_("Save As")));
        menu_items.add (new Gtk.SeparatorMenuItem ());
        menu_items.add (new Gtk.MenuItem.with_label(_("Quit")));
        menu_items.show_all ();

        menu = new Akira.Partials.MenuButton ("document-open", _("Menu"), _("Open Menu"));
        menu.popup = menu_items;

        var tools = new Gtk.Menu ();
        tools.add (new Gtk.MenuItem.with_label(_("Artboard")));
        tools.add (new Gtk.SeparatorMenuItem ());
        tools.add (new Gtk.MenuItem.with_label(_("Vector")));
        tools.add (new Gtk.MenuItem.with_label(_("Pencil")));
        tools.add (new Gtk.MenuItem.with_label(_("Shapes")));
        tools.add (new Gtk.SeparatorMenuItem ());
        tools.add (new Gtk.MenuItem.with_label(_("Text")));
        tools.add (new Gtk.MenuItem.with_label(_("Image")));
        tools.show_all ();

        toolset = new Akira.Partials.MenuButton ("insert-object", _("Add"), _("Add a New Object"));
        toolset.popup = tools;

        settings = new Akira.Partials.MenuButton ("open-menu", _("Settings"), _("Open Settings"));

        layout = new Akira.Partials.HeaderBarButton ("preferences-system-windows", _("Layout"), _("Toggle Layout (Ctrl+.)"));
        ruler = new Akira.Partials.HeaderBarButton ("applications-accessories", _("Ruler"), _("Toggle Ruler (Ctrl+⇧+R)"));

        add (menu);
        add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        add (toolset);
        add (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_end (settings);
        pack_end (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        pack_end (layout);
        pack_end (ruler);

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

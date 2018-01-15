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
    public weak Akira.Window window { get; construct; }

    private const string TOOLS_DIR = "/com/github/alecaddd/akira/tools/";

    public Akira.Partials.HeaderBarButton new_document;
    public Akira.Partials.HeaderBarButton save_file;
    public Akira.Partials.HeaderBarButton save_file_as;

    public Akira.Partials.MenuButton menu;
    public Akira.Partials.MenuButton toolset;
    public Akira.Partials.HeaderBarButton settings;
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

    public HeaderBar (Akira.Window main_window) {
        Object (
            toggled: true,
            window: main_window
        );
    }

    construct {
        set_title (APP_NAME);
        set_show_close_button (true);

        var menu_items = new Gtk.Menu ();

        var new_window = new Gtk.MenuItem.with_label (_("New Window"));
        new_window.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_NEW_WINDOW;
        new_window.add_accelerator ("activate", window.accel_group, Gdk.keyval_from_name("N"), Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        menu_items.add (new_window);
        menu_items.add (new Gtk.SeparatorMenuItem ());

        var open = new Gtk.MenuItem.with_label (_("Open"));
        open.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_OPEN;
        open.add_accelerator ("activate", window.accel_group, Gdk.keyval_from_name("O"), Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        menu_items.add (open);

        var save = new Gtk.MenuItem.with_label (_("Save"));
        save.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_SAVE;
        save.add_accelerator ("activate", window.accel_group, Gdk.keyval_from_name("S"), Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        menu_items.add (save);

        var save_as = new Gtk.MenuItem.with_label (_("Save As"));
        save_as.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_SAVE_AS;
        save_as.add_accelerator ("activate", window.accel_group, Gdk.keyval_from_name("S"), Gdk.ModifierType.CONTROL_MASK + Gdk.ModifierType.SHIFT_MASK, Gtk.AccelFlags.VISIBLE);
        menu_items.add (save_as);

        menu_items.add (new Gtk.SeparatorMenuItem ());

        var quit = new Gtk.MenuItem.with_label(_("Quit"));
        quit.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_QUIT;
        quit.add_accelerator ("activate", window.accel_group, Gdk.keyval_from_name("Q"), Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE);
        menu_items.add (quit);

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

        settings = new Akira.Partials.HeaderBarButton ("preferences-other", _("Preferences"), _("Open Preferences (Ctrl+,)"));

        layout = new Akira.Partials.HeaderBarButton ("preferences-system-windows", _("Layout"), _("Toggle Layout (Ctrl+.)"));
        layout.action_name = Akira.Window.ACTION_PREFIX + Akira.Window.ACTION_PRESENTATION;
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
        // deal with signals not part of accelerators
    }

    public void button_sensitivity () {
        // dinamically toggle button sensitivity based on document status or actor selected.
    }

    public void toggle () {
        toggled = !toggled;
    }
}

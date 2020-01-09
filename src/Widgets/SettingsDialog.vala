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

public class Akira.Widgets.SettingsDialog : Gtk.Dialog {
    public weak Akira.Window window { get; construct; }
    private Gtk.Stack stack;
    private Gtk.Switch dark_theme_switch;
    private Gtk.Switch label_switch;
    private Gtk.Switch symbolic_switch;
    private Gtk.Switch border_switch;
    private Gtk.ColorButton fill_color;
    private Gtk.ColorButton border_color;
    private Gtk.SpinButton border_size;

    enum Column {
        ICONTYPE
    }

    public SettingsDialog (Akira.Window _window) {
        Object (
            window: _window,
            border_width: 5,
            deletable: false,
            resizable: false,
            modal: true,
            title: _("Preferences")
        );
    }

    construct {
        transient_for = window;
        stack = new Gtk.Stack ();
        stack.margin = 6;
        stack.margin_bottom = 15;
        stack.margin_top = 15;
        stack.add_titled (get_general_box (), "general", _("General"));
        stack.add_titled (get_interface_box (), "interface", _("Interface"));
        stack.add_titled (get_shapes_box (), "shapes", _("Shapes"));

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.set_stack (stack);
        stack_switcher.halign = Gtk.Align.CENTER;

        var grid = new Gtk.Grid ();
        grid.halign = Gtk.Align.CENTER;
        grid.attach (stack_switcher, 1, 1, 1, 1);
        grid.attach (stack, 1, 2, 1, 1);

        get_content_area ().add (grid);

        var close_button = new SettingsButton (_("Close"));

        close_button.clicked.connect (() => {
            destroy ();
            window.event_bus.set_focus_on_canvas ();
        });

        add_action_widget (close_button, 0);
    }

    private Gtk.Widget get_general_box () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.column_homogeneous = true;

        grid.attach (new SettingsHeader (_("General")), 0, 0, 2, 1);
        grid.attach (new SettingsLabel (_("Auto Reopen Latest File:")), 0, 1, 1, 1);
        grid.attach (new SettingsSwitch ("open-quick"), 1, 1, 1, 1);

        return grid;
    }

    private Gtk.Widget get_interface_box () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.column_homogeneous = true;

        grid.attach (new SettingsHeader (_("Interface")), 0, 0, 2, 1);

        grid.attach (new SettingsLabel (_("Use Dark Theme:")), 0, 1, 1, 1);
        dark_theme_switch = new SettingsSwitch ("dark-theme");

        grid.attach (dark_theme_switch, 1, 1, 1, 1);

        dark_theme_switch.notify["active"].connect (() => {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;
        });

        grid.attach (new SettingsHeader (_("ToolBar Style")), 0, 2, 2, 1);

        grid.attach (new SettingsLabel (_("Show Button Labels:")), 0, 3, 1, 1);
        label_switch = new SettingsSwitch ("show-label");
        grid.attach (label_switch, 1, 3, 1, 1);

        grid.attach (new SettingsLabel (_("Use Symbolic Icons:")), 0, 4, 1, 1);
        symbolic_switch = new SettingsSwitch ("use-symbolic");
        grid.attach (symbolic_switch, 1, 4, 1, 1);

        return grid;
    }

    private Gtk.Widget get_shapes_box () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.column_homogeneous = true;

        var fill_rgba = Gdk.RGBA ();
        fill_rgba.parse (settings.fill_color);
        var border_rgba = Gdk.RGBA ();
        border_rgba.parse (settings.border_color);

        grid.attach (new SettingsHeader (_("Default Colors")), 0, 0, 2, 1);

        var description = new Gtk.Label (_("Define the default style used when creating a new shape."));
        description.halign = Gtk.Align.START;
        description.margin_bottom = 10;
        grid.attach (description, 0, 1, 2, 1);

        grid.attach (new SettingsLabel (_("Fill Color:")), 0, 2, 1, 1);
        fill_color = new Gtk.ColorButton.with_rgba (fill_rgba);
        fill_color.halign = Gtk.Align.START;
        grid.attach (fill_color, 1, 2, 1, 1);

        fill_color.color_set.connect (() => {
            var rgba = fill_color.get_rgba ();

            //Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)" .printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("setting color: %s", rgba_str);

            settings.fill_color = rgba_str;
        });

        grid.attach (new SettingsLabel (_("Enable Border Style:")), 0, 3, 1, 1);
        border_switch = new SettingsSwitch ("set-border");
        grid.attach (border_switch, 1, 3, 1, 1);
        grid.attach (new SettingsLabel (_("Border Color:")), 0, 4, 1, 1);
        border_color = new Gtk.ColorButton.with_rgba (border_rgba);
        border_color.halign = Gtk.Align.START;
        grid.attach (border_color, 1, 4, 1, 1);

        border_color.color_set.connect (() => {
            var rgba = border_color.get_rgba ();

            //Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)".printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("setting color: %s", rgba_str);

            settings.border_color = rgba_str;
        });

        grid.attach (new SettingsLabel (_("Border Width:")), 0, 5, 1, 1);
        border_size = new Gtk.SpinButton.with_range (1, 9999, 1);
        border_size.halign = Gtk.Align.START;
        grid.attach (border_size, 1, 5, 1, 1);

        settings.bind ("border-size", border_size, "value", SettingsBindFlags.DEFAULT);

        border_switch.bind_property ("active", border_color, "sensitive");
        border_switch.bind_property ("active", border_size, "sensitive");

        return grid;
    }

    private class SettingsHeader : Gtk.Label {
        public SettingsHeader (string text) {
            label = text;
            get_style_context ().add_class ("h4");
            halign = Gtk.Align.START;
        }
    }

    private class SettingsLabel : Gtk.Label {
        public SettingsLabel (string text) {
            label = text;
            halign = Gtk.Align.END;
        }
    }

    private class SettingsSwitch : Gtk.Switch {
        public SettingsSwitch (string setting) {
            halign = Gtk.Align.START;
            settings.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
        }
    }

    private class SettingsButton : Gtk.Button {
        public SettingsButton (string text) {
            label = text;
            valign = Gtk.Align.END;
            get_style_context ().add_class ("suggested-action");
        }
    }
}

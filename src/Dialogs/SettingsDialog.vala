/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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

public class Akira.Dialogs.SettingsDialog : Gtk.Dialog {
    public weak Akira.Window window { get; construct; }
    private Gtk.Stack stack;
    private Gtk.Switch dark_theme_switch;
    private Gtk.Switch label_switch;
    private Gtk.Switch symbolic_switch;
    private Gtk.Switch border_switch;
    private Gtk.ColorButton grid_color;
    private Gtk.ColorButton snaps_color;
    private Gtk.ColorButton fill_color;
    private Gtk.ColorButton border_color;
    private Gtk.SpinButton border_size;
    private Gtk.ColorButton text_fill_color;
    private Partials.InputField text_size;
    private Gtk.ComboBoxText font_name;

    public string [] fonts = Utils.Font.get_fonts ();

    public SettingsDialog (Akira.Window _window) {
        Object (
            window: _window,
            border_width: 6,
            deletable: true,
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
        stack.add_titled (get_canvas_box (), "canvas", _("Canvas"));
        stack.add_titled (get_shapes_box (), "shapes", _("Shapes"));
        stack.add_titled (get_about_box (), "about", _("About"));

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.set_stack (stack);
        stack_switcher.halign = Gtk.Align.CENTER;

        var grid = new Gtk.Grid ();
        grid.halign = Gtk.Align.CENTER;
        grid.attach (stack_switcher, 1, 1, 1, 1);
        grid.attach (stack, 1, 2, 1, 1);

        get_content_area ().add (grid);
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

        grid.attach (new SettingsLabel (_("Invert Panels Order:")), 0, 2, 1, 1);
        symbolic_switch = new SettingsSwitch ("invert-sidebar");
        grid.attach (symbolic_switch, 1, 2, 1, 1);

        var panels_helper_label = new Gtk.Label (_("Restart application to apply this change."));
        panels_helper_label.get_style_context ().add_class ("dim-label");
        grid.attach (panels_helper_label, 1, 3, 1, 1);

        grid.attach (new SettingsHeader (_("ToolBar Style")), 0, 4, 2, 1);

        grid.attach (new SettingsLabel (_("Show Button Labels:")), 0, 5, 1, 1);
        label_switch = new SettingsSwitch ("show-label");
        grid.attach (label_switch, 1, 5, 1, 1);

        grid.attach (new SettingsLabel (_("Use Symbolic Icons:")), 0, 6, 1, 1);
        symbolic_switch = new SettingsSwitch ("use-symbolic");
        grid.attach (symbolic_switch, 1, 6, 1, 1);

        dark_theme_switch.notify["active"].connect (() => {
            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.dark_theme;
            window.event_bus.change_theme ();
        });

        return grid;
    }

    private Gtk.Widget get_canvas_box () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.column_homogeneous = true;

        // Pixel grid.
        var grid_rgba = Gdk.RGBA ();
        grid_rgba.parse (settings.grid_color);

        grid.attach (new SettingsHeader (_("Pixel Grid")), 0, 0, 2, 1);

        var description = new Gtk.Label (_("Define the default color for the Canvas pixel grid."));
        description.halign = Gtk.Align.START;
        description.margin_bottom = 10;
        grid.attach (description, 0, 1, 2, 1);

        grid.attach (new SettingsLabel (_("Pixel Grid Color:")), 0, 2, 1, 1);
        grid_color = new Gtk.ColorButton.with_rgba (grid_rgba);
        grid_color.halign = Gtk.Align.START;
        grid.attach (grid_color, 1, 2, 1, 1);

        grid_color.color_set.connect (() => {
            var rgba = grid_color.get_rgba ();

            // Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)".printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("pixel grid color: %s", rgba_str);

            settings.grid_color = rgba_str;
            window.event_bus.update_pixel_grid ();
        });

        // Snapping guides.
        var snaps_rgba = Gdk.RGBA ();
        snaps_rgba.parse (settings.snaps_color);

        grid.attach (new SettingsHeader (_("Snapping Guides")), 0, 3, 2, 1);

        var snaps_description = new Gtk.Label (_("Define the default options for the Snapping Guides."));
        snaps_description.halign = Gtk.Align.START;
        snaps_description.margin_bottom = 10;
        grid.attach (snaps_description, 0, 4, 2, 1);

        grid.attach (new SettingsLabel (_("Enable Snapping Guides:")), 0, 5, 1, 1);
        var snaps_switch = new SettingsSwitch ("enable-snaps");
        grid.attach (snaps_switch, 1, 5, 1, 1);

        grid.attach (new SettingsLabel (_("Snapping Guides Color:")), 0, 6, 1, 1);
        snaps_color = new Gtk.ColorButton.with_rgba (snaps_rgba);
        snaps_color.halign = Gtk.Align.START;
        grid.attach (snaps_color, 1, 6, 1, 1);

        snaps_color.color_set.connect (() => {
            var rgba = snaps_color.get_rgba ();

            // Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)".printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("pixel snaps color: %s", rgba_str);

            settings.snaps_color = rgba_str;
            window.event_bus.update_snaps_color ();
        });

        grid.attach (new SettingsLabel (_("Snapping Sensitivity Threshold:")), 0, 7, 1, 1);
        var snaps_sensitivity = new Gtk.SpinButton.with_range (0, 9999, 1);
        snaps_sensitivity.halign = Gtk.Align.START;
        snaps_sensitivity.width_chars = 6;
        snaps_sensitivity.get_style_context ().add_class ("input-icon-right");
        snaps_sensitivity.secondary_icon_name = "input-pixel-symbolic";
        snaps_sensitivity.secondary_icon_sensitive = false;
        snaps_sensitivity.secondary_icon_activatable = false;
        grid.attach (snaps_sensitivity, 1, 7, 1, 1);

        settings.bind ("snaps-sensitivity", snaps_sensitivity, "value", SettingsBindFlags.DEFAULT);

        snaps_switch.bind_property ("active", snaps_color, "sensitive", BindingFlags.SYNC_CREATE);
        snaps_switch.bind_property ("active", snaps_sensitivity, "sensitive", BindingFlags.SYNC_CREATE);

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

        var text_fill_rgba = Gdk.RGBA ();
        text_fill_rgba.parse (settings.text_color);

        grid.attach (new SettingsHeader (_("Default Colors")), 0, 0, 2, 1);

        var description = new Gtk.Label (_("Define the default style used when creating a new shape."));
        description.halign = Gtk.Align.START;
        description.margin_bottom = 10;
        grid.attach (description, 0, 1, 2, 1);

        grid.attach (new SettingsLabel (_("Fill Color:")), 0, 2, 1, 1);
        fill_color = new Gtk.ColorButton.with_rgba (fill_rgba);
        text_fill_color = new Gtk.ColorButton.with_rgba (text_fill_rgba);
        text_fill_color.halign = Gtk.Align.START;
        fill_color.halign = Gtk.Align.START;
        grid.attach (fill_color, 1, 2, 1, 1);

        fill_color.color_set.connect (() => {
            var rgba = fill_color.get_rgba ();

            // Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)".printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("setting color: %s", rgba_str);

            settings.fill_color = rgba_str;
        });

        text_fill_color.color_set.connect (() => {
            var rgba = text_fill_color.get_rgba ();

            // Gdk.RGBA uses rgb() if alpha is 1.
            string rgba_str = "rgba(%d,%d,%d,%d)".printf (
                (int) (rgba.red * 255),
                (int) (rgba.green * 255),
                (int) (rgba.blue * 255),
                (int) (rgba.alpha)
            );

            debug ("setting color: %s", rgba_str);

            settings.text_color = rgba_str;
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

            // Gdk.RGBA uses rgb() if alpha is 1.
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
        border_size.width_chars = 6;
        border_size.get_style_context ().add_class ("input-icon-right");
        border_size.secondary_icon_name = "input-pixel-symbolic";
        border_size.secondary_icon_sensitive = false;
        border_size.secondary_icon_activatable = false;
        grid.attach (border_size, 1, 5, 1, 1);
        grid.attach (new SettingsLabel (_("Text Tool Fill:")), 0, 6, 1, 1);
        grid.attach (text_fill_color, 1, 6, 1, 1);
        text_size = new Akira.Partials.InputField (Akira.Partials.InputField.Unit.PIXEL, 6, true, true);
        text_size.halign = Gtk.Align.START;
        text_size.entry.hexpand = false;
        text_size.entry.sensitive = true;
        text_size.set_range (1, 5000);
        grid.attach (new SettingsLabel (_("Text Tool Font Size:")), 0, 7, 1, 1);
        grid.attach (text_size, 1, 7, 1, 1);
        font_name = new Gtk.ComboBoxText.with_entry ();
        font_name.halign = Gtk.Align.START;
        foreach (string font in fonts) {
            font_name.append (font, font);
        }
        grid.attach (new SettingsLabel (_("Text Tool Font Name:")), 0, 8, 1, 1);
        grid.attach (font_name, 1, 8, 1, 1);

        settings.bind ("border-size", border_size, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("text-size", text_size.entry, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("text-font", font_name, "active_id", SettingsBindFlags.DEFAULT);

        border_switch.bind_property ("active", border_color, "sensitive", BindingFlags.SYNC_CREATE);
        border_switch.bind_property ("active", border_size, "sensitive", BindingFlags.SYNC_CREATE);

        return grid;
    }

    private Gtk.Widget get_about_box () {
        var grid = new Gtk.Grid ();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.halign = Gtk.Align.CENTER;

        var app_icon = new Gtk.Image ();
        app_icon.gicon = new ThemedIcon (Constants.APP_ID);
        app_icon.pixel_size = 64;
        app_icon.margin_top = 12;

        var app_name = new Gtk.Label (Constants.APP_NAME);
        app_name.get_style_context ().add_class ("h2");
        app_name.margin_top = 6;

        var app_description = new Gtk.Label (_("The Linux Design Tool"));
        app_description.get_style_context ().add_class ("h3");

        var app_version = new Gtk.Label ("v" + Constants.VERSION + " - alpha");
        app_version.get_style_context ().add_class ("dim-label");
        app_version.selectable = true;

        var disclaimer = new Gtk.Label (
            _("WARNING!\nAkira is still under development and not ready for production. Missing features, random bugs, and black holes opening in your kitchen are to be expected."
            )
        );
        disclaimer.justify = Gtk.Justification.CENTER;
        disclaimer.get_style_context ().add_class ("warning-message");
        disclaimer.max_width_chars = 60;
        disclaimer.wrap = true;
        disclaimer.margin_top = disclaimer.margin_bottom = 12;

        var patreons_label = new Gtk.Label (_("Thanks to our awesome supporters!"));
        patreons_label.get_style_context ().add_class ("h4");

        var patreons_url = new Gtk.LinkButton.with_label (
            "https://github.com/akiraux/Akira/blob/master/SUPPORTERS.md",
            _("View the list of supporters")
        );
        patreons_url.halign = Gtk.Align.CENTER;
        patreons_url.margin_bottom = 12;

        grid.attach (app_icon, 0, 0);
        grid.attach (app_name, 0, 1);
        grid.attach (app_description, 0, 2);
        grid.attach (app_version, 0, 3);
        grid.attach (disclaimer, 0, 4);
        grid.attach (patreons_label, 0, 5);
        grid.attach (patreons_url, 0, 6);

        // Button grid at the bottom of the About page.
        var button_grid = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        button_grid.halign = Gtk.Align.CENTER;
        button_grid.spacing = 6;

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

        grid.attach (button_grid, 0, 7);

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
}

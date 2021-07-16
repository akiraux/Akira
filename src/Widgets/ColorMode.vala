/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */
 public class Akira.Widgets.ColorMode {
    // these buttons will be used to switch between different coloring modes
    private Gtk.Button solid_color_button;
    private Gtk.Button linear_gradient_button;
    private Gtk.Button radial_gradient_button;
    // this button will be be used to delete the selected gradient step
    private Gtk.Button delete_step_button;

    private GradientEditor gradient_editor;
    public string color_mode_type;

    public Gtk.Grid buttons_grid;
    private unowned Models.ColorModel model;
    private unowned Window window;

    public ColorMode (Models.ColorModel _model, Window _window) {
        model = _model;
        color_mode_type = model.color_mode;
        window = _window;

        init_button_ui ();
    }

    private void init_button_ui () {

        solid_color_button = new Gtk.Button.from_icon_name ("solid-color-button", Gtk.IconSize.DND);
        solid_color_button.set_tooltip_text (_("Solid Color"));
        solid_color_button.can_focus = false;
        solid_color_button.valign = Gtk.Align.CENTER;

        linear_gradient_button = new Gtk.Button.from_icon_name ("linear-gradient-button", Gtk.IconSize.DND);
        linear_gradient_button.set_tooltip_text (_("Linear Gradient"));
        linear_gradient_button.can_focus = false;
        linear_gradient_button.valign = Gtk.Align.CENTER;

        radial_gradient_button = new Gtk.Button.from_icon_name ("radial-gradient-button", Gtk.IconSize.DND);
        radial_gradient_button.set_tooltip_text (_("Radial Gradient"));
        radial_gradient_button.can_focus = false;
        radial_gradient_button.valign = Gtk.Align.CENTER;

        delete_step_button = new Gtk.Button.from_icon_name ("user-trash-symbolic");
        delete_step_button.set_tooltip_text (_("Delete Gradient Step"));
        delete_step_button.can_focus = false;
        delete_step_button.valign = Gtk.Align.CENTER;
        delete_step_button.halign = Gtk.Align.CENTER;
        delete_step_button.margin = 10;

        solid_color_button.clicked.connect ( () => mode_button_pressed ("solid"));
        linear_gradient_button.clicked.connect ( () => mode_button_pressed ("linear"));
        radial_gradient_button.clicked.connect ( () => mode_button_pressed ("radial"));
        delete_step_button.clicked.connect (on_delete_button_pressed);

        gradient_editor = new GradientEditor (window, model, model.pattern);

        // since color modes on border havent been implmented yet, disable these buttons
        if (model.type == Akira.Models.ColorModel.Type.BORDER) {
            solid_color_button.sensitive = false;
            linear_gradient_button.sensitive = false;
            radial_gradient_button.sensitive = false;
            delete_step_button.sensitive = false;
        }

        Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        separator.hexpand = true;

        buttons_grid = new Gtk.Grid ();
        buttons_grid.attach (solid_color_button, 0, 0);
        buttons_grid.attach (linear_gradient_button, 1, 0);
        buttons_grid.attach (radial_gradient_button, 2, 0);
        buttons_grid.attach (separator, 3, 0);

        buttons_grid.attach (gradient_editor, 0, 1, 4, 1);
        buttons_grid.attach (delete_step_button, 4, 1);
    }

    private void mode_button_pressed (string _color_mode_type) {
        color_mode_type = _color_mode_type;
        model.color_mode = color_mode_type;
        window.event_bus.color_mode_changed (color_mode_type);
    }

    private void on_delete_button_pressed () {
        if (color_mode_type != "solid") {
            gradient_editor.delete_selected_step ();
        }
    }

 }

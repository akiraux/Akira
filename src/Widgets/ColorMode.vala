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

/*
 * Helper class to quickly create a container with a color button and a color
 * picker. The color button opens up the GtkColorChooser.
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
    private Models.ColorModel model;
    private ColorRow color_row;

    public ColorMode (Models.ColorModel _model, ColorRow _color_row) {
        model = _model;
        color_row = _color_row;
        color_mode_type = "solid";
        
        color_row.color_changed.connect(on_color_changed);

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
        delete_step_button.set_tooltip_text(_("Delete Gradient Step"));
        delete_step_button.can_focus = false;
        delete_step_button.valign = Gtk.Align.CENTER;
        delete_step_button.halign = Gtk.Align.CENTER;

        solid_color_button.clicked.connect ( () => mode_button_pressed ("solid"));
        linear_gradient_button.clicked.connect ( () => mode_button_pressed ("linear"));
        radial_gradient_button.clicked.connect ( () => mode_button_pressed ("radial"));
        delete_step_button.clicked.connect (delete_selected_step);

        gradient_editor = new GradientEditor(this);

        Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
        separator.hexpand = true;
        
        buttons_grid = new Gtk.Grid();
        buttons_grid.attach (solid_color_button, 0, 0);
        buttons_grid.attach (linear_gradient_button, 1, 0);
        buttons_grid.attach (radial_gradient_button, 2, 0);
        buttons_grid.attach (separator, 3, 0);
        
        buttons_grid.attach (gradient_editor, 0, 1, 4, 4);
        buttons_grid.attach (delete_step_button, 4, 1);
    }

    private void mode_button_pressed(string _color_mode_type) {
        color_mode_type = _color_mode_type;
        gradient_editor.on_color_mode_changed();

    }

    public void on_color_changed (string color, double alpha) {
        if(color_mode_type == "solid") {
            // Update the model values.
            model.color = color;
            model.alpha = (int) (alpha * 255);
            
            } else {
                gradient_editor.on_color_changed (color, alpha);
            }
            
    }
    
    private void delete_selected_step () {

    }

 }

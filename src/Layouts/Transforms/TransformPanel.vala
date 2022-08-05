/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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

/*
 * Layout component containing the input fields representing the transformation
 * matrix of the selected items.
 */
public class Akira.Layouts.Transforms.TransformPanel : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public Widgets.LinkedInput x_input;
    public Widgets.LinkedInput y_input;

    public Widgets.LinkedInput width_input;
    public Widgets.LinkedInput height_input;

    public Widgets.LinkedInput rotation_input;

    public TransformPanel (Lib.ViewCanvas canvas) {
        Object (view_canvas: canvas);

        border_width = 12;
        row_spacing = column_spacing = 6;
        hexpand = true;

        var lock_image = new Gtk.Image.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.BUTTON);
        var lock_button = new Gtk.ToggleButton () {
            tooltip_text = _("Lock Ratio"),
            image = lock_image,
            can_focus = false,
            sensitive = false
        };
        lock_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        lock_button.get_style_context ().add_class ("label-colors");

        var hflip_button = new Gtk.ToggleButton () {
            hexpand = false,
            can_focus = false,
            sensitive = false,
            halign = valign = Gtk.Align.CENTER,
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>bracketleft"}, _("Flip Horizontally"))
        };
        hflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        hflip_button.add (new Widgets.ButtonImage ("object-flip-horizontal"));

        var vflip_button = new Gtk.ToggleButton () {
            hexpand = false,
            can_focus = false,
            sensitive = false,
            halign = valign = Gtk.Align.CENTER,
            tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>bracketright"}, _("Flip Vertically"))
        };
        vflip_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        vflip_button.add (new Widgets.ButtonImage ("object-flip-vertical"));

        var align_grid = new Gtk.Grid ();
        align_grid.hexpand = true;
        align_grid.column_homogeneous = true;
        align_grid.attach (hflip_button, 0, 0, 1, 1);
        align_grid.attach (vflip_button, 1, 0, 1, 1);

        var scale = new Gtk.Scale (
            Gtk.Orientation.HORIZONTAL,
            new Gtk.Adjustment (100.0, 0, 100.0, 0, 0, 0)
        ) {
            hexpand = true,
            sensitive = false,
            draw_value = false,
            digits = 0,
            margin_end = 20
        };

        var opacity_entry = new Widgets.InputField (
            view_canvas, Widgets.InputField.Unit.PERCENTAGE, 7, true, true);
        opacity_entry.entry.hexpand = false;
        opacity_entry.entry.width_request = 64;

        var opacity_grid = new Gtk.Grid ();
        opacity_grid.hexpand = true;
        opacity_grid.attach (scale, 0, 0, 1);
        opacity_grid.attach (opacity_entry, 1, 0, 1);

        attach (group_title (_("Position")), 0, 0, 3);

        x_input = new Widgets.LinkedInput (view_canvas, _("X"), _("Horizontal position"));
        attach (x_input, 0, 1, 1);

        y_input = new Widgets.LinkedInput (view_canvas, _("Y"), _("Vertical position"));
        attach (y_input, 2, 1, 1);

        attach (separator (), 0, 2, 3);

        attach (group_title (_("Size")), 0, 3, 3);
        width_input = new Widgets.LinkedInput (view_canvas, _("W"), _("Width"));
        attach (width_input, 0, 4, 1);

        attach (lock_button, 1, 4, 1);

        height_input = new Widgets.LinkedInput (view_canvas, _("H"), _("Height"));
        attach (height_input, 2, 4, 1);

        attach (separator (), 0, 5, 3);

        attach (group_title (_("Transform")), 0, 6, 3);

        rotation_input = new Widgets.LinkedInput (view_canvas, _("R"), _("Rotation degrees"), Widgets.InputField.Unit.DEGREES);
        attach (rotation_input, 0, 7, 1);

        attach (align_grid, 2, 7, 1);
        attach (separator (), 0, 8, 3);
        attach (group_title (_("Opacity")), 0, 9, 3);
        attach (opacity_grid, 0, 10, 3);

        view_canvas.window.event_bus.selection_geometry_modified.connect (on_selection_geometry_modified);
    }

    private Gtk.Label group_title (string title) {
        var title_label = new Gtk.Label (title) {
            halign = Gtk.Align.START,
            hexpand = true,
            margin_bottom = 2
        };
        title_label.get_style_context ().add_class ("group-title");

        return title_label;
    }

    private Gtk.Separator separator () {
        var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
            margin_bottom = 6
        };
        sep.get_style_context ().add_class ("panel-separator");

        return sep;
    }

    private void on_selection_geometry_modified () {
        unowned var sm = view_canvas.selection_manager;
        if (sm.selection == null || sm.selection.is_empty ()) {
          x_input.input_field.entry.set_value (0);
          y_input.input_field.entry.set_value (0);
          width_input.input_field.entry.set_value (0);
          height_input.input_field.entry.set_value (0);
          rotation_input.input_field.entry.set_value (0);
          return;
        }

        var quad = sm.selection.area (). quad ();

        x_input.input_field.entry.set_value (quad.tl_x);
        y_input.input_field.entry.set_value (quad.tl_y);
        width_input.input_field.entry.set_value (quad.width);
        height_input.input_field.entry.set_value (quad.height);

        double rot = Utils.GeometryMath.matrix_rotation_component (quad.transformation) * 180 / Math.PI;
        rotation_input.input_field.entry.set_value (rot);
    }
}

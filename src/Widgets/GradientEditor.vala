
/**
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

/*
 * This class creates a widget that allows user to create new stop points,
 * select existing stop points and assign them colors.
 *
 * When a different PatternType is selected from PatternChooser, this widget 
 * will redraw using the stop colors of that pattern.
 *
 * In order to visualize the pattern, the background of this widget will be colored
 * with a linear gradient. 
 *
 * It is disabled for SOLID pattern type.
 */
public class Akira.Widgets.GradientEditor : Gtk.DrawingArea {
    public const double NOB_RADII = 5;
    public const double STROKE_WIDTH = 0.5;

    // This signal will be triggered when pattern is editor using this editor.
    // The PatternChooser will handle this signal.
    public signal void pattern_edited (Lib.Components.Pattern pattern);
    public signal void color_changed (Gdk.RGBA color);

    // Dimensions of the widget.
    private double width;
    private double height;

    // Represents all the stop colors of current pattern.
    private Lib.Components.Pattern pattern;
    // Represents currently active stop color.
    private unowned Lib.Components.Pattern.StopColor selected_stop_color;

    public GradientEditor (Lib.Components.Pattern pattern) {
        hexpand = true;
        height_request = 40;
        margin = 5;

        set_events (
            Gdk.EventMask.BUTTON_PRESS_MASK |
            Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.BUTTON_MOTION_MASK
        );

        this.pattern = pattern;

        size_allocate.connect (() => {
            width = get_allocated_width ();
            height = get_allocated_height ();

            draw.connect (draw_editor);
        });

        color_changed.connect (handle_color_changed);

        this.button_press_event.connect (handle_button_press);
        this.motion_notify_event.connect (handle_motion_notify);
        this.button_release_event.connect (handle_button_release);
    }

    public void set_pattern (Lib.Components.Pattern pattern) {
        this.pattern = pattern;
        queue_draw ();
    }

    private bool draw_editor (Cairo.Context context) {
        draw_pattern (context);
        draw_stop_colors (context);

        return true;
    }

    private void draw_pattern (Cairo.Context context) {
        context.set_source_rgba (1, 1, 0, 1);
        context.move_to (0, 0);
        context.rectangle (0, 0, width, height);
        context.stroke ();

        var linear_pattern = new Lib.Components.Pattern.linear (
            Geometry.Point (0, height / 2.0),
            Geometry.Point (width, height / 2.0),
            false
        );

        linear_pattern.colors = pattern.colors;

        var converted_pattern = Utils.Pattern.convert_to_cairo_pattern (linear_pattern);
        context.set_source (converted_pattern);
        context.rectangle (0, 0, width, height);
        context.fill ();
    }

    private void draw_stop_colors (Cairo.Context context) {
        if (is_solid_pattern ()) {
            return;
        }

        context.set_source_rgba (0, 0, 0, 1);
        context.set_line_width (STROKE_WIDTH);

        // First, draw the horizontal line over which all stop color nobs will be placed.
        // Painting two strokes of contrasting colors makes it easier to spot the line.
        context.move_to (0, height / 2.0 - STROKE_WIDTH);
        context.line_to (width, height / 2.0 - STROKE_WIDTH);

        context.stroke ();
        context.set_source_rgba (1, 1, 1, 1);

        context.move_to (0, height / 2.0 + STROKE_WIDTH);
        context.line_to (width, height / 2.0 + STROKE_WIDTH);

        context.stroke ();

        // Paint the stop colors.
        foreach (var stop_color in pattern.colors) {
            var position = stop_color.offset * width;

            if (selected_stop_color.offset == stop_color.offset) {
                context.set_source_rgba (0.1568, 0.4745, 0.9823, 1);
            } else {
                context.set_source_rgba (0, 0, 0, 1);
            }

            context.arc (position, height / 2.0, NOB_RADII, 0, 2 * Math.PI);
            context.fill ();

            context.set_source_rgba (1, 1, 1, 1);
            context.set_line_width (2 * STROKE_WIDTH);
            context.arc (position, height / 2.0, NOB_RADII + 1, 0, 2 * Math.PI);
            context.stroke ();
        }
    }

    private void handle_color_changed (Gdk.RGBA color) {
        pattern.colors.remove (selected_stop_color);
        selected_stop_color.color = color;
        pattern.colors.add (selected_stop_color);

        pattern_edited (pattern);
        queue_draw ();
    }

    private bool handle_button_press (Gdk.EventButton event) {
        if (is_solid_pattern ()) {
            return true;
        }

        // Offset of current event expressed as fraction of width.
        double event_offset = event.x / width;

        // Get the stop color at this location.
        // If none exists, get ones that are just greater or smaller than it.
        var left_stop_color = pattern.colors.floor (Lib.Components.Pattern.StopColor () {offset = event_offset});
        var right_stop_color = pattern.colors.ceil (Lib.Components.Pattern.StopColor () {offset = event_offset});

        double left_offset_actual_value = (left_stop_color.offset - event_offset) * width;
        double right_offset_actual_value = (right_stop_color.offset - event_offset) * width;

        // Check which one is within the threshold.
        if (left_offset_actual_value.abs () < NOB_RADII) {
            selected_stop_color = left_stop_color;
        } else if (right_offset_actual_value.abs () < NOB_RADII) {
            selected_stop_color = right_stop_color;
        } else {
            // If neither of the stop colors is anywhere near close, create a new one here.
            var new_stop_color = Lib.Components.Pattern.StopColor () {offset = event_offset, color = left_stop_color.color};
            pattern.colors.add (new_stop_color);
            selected_stop_color = new_stop_color;
        }

        color_changed (selected_stop_color.color);
        pattern_edited (pattern);
        queue_draw ();

        return true;
    }

    // As we used the BUTTON_MOTION_MASK, this method will be called only when mouse is clicked and dragged.
    private bool handle_motion_notify (Gdk.EventMotion event) {
        double event_offset = event.x / width;

        pattern.colors.remove (selected_stop_color);
        selected_stop_color.offset = event_offset;
        pattern.colors.add (selected_stop_color);

        pattern_edited (pattern);
        queue_draw ();

        return true;
    }

    private bool handle_button_release (Gdk.EventButton event) {
        return true;
    }

    private bool is_solid_pattern () {
        if (pattern.colors.size == 1) {
            // Single stop color means solid pattern.
            return true;
        }

        return false;
    }

}

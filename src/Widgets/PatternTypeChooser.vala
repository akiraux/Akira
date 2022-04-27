
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
 * This widget provides a set of options that allow user to select what kind of pattern
 * they want to draw.
 * Selecting ony one of the buttons will change the pattern type (SOLID, LINEAR, RADIAL).
 */
public class Akira.Widgets.PatternTypeChooser : Granite.Widgets.ModeButton {
    private unowned Lib.ViewCanvas canvas;

    // Trigger this signal when the active PatternType changes.
    public signal void pattern_changed (Lib.Components.Pattern pattern);

    private Models.ColorModel model;

    public PatternTypeChooser (Models.ColorModel model, Window window) {
        construct_chooser_widget ();

        this.set_active ((int) model.pattern.type);
        this.model = model;

        // Connect signals.
        this.mode_changed.connect ((window) => {
            var active_mode = (Lib.Components.Pattern.PatternType) this.selected;

            model.active_pattern_type = active_mode;
            pattern_changed (model.pattern);
            
            handle_pattern_changed ();
        });

        this.canvas = window.main_window.main_view_canvas.canvas;

        window.event_bus.translate_gradient_nob_by_delta.connect ((nob, delta) => {
            // This condition checks if this widget is currently open as there can be multiple instances
            // if PatternTypeChooser present. And we don't want all of them to handle this signal.
            if (!is_drawable ()) {
                return;
            }

            model.move_pattern_position_by_delta (nob, delta);
            handle_pattern_changed ();
        });
    }

    public void set_pattern_type (Lib.Components.Pattern.PatternType type) {
        this.set_active ((int) type);
    }

    private void construct_chooser_widget () {
        this.append_text ("Solid");
        this.append_text ("Linear");
        this.append_text ("Radial");
    }

    private void handle_pattern_changed () {
        var active_mode = (Lib.Components.Pattern.PatternType) this.selected;

        var coords = canvas.selection_manager.selection.first_node ().instance.components.center;
        var size = canvas.selection_manager.selection.first_node ().instance.components.size;

        Geometry.Point origin = Geometry.Point (coords.x - size.width / 2.0, coords.y - size.height / 2.0);

        // Update position of nobs in ViewLayerNobs.
        Geometry.Point hidden_pos = Geometry.Point (0, 0);
        var start_nob_pos = Geometry.Point (
            model.pattern.start.x * size.width / 100.0 + origin.x,
            model.pattern.start.y * size.height / 100.0 + origin.y
        );
        var end_nob_pos = Geometry.Point (
            model.pattern.end.x * size.width / 100.0 + origin.x,
            model.pattern.end.y * size.height / 100.0 + origin.y
        );

        canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_START, hidden_pos);
        canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_END, hidden_pos);
        canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_RADIUS_START, hidden_pos);
        canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_RADIUS_END, hidden_pos);

        if (active_mode == Lib.Components.Pattern.PatternType.LINEAR) {
            canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_START, start_nob_pos);
            canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_END, end_nob_pos);
        } else if (active_mode == Lib.Components.Pattern.PatternType.RADIAL) {
            canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_START, start_nob_pos);
            canvas.nob_manager.set_gradient_nob_position (Utils.Nobs.Nob.GRADIENT_END, end_nob_pos);
        }

        canvas.nob_manager.set_layer_flags_from_pattern_type (active_mode);
    }
}

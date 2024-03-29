/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */


/*
 * ItemInsertMode handles item insertion. After the first click, this mode will use static methods
 * in the TransformMode to transform the inserted items.
 *
 * In the future, this mode can be kept alive during multiple clicks when inserting items like polylines.
 */
public class Akira.Lib.Modes.ItemInsertMode : AbstractInteractionMode {
    public weak Lib.ViewCanvas view_canvas { get; construct; }

    private string item_insert_type;

    private Lib.Modes.TransformMode transform_mode;
    private Lib.Modes.PathEditMode path_edit_mode;

    public ItemInsertMode (Lib.ViewCanvas canvas, string item_type) {
        Object (view_canvas: canvas);
        item_insert_type = item_type;
    }

    construct {
        transform_mode = null;
        path_edit_mode = null;
    }

    public override AbstractInteractionMode.ModeType mode_type () {
        return AbstractInteractionMode.ModeType.ITEM_INSERT;
    }

    public override void mode_end () {
        if (transform_mode != null) {
            transform_mode.mode_end ();
        }

        if (path_edit_mode != null) {
            path_edit_mode.mode_end ();
        }
    }

    public override Gdk.CursorType? cursor_type () {
        if (transform_mode != null) {
            return transform_mode.cursor_type ();
        }

        return Gdk.CursorType.CROSSHAIR;
    }

    public override bool key_press_event (Gdk.EventKey event) {
        if (transform_mode != null) {
            return transform_mode.key_press_event (event);
        }

        if (path_edit_mode != null) {
            return path_edit_mode.key_press_event (event);
        }

        return false;
    }

    public override bool key_release_event (Gdk.EventKey event) {
        if (transform_mode != null) {
            return transform_mode.key_press_event (event);
        }
        return false;
     }

    public override bool button_press_event (Gdk.EventButton event) {
        if (transform_mode != null) {
            return transform_mode.button_press_event (event);
        }

        if (path_edit_mode != null) {
            return path_edit_mode.button_press_event (event);
        }

        if (event.button == Gdk.BUTTON_PRIMARY) {
            view_canvas.window.event_bus.create_model_snapshot ("add item");

            bool is_artboard;
            var instance = construct_item (item_insert_type, event.x, event.y, out is_artboard);

            var group_id = Lib.Items.Model.ORIGIN_ID;
            if (!is_artboard) {
                group_id = view_canvas.items_manager.first_group_at (event.x, event.y).id;
            }

            view_canvas.items_manager.add_item_to_group (group_id, instance, false);

            view_canvas.selection_manager.reset_selection ();
            view_canvas.selection_manager.add_to_selection (instance.id);

            // If a path is being inserted, then start the PathEditMode.
            if (item_insert_type == "path") {
                path_edit_mode = new Lib.Modes.PathEditMode (view_canvas, instance);
                path_edit_mode.mode_begin ();
                path_edit_mode.button_press_event (event);
            } else {
                transform_mode = new Lib.Modes.TransformMode (view_canvas, Utils.Nobs.Nob.BOTTOM_LEFT, false);
                transform_mode.mode_begin ();
                transform_mode.button_press_event (event);
            }

            // Defer the print of the layer UI after all items have been created.
            view_canvas.window.main_window.show_added_layers (1);
            view_canvas.selection_manager.selection_modified_external (true);
            return true;
        }

        return false;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (transform_mode != null) {
            transform_mode.button_release_event (event);
            request_deregistration (mode_type ());
        }

        if (path_edit_mode != null) {
            return path_edit_mode.button_release_event (event);
        }

        return true;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (transform_mode != null) {
            return transform_mode.motion_notify_event (event);
        }

        if (path_edit_mode != null) {
            return path_edit_mode.motion_notify_event (event);
        }

        return true;
    }

    public override Object? extra_context () {
        if (transform_mode != null) {
            return transform_mode.extra_context ();
        }

        return null;
    }

    private static Lib.Items.ModelInstance construct_item (string from_type, double x, double y, out bool is_artboard) {
        double center_x = 0.0;
        double center_y = 0.0;
        double width = 1.0;
        double height = 1.0;
        is_artboard = false;

        // We use floor to align to the pixel that is clicked.
        Utils.AffineTransform.geometry_from_top_left (
            GLib.Math.floor (x),
            GLib.Math.floor (y),
            ref center_x,
            ref center_y,
            ref width,
            ref height
        );

        var coordinates = new Lib.Components.Coordinates (center_x, center_y);
        var size = new Lib.Components.Size (width, height, false);

        Lib.Items.ModelInstance new_item = null;
        switch (from_type) {
            case "rectangle":
                new_item = Lib.Items.ModelTypeRect.default_rect (
                    coordinates,
                    size,
                    borders_from_settings (),
                    fills_from_settings ()
                );
                break;

            case "ellipse":
                new_item = Lib.Items.ModelTypeEllipse.default_ellipse (
                    coordinates,
                    size,
                    borders_from_settings (),
                    fills_from_settings ()
                );
                break;

            case "text":
                new_item = Lib.Items.ModelTypeText.default_text (
                    coordinates,
                    size,
                    new Components.Text ("Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.")
                );
                break;

            case "artboard":
                is_artboard = true;
                new_item = Lib.Items.ModelTypeArtboard.default_artboard (
                    coordinates,
                    size
                );
                break;

            case "image":
                break;

            case "path":
                new_item = Lib.Items.ModelTypePath.default_path (
                    coordinates,
                    borders_from_settings (),
                    null
                );

                var test_path = new Geometry.PathSegment[1];
                test_path[0] = Geometry.PathSegment.line (Geometry.Point (0, 0));

                new_item.components.path = new Lib.Components.Path.from_points (test_path, false);
                break;
        }

        if (new_item == null) {
            new_item = Lib.Items.ModelTypeRect.default_rect (
                coordinates,
                size,
                borders_from_settings (),
                fills_from_settings ()
            );
        }

        return new_item;
    }

    private static Lib.Components.Fills fills_from_settings () {
        var fill_rgba = Gdk.RGBA ();
        fill_rgba.parse (settings.fill_color);
        return new Lib.Components.Fills.with_color (Lib.Components.Color.from_rgba (fill_rgba));
    }

    private static Lib.Components.Borders? borders_from_settings () {
        if (!settings.set_border) {
            return null;
        }

        var border_rgba = Gdk.RGBA ();
        border_rgba.parse (settings.border_color);
        return new Lib.Components.Borders.single_color (
            Lib.Components.Color.from_rgba (border_rgba),
            settings.border_size
        );
    }
}

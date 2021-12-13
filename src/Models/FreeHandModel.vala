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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

public class Akira.Models.FreeHandModel : Object {
    public Lib.Items.ModelInstance instance { get; construct; }
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private ViewLayers.ViewLayerPath path_layer;

    // These store a copy of points and commands in the path.
    private Lib.Modes.PathEditMode.Type[] commands;
    private Geometry.Point[] points;

    public Geometry.Point first_point;

    // This stores the raw points taken directly from input events.
    // These points are further processed to fit a curve.
    private Geometry.Point[] raw_points;

    public FreeHandModel (Lib.Items.ModelInstance instance, Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            instance: instance
        );

        first_point = Geometry.Point (-1, -1);

        commands = instance.components.path.commands;
        points = instance.components.path.data;

        // Layer to show when editing paths.
        path_layer = new ViewLayers.ViewLayerPath ();
        path_layer.add_to_canvas (ViewLayers.ViewLayer.PATH_LAYER_ID, view_canvas);

        update_view ();
    }

    /*
     * Recalculates the extents and updates the ViewLayerPath
     */
    private void update_view () {
        var points = instance.components.path.data;

        var coordinates = view_canvas.selection_manager.selection.coordinates ();

        Geometry.Rectangle extents = Geometry.Rectangle.empty ();
        extents.left = coordinates.center_x - coordinates.width / 2.0;
        extents.right = coordinates.center_x + coordinates.width / 2.0;
        extents.top = coordinates.center_y - coordinates.height / 2.0;
        extents.bottom = coordinates.center_y + coordinates.height / 2.0;

        PathDataModel path_data = PathDataModel ();
        path_data.points = points;
        path_data.commands = commands;
        path_data.live_pts = raw_points;
        path_data.length = raw_points.length;
        path_data.extents = extents;
        path_data.rot_angle = instance.components.transform.rotation;

        path_data.live_extents = get_extents_using_live_pts (extents);

        path_layer.update_path_data (path_data);
    }

    private Geometry.Rectangle get_extents_using_live_pts (Geometry.Rectangle extents) {
        var live_extents = Geometry.Rectangle.empty ();

        live_extents.left = extents.left;
        live_extents.right = extents.right;
        live_extents.top = extents.top;
        live_extents.bottom = extents.bottom;

        for (int i = 0; i < raw_points.length; ++i) {
            var temp = raw_points[i];
            temp.x = temp.x - first_point.x + extents.left;
            temp.y = temp.y - first_point.y + extents.top;

            if (temp.x < extents.left) {
                live_extents.left = temp.x;
            }
            if (temp.x > extents.right) {
                live_extents.right = temp.x;
            }
            if (temp.y < extents.top) {
                live_extents.top = temp.y;
            }
            if (temp.y > extents.bottom) {
                live_extents.bottom = temp.y;
            }
        }

        return live_extents;
    }
}

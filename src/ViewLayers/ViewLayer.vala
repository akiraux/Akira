/**
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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

public class Akira.ViewLayers.ViewLayer : Object {
    // Higher numbers are higher on the stack
    public const string VSNAPS_LAYER_ID = "99_vsnaps_layer";
    public const string HSNAPS_LAYER_ID = "99_hsnaps_layer";
    public const string GRID_LAYER_ID = "88_grid_layer";
    public const string HOVER_LAYER_ID = "77_hover_layer";
    public const string NOBS_LAYER_ID = "66_nobs_layer";


    private bool _is_visible { get; set; default = false; }
    private BaseCanvas? _canvas { get; set; default = null; }

    public BaseCanvas? canvas { get { return _canvas; } }
    public bool is_visible { get { return _is_visible; } }

    public void add_to_canvas (string layer_id, BaseCanvas canvas) {
        _canvas = canvas;
        _canvas.add_viewlayer_overlay (layer_id, this);
    }

    public void set_visible (bool visible) {
        if (_is_visible == visible) {
            return;
        }

        _is_visible = visible;

        update ();
    }

    public virtual void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {}
    public virtual void update () {}

}

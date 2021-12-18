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
    public class Mask {
        private ViewLayer view_layer;

        // Scoped mask implementation to hide masks temporarily during a scope (RAII)
        public Mask (ViewLayer layer) {
            view_layer = layer;
            if (view_layer != null) {
                view_layer.add_mask ();
            }
        }

        ~Mask () {
            if (view_layer != null) {
                view_layer.remove_mask ();
            }
        }
    }

    // Higher numbers are higher on the stack
    public const string VSNAPS_LAYER_ID = "99_vsnaps_layer";
    public const string HSNAPS_LAYER_ID = "99_hsnaps_layer";
    public const string GRID_LAYER_ID = "88_grid_layer";
    public const string HOVER_LAYER_ID = "77_hover_layer";
    // at a time, only one of nobs and path layer will be shown.
    // so they have equal priority
    public const string NOBS_LAYER_ID = "66_nobs_layer";
    public const string PATH_LAYER_ID = "66_path_layer";


    private bool p_is_visible { get; set; default = false; }
    private BaseCanvas? p_canvas { get; set; default = null; }
    private int p_mask_counter { get; set; default = 0; }

    public BaseCanvas? canvas { get { return p_canvas; } }
    public bool is_visible { get { return p_is_visible; } }
    public bool is_masked { get { return p_mask_counter > 0; } }


    public void add_to_canvas (string layer_id, BaseCanvas canvas) {
        p_canvas = canvas;
        p_canvas.add_viewlayer_overlay (layer_id, this);
    }

    public void set_visible (bool visible) {
        if (p_is_visible == visible) {
            return;
        }

        p_is_visible = visible;

        update ();
    }

    public void add_mask () {
        p_mask_counter++;
        if (is_visible && is_masked) {
            update ();
        }
    }

    public void remove_mask () {
        p_mask_counter = int.min (p_mask_counter - 1, 0);

        if (is_visible && !is_masked) {
            update ();
        }
    }

    public virtual void draw_layer (Cairo.Context context, Geometry.Rectangle target_bounds, double scale) {}
    public virtual void update () {}

}

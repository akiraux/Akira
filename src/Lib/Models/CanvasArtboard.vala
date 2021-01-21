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
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Lib.Models.CanvasArtboard : Goo.CanvasItemSimple, Goo.CanvasItem, Models.CanvasItem {
    private const double LABEL_FONT_SIZE = 15.0;
    private const double LABEL_BOTTOM_PADDING = 8.0;

    // Identifiers.
    public Models.CanvasItemType item_type { get; set; }
    public string id { get; set; }
    private string _name;
    public string name {
        get {
            return _name;
        }
        set {
            _name = value;
            changed (false);
        }
    }

    // Transform Panel attributes.
    public double opacity { get; set; }
    public double rotation { get; set; }

    // Fill Panel attributes.
    public bool has_fill { get; set; default = true; }
    public int fill_alpha { get; set; }
    public Gdk.RGBA color { get; set; }
    public string color_string { get; set; }
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = true; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
    public string border_color_string { get; set; }
    public int stroke_alpha { get; set; }
    public bool hidden_border { get; set; }

    // Style Panel attributes.
    public bool size_locked { get; set; }
    public double size_ratio { get; set; }
    public bool flipped_h { get; set; }
    public bool flipped_v { get; set; }
    public bool show_border_radius_panel { get; set; }
    public bool show_fill_panel { get; set; }
    public bool show_border_panel { get; set; }

    // Layers panel attributes.
    public bool selected { get; set; }
    public bool locked { get; set; }
    public string layer_icon { get; set; default = null; }
    public int z_index { get; set; }

    // Shape's unique identifiers.
    public bool is_radius_uniform { get; set; }
    public bool is_radius_autoscale { get; set; }

    // CanvasItemSimple basic properties
    public double x { get; set; }
    public double y { get; set; }
    public double width { get; set; }
    public double height { get; set; }
    public Goo.CanvasItem parent_item { get; set; }

    // Artboard related properties
    private Cairo.TextExtents label_extents;
    public Akira.Models.ListModel<Models.CanvasItem> items;
    public new Akira.Lib.Canvas canvas { get; set; }
    public Models.CanvasArtboard? artboard { get; set; }
    public Managers.GhostBoundsManager bounds_manager { get; set; }

    public double relative_x { get; set; }
    public double relative_y { get; set; }

    // Knows if an item was created or loaded for ordering purpose.
    public bool loaded { get; set; default = false; }

    public CanvasArtboard (double _x = 0, double _y = 0, Goo.CanvasItem? _parent = null) {
        parent_item = _parent;

        canvas = parent_item.get_canvas () as Akira.Lib.Canvas;
        parent_item.add_child (this, -1);

        // Artboards can't be nested.
        artboard = null;

        item_type = Models.CanvasItemType.ARTBOARD;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        width = 1;
        height = 1;
        x = 0;
        y = 0;

        show_border_radius_panel = false;
        show_fill_panel = true;
        show_border_panel = false;
        is_radius_uniform = true;
        is_radius_autoscale = false;

        var fill_rgba = Gdk.RGBA ();
        fill_rgba.parse ("rgba (255, 255, 255, 1)");
        color = fill_rgba;

        set_transform (Cairo.Matrix.identity ());

        // Keep the item always in the origin
        // move the entire coordinate system every time.
        translate (_x, _y);

        // Get artboard name pixel extent.
        get_label_extent ();

        // Init items list.
        items = new Akira.Models.ListModel<Models.CanvasItem> ();

        canvas.window.event_bus.zoom.connect (trigger_change);
        canvas.window.event_bus.change_theme.connect (trigger_change);
    }

    public uint get_items_length () {
        return items.get_n_items ();
    }

    public void remove_item (Models.CanvasItem item) {
        item.disconnect_from_artboard ();
        items.remove_item.begin (item);
        item.artboard = null;
        changed (false);
    }

    public bool is_inside (double x, double y) {
        return x <= bounds.x2
            && x >= bounds.x1
            && y >= bounds.y1
            && y <= bounds.y2;
    }

    public bool dropped_inside (Models.CanvasItem item) {
        return item.bounds_manager.x1 < bounds.x2
            && item.bounds_manager.x2 > bounds.x1
            && item.bounds_manager.y1 < bounds.y2
            && item.bounds_manager.y2 > bounds.y1 + get_label_height ();
    }

    public void add_child (Goo.CanvasItem item, int position = -1) {
        var canvas_item = item as Models.CanvasItem;

        if (canvas_item.id == null) {
            return;
        }

        items.add_item.begin (canvas_item, ((Models.CanvasItem) item).loaded);
        item.set_parent (this);

        request_update ();
    }

    private void get_label_extent () {
        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 290, 256);
        Cairo.Context cr = new Cairo.Context (surface);

        cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        cr.set_font_size (LABEL_FONT_SIZE / ((Lib.Canvas) canvas).current_scale);
        cr.text_extents (id, out label_extents);
    }

    public override void simple_update (Cairo.Context cr) {
        bounds.x1 = x;
        bounds.y1 = y - get_label_height ();
        bounds.x2 = x + width;
        bounds.y2 = y + height;
    }

    /*
     * Paint the artbaord and all its child elements. This method is not called
     * if the artboard is outside the visible canvas area. Goocanvas does this automatically.
     */
    public override void simple_paint (Cairo.Context cr, Goo.CanvasBounds area_bounds) {
        cr.set_source_rgba (0, 0, 0, 0.6);

        if (settings.dark_theme) {
            cr.set_source_rgba (1, 1, 1, 0.6);
        }

        cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        cr.set_font_size (LABEL_FONT_SIZE / ((Lib.Canvas) canvas).current_scale);
        cr.move_to (x, y - (LABEL_BOTTOM_PADDING / ((Lib.Canvas) canvas).current_scale));
        cr.show_text (name != null ? name : id);

        // Mask items outside Artboard.
        cr.rectangle (x, y, width, height);
        cr.clip ();

        cr.rectangle (x, y, width, height);

        // If the user hides or delete the fill color, set the opacity to 0.
        var alpha = hidden_fill || !has_fill ? 0 : color.alpha;
        cr.set_source_rgba (color.red, color.green, color.blue, alpha);
        cr.fill ();

        // Interrupt if no item is present in the artboard.
        if (items.get_n_items () == 0) {
            return;
        }

        var items_length = items.get_n_items ();

        // Painting items in reversed order in order to
        // print last item inserted (top of the stack) on top
        // of the items inserted before.
        for (var i = 0; i < items_length; i++) {
            var item = items[items_length - 1 - i];

            var canvas_item = item as Goo.CanvasItemSimple;
            if (canvas_item == null || item.visibility != Goo.CanvasItemVisibility.VISIBLE) {
                continue;
            }

            cr.save ();
            cr.transform (item.compute_transform (Cairo.Matrix.identity ()));

            // TEMPORARILY REMOVED.
            // This won't work until the official goocanvas PPA gets the fixed VAPI.
            // Clip the item if it comes with a path mask.
            // if (canvas_item.simple_data.clip_path_commands != null) {
            //     Goo.Canvas.create_path (canvas_item.simple_data.clip_path_commands, cr);
            //     Cairo.FillRule fill_rule =
            //         canvas_item.simple_data.clip_fill_rule == 0
            //         ? Cairo.FillRule.EVEN_ODD
            //         : Cairo.FillRule.WINDING;

            //     cr.set_fill_rule (fill_rule);
            //     cr.clip ();
            // }

            canvas_item.simple_paint (cr, bounds);
            cr.restore ();

            item.bounds_manager.update ();
        }
    }

    public override bool simple_is_item_at (double x, double y, Cairo.Context cr, bool is_pointer_event) {
        // To select an Artboard you should put the arrow over the Artboard label.
        return y < 0
            && y > - get_label_height ()
            && x > 0
            && x < label_extents.width;
    }

    public double get_label_height () {
        return label_extents.height + LABEL_BOTTOM_PADDING;
    }

    public unowned GLib.List<Goo.CanvasItem> get_items_at (
        double x,
        double y,
        Cairo.Context cr,
        bool is_pointer_event,
        bool parent_is_visible,
        GLib.List<Goo.CanvasItem> found_items
    ) {
        // Check if the item needs a paint update.
        if (need_update == 1) {
            ensure_updated ();
        }

        // Skip the item if the point isn't in the item's bounds.
        if (bounds.x1 > x || bounds.x2 < x || bounds.y1 > y || bounds.y2 < y) {
            return found_items;
        }

        // Skip the item if is not visible or locked.
        if (visibility != Goo.CanvasItemVisibility.VISIBLE || locked == true) {
            return found_items;
        }

        var artboard_x = x;
        var artboard_y = y;

        canvas.convert_to_item_space (this, ref artboard_x, ref artboard_y);

        if (simple_is_item_at (artboard_x, artboard_y, cr, is_pointer_event)) {
            found_items.append (this);
        }

        foreach (Lib.Models.CanvasItem item in items) {
            if (item.simple_is_item_at (x, y, cr, is_pointer_event)) {
                found_items.append (item);
            }
        }

        return found_items;
    }

    /**
     * Programmatically trigger the simple_paint() method when the UI requires an update.
     */
    public void trigger_change () {
        // Force the redraw of the font size.
        changed (false);
    }
}

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
 *
 * Note: This is transcribed to goocanvas. Not sure how copyright
 * works in that case. But all credit to the original authors of
 * goocanvas.c
 */

/*
 * Group optimized for Akira.
 */
public class Akira.ViewLayers.BaseCanvas : Gtk.Widget , Gtk.Scrollable {
    private const double DEFAULT_WIDTH = 1000.0;
    private const double DEFAULT_HEIGHT = 1000.0;

    private int window_x = 0;
    private int window_y = 0;
    private bool automatic_bounds = false;
    private bool bounds_from_origin = true;
    private bool clear_background = true;

    private int freeze_count = 0;
    private bool need_update = true;
    private bool need_entire_subtree_update_ = true;
    private bool before_initial_draw = true;
    private bool needs_reconfigure = false;
    private Geometry.Rectangle bounds = Geometry.Rectangle.with_coordinates (0, 0, DEFAULT_WIDTH, DEFAULT_HEIGHT);

    public bool pause_redraw = false;

    // The main window that gets scrolled around
    private Gdk.Window canvas_window;

    private unowned Lib2.Items.Model? model_to_render = null;

    private double _scale { get; set; default = 1.0; }
    private double _resolution_x { get; set; default = 96.0; }
    private double _resolution_y { get; set; default = 96.0; }
    private Gtk.Adjustment _hadjustment { get; set; default = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0); }
    private Gtk.Adjustment _vadjustment { get; set; default = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0); }
    private Gtk.ScrollablePolicy _hscroll_policy { get; set; }
    private Gtk.ScrollablePolicy _vscroll_policy { get; set; }

    private Gee.TreeMap<string, ViewLayers.ViewLayer> overlays;

    public double scale {
        get { return _scale; }
        set { this.internal_set_scale (value); }
    }

    public double x1 {
        get { return bounds.left; }
        set {
            bounds.left = value;
            needs_reconfigure = true;
            reconfigure (false);
            queue_draw ();
        }
    }
    public double y1 {
        get { return bounds.top; }
        set {
            bounds.top = value;
            needs_reconfigure = true;
            reconfigure (false);
            queue_draw ();
        }
    }
    public double x2 {
        get { return bounds.right; }
        set {
            bounds.right = value;
            needs_reconfigure = true;
            reconfigure (false);
            queue_draw ();
        }
    }
    public double y2 {
        get { return bounds.bottom; }
        set {
            bounds.bottom = value;
            needs_reconfigure = true;
            reconfigure (false);
            queue_draw ();
        }
    }

    public double resolution_x {
        get { return _resolution_x; }
        set { _resolution_x = value; needs_reconfigure = true; }
    }
    public double resolution_y {
        get { return _resolution_y; }
        set { _resolution_y = value; needs_reconfigure = true; }
    }

    public Gtk.Adjustment hadjustment {
        get { return _hadjustment; }
        set construct { internal_set_hadjustment (value); }
    }
    public Gtk.Adjustment vadjustment {
        get { return _vadjustment; }
        set construct { internal_set_vadjustment (value); }
    }

    public Gtk.ScrollablePolicy hscroll_policy {
        get { return _hscroll_policy; }
        set { _hscroll_policy = value; queue_resize (); }
    }

    public Gtk.ScrollablePolicy vscroll_policy {
        get { return _vscroll_policy; }
        set { _vscroll_policy = value; queue_resize (); }
    }

    BaseCanvas () {
        hadjustment = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        vadjustment = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    }

    public void set_model_to_render (Lib2.Items.Model model) {
        model_to_render = model;
        request_redraw (bounds);
        queue_draw ();
    }

    public void add_viewlayer_overlay (string id, ViewLayers.ViewLayer layer) {
        if (overlays == null) {
            overlays = new Gee.TreeMap<string, ViewLayers.ViewLayer> ();
        }
        overlays[id] = layer;
        if (layer.is_visible) {
            layer.update ();
        }
    }

    public bool get_border (out Gtk.Border border) {
        border = Gtk.Border ();
        return true;
    }

    public override void realize () {
        set_realized (true);
        Gtk.Allocation allocation;
        get_allocation (out allocation);

        var attributes = Gdk.WindowAttr ();
        attributes.window_type = Gdk.WindowType.CHILD;
        attributes.x = allocation.x;
        attributes.y = allocation.y;
        attributes.width = allocation.width;
        attributes.height = allocation.height;
        attributes.wclass = Gdk.WindowWindowClass.INPUT_OUTPUT;
        attributes.visual = get_visual ();
        attributes.event_mask = Gdk.EventMask.VISIBILITY_NOTIFY_MASK;
        int attributes_mask = Gdk.WindowAttributesType.X | Gdk.WindowAttributesType.Y | Gdk.WindowAttributesType.VISUAL;

        var window = new Gdk.Window (get_parent_window (), attributes, (Gdk.WindowAttributesType)attributes_mask);
        set_window (window);
        window.set_user_data (this);

        int width_pixels = (int)((bounds.right - bounds.left) * scale) + 1;
        int height_pixels = (int)((bounds.bottom - bounds.top) * scale) + 1;
        attributes.x = (hadjustment == null) ? 0 : (int)hadjustment.get_value ();
        attributes.y = (vadjustment == null) ? 0 : (int)vadjustment.get_value ();
        attributes.width = int.max (width_pixels, allocation.width);
        attributes.height = int.max (height_pixels, allocation.height);
        attributes.event_mask =
            Gdk.EventMask.EXPOSURE_MASK
            | Gdk.EventMask.SCROLL_MASK
            | Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.POINTER_MOTION_HINT_MASK
            | Gdk.EventMask.KEY_PRESS_MASK
            | Gdk.EventMask.KEY_RELEASE_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK
            | Gdk.EventMask.FOCUS_CHANGE_MASK
            | get_events ();

        window_x = attributes.x;
        window_y = attributes.y;

        canvas_window = new Gdk.Window (window, attributes, (Gdk.WindowAttributesType)attributes_mask);
        canvas_window.set_user_data (this);
    }

    public override void map () {
        base.map ();
        canvas_window.show ();
        get_window ().show ();
    }

    public override void unrealize () {
        canvas_window.set_user_data (null);
        base.unrealize ();
    }

    public override void get_preferred_height (out int minimum_height, out int natural_height) {
        minimum_height = 0;
        natural_height = 0;
    }

    public override void get_preferred_width (out int minimum_width, out int natural_width) {
        minimum_width = 0;
        natural_width = 0;
    }

    public override void size_allocate (Gtk.Allocation allocation) {
        set_allocation (allocation);

        if (get_realized ()) {
            get_window ().move_resize (allocation.x, allocation.y, allocation.width, allocation.height);
            //tmp_canvas.move_resize (allocation.x, allocation.y, allocation.width, allocation.height);
        }

        reconfigure (true);
    }

    public override bool scroll_event (Gdk.EventScroll event) {
        Gtk.Adjustment adj;
        if (event.direction == Gdk.ScrollDirection.UP || event.direction == Gdk.ScrollDirection.DOWN) {
            adj = vadjustment;
        } else {
            adj = hadjustment;
        }

        var delta = GLib.Math.pow (adj.get_page_size (), 2.0 / 3.0);

        if (event.direction == Gdk.ScrollDirection.UP || event.direction == Gdk.ScrollDirection.LEFT) {
            delta = -delta;
        }

        var maxv = adj.get_upper () - adj.get_page_size ();
        var new_value = Utils.GeometryMath.clamp (adj.get_value () + delta, adj.get_lower (), maxv);

        adj.set_value (new_value);
        return true;
    }

    public void convert_to_pixels (ref double x, ref double y) {
        x = (x - bounds.left) * scale;
        y = (y - bounds.top) * scale;
    }

    public void convert_from_pixels (ref double x, ref double y) {
        x = x / scale + bounds.left;
        y = y / scale + bounds.top;
    }


    public void convert_from_window_pixels (ref double x, ref double y) {
        x -= window_x;
        y -= window_y;
        convert_from_pixels (ref x, ref y);
    }

    public void setup_cairo_context (Cairo.Context* context) {
        context->set_antialias (Cairo.Antialias.GRAY);
        context->set_line_width (0.0);
    }

    public Cairo.Context create_cairo_context () {
        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 1, 1);
        var context = new Cairo.Context (surface);
        setup_cairo_context (context);
        return context;
    }

    public void set_bounds (Geometry.Rectangle new_bounds) {
        bounds = new_bounds;
        reconfigure (false);
        queue_draw ();
    }

    /*
     * Get viewport bounds in user coordinates.
     */
    public Geometry.Rectangle viewport_bounds_in_user () {
        var r = Geometry.Rectangle.empty ();

        convert_from_window_pixels (ref r.left, ref r.top);

        Gtk.Allocation allocation;
        get_allocation (out allocation);

        double w = allocation.width;
        double h = allocation.height;


        convert_from_pixels (ref w, ref h);

        r.right = r.left + w;
        r.bottom = r.top + h;
        return r;
    }

    public Geometry.Rectangle get_bounds () {
        return bounds;
    }

    public void internal_set_scale (double new_scale) {
        var x = hadjustment.get_value () + hadjustment.get_page_size () / 2;
        var y = vadjustment.get_value () + vadjustment.get_page_size () / 2;

        freeze_count++;

        _scale = new_scale;

        reconfigure (false);

        x -= hadjustment.get_page_size () / scale / 2;
        y -= vadjustment.get_page_size () / scale / 2;

        scroll_to (x, y);

        freeze_count--;
        adjustment_value_changed ();
        queue_draw ();
    }

    public void scroll_to (double top, double left) {
        double x = left;
        double y = top;

        var xmax = hadjustment.get_upper () - hadjustment.get_page_size ();
        var ymax = vadjustment.get_upper () - vadjustment.get_page_size ();
        x = Utils.GeometryMath.clamp (x, hadjustment.get_lower (), xmax);
        y = Utils.GeometryMath.clamp (y, vadjustment.get_lower (), ymax);

        freeze_count++;
        hadjustment.set_value (x);
        vadjustment.set_value (y);
        freeze_count--;

        adjustment_value_changed ();
    }

    public void reconfigure (bool redraw_if_needed) {
        /* Make sure the bounds are sane. */
        if (bounds.right < bounds.left) {
            bounds.right = bounds.left;
        }
        if (bounds.bottom < bounds.top) {
            bounds.bottom = bounds.top;
        }

        /* This is the natural size of the canvas window in pixels, rounded up to
            the next pixel. */
        int width_pixels = (int)((bounds.right - bounds.left) * scale) + 1;
        int height_pixels = (int)((bounds.bottom - bounds.top) * scale) + 1;

        Gtk.Allocation allocation;
        get_allocation (out allocation);
        var window_width = int.max (width_pixels, allocation.width);
        var window_height = int.max (height_pixels, allocation.height);

        freeze_count++;

        int wx = 0;
        int wy = 0;

        if (hadjustment != null) {
            configure_hadjustment (window_width);
            wx = (int)hadjustment.get_value ();
        }

        if (vadjustment != null) {
            configure_vadjustment (window_height);
            wy = (int)vadjustment.get_value ();
        }

        freeze_count--;

        if (get_realized ()) {
            canvas_window.move_resize (wx, wy, window_width, window_height);
        }
    }

    public void internal_set_hadjustment (Gtk.Adjustment? new_hadj) {
     if (new_hadj != null && hadjustment == new_hadj) {
            return;
        }

        if (hadjustment != null) {
            hadjustment.value_changed.disconnect (adjustment_value_changed);
        }

        var newadj = new_hadj;
        if (newadj == null) {
            newadj = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        }

        newadj.value_changed.connect (adjustment_value_changed);
        reconfigure (true);
        _hadjustment = newadj;
    }

    public void internal_set_vadjustment (Gtk.Adjustment? new_vadj) {

        if (new_vadj != null && _vadjustment == new_vadj) {
            return;
        }

        if (vadjustment != null) {
            vadjustment.value_changed.disconnect (adjustment_value_changed);
        }

        var newadj = new_vadj;
        if (newadj == null) {
            newadj = new Gtk.Adjustment (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        }

        newadj.value_changed.connect (adjustment_value_changed);
        reconfigure (true);
        _vadjustment = newadj;
    }

    private void configure_hadjustment (int window_width) {
        var value = hadjustment.get_value ();
        var lower = hadjustment.get_lower ();
        var upper = hadjustment.get_upper ();
        var step_inc = hadjustment.get_step_increment ();
        var page_inc = hadjustment.get_page_increment ();
        var page_size = hadjustment.get_page_size ();

        bool configure = false;

        if (upper != window_width) {
            upper = window_width;
            configure = true;
        }

        Gtk.Allocation allocation;
        get_allocation (out allocation);

        if (page_size != allocation.width) {
            page_size = allocation.width;
            page_inc = page_size * 0.9;
            step_inc = page_size * 0.1;
            configure = true;
        }

        var max_value = double.max (0.0, upper - page_size);
        if (value > max_value) {
            value = max_value;
            configure = true;
        }

        if (configure) {
            hadjustment.configure (value, lower, upper, step_inc, page_inc, page_size);
        }
    }

    private void configure_vadjustment (int window_height) {
        bool configure = false;
        var value = vadjustment.get_value ();
        var lower = vadjustment.get_lower ();
        var upper = vadjustment.get_upper ();
        var step_inc = vadjustment.get_step_increment ();
        var page_inc = vadjustment.get_page_increment ();
        var page_size = vadjustment.get_page_size ();

        if (upper != window_height) {
            upper = window_height;
            configure = true;
        }

        Gtk.Allocation allocation;
        get_allocation (out allocation);

        if (page_size != allocation.height) {
            page_size = allocation.height;
            page_inc = page_size * 0.9;
            step_inc = page_size * 0.1;
            configure = true;
        }

        var max_value = double.max (0.0, upper - page_size);
        if (value > max_value) {
            value = max_value;
            configure = true;
        }

        if (configure) {
            vadjustment.configure (value, lower, upper, step_inc, page_inc, page_size);
        }
    }

    public void adjustment_value_changed () {
        if (freeze_count == 0 && get_realized ()) {
            int new_window_x = - (int)hadjustment.get_value ();
            int new_window_y = - (int)vadjustment.get_value ();

            window_x = new_window_x;
            window_y = new_window_y;

            canvas_window.move (new_window_x, new_window_y);
        }
    }

    /*
     * Request a redraw of bounds `b` in the canvas coordinate space.
     */
    public void request_redraw (Geometry.Rectangle b) {
        if (before_initial_draw) {
            return;
        }

        if (!is_drawable () || b.left == b.right) {
            return;
        }

        var rect = Gdk.Rectangle ();

        // Extra one is for possible antialiasing requirements
        rect.x = (int) ((b.left - bounds.left) * scale - 1.0);
        rect.y = (int) ((b.top - bounds.top) * scale - 1.0);

        // Offset by one for same reasons. Keeping Goocanvas tradition and an extra 1 for luck.
        rect.width = (int) ((b.right - bounds.left) * scale - rect.x + 2 + 1);
        rect.height = (int) ((b.bottom - bounds.top) * scale - rect.y + 2 + 1);

        canvas_window.invalidate_rect (rect, false);
    }

    public override bool draw (Cairo.Context context) {
        if (!Gtk.cairo_should_draw_window (context, canvas_window)) {
            return false;
        }

        var clip_bounds = Geometry.Rectangle ();
        context.clip_extents (out clip_bounds.left, out clip_bounds.top, out clip_bounds.right, out clip_bounds.bottom);

        context.save ();

        setup_cairo_context (context);

        if (clear_background) {
            Gtk.Allocation allocation;
            get_allocation (out allocation);
            unowned var style_context = get_style_context ();
            style_context.render_background (context, 0, 0, allocation.width, allocation.height);
            context.set_source_rgb (0, 0, 0);
        }

        var to_paint = clip_bounds;

        convert_from_window_pixels (ref to_paint.left, ref to_paint.top);
        convert_from_window_pixels (ref to_paint.right, ref to_paint.bottom);

        context.translate (window_x, window_y);

        context.scale (scale, scale);

        // translate so that the top-left of the canvas becomes 0,0
        context.translate (-bounds.left, -bounds.top);

        // clip to the canvas bounds, if necessary. only necessary if model bounds are
        // outside the canvas bounds, and the canvas bounds are less than the area being painted.
        // var model_bounds = Geometry.Rectangle (); // TODO
        // double top = 0;
        // double left = 0;
        // double bottom = 0;
        // double right = 0;
        // if (
        //     (model_bounds.left < bounds.left && bounds.left > to_paint.left)
        //     || (model_bounds.right > bounds.right && bounds.right < to_paint.right)
        //     || (model_bounds.top < bounds.top && bounds.top > to_paint.top)
        //     || (model_bounds.bottom > bounds.bottom && bounds.bottom < to_paint.bottom)
        // ) {
        //     left = double.max (bounds.left, to_paint.left);
        //     top = double.max (bounds.top, to_paint.top);
        //     bottom = double.min (bounds.bottom, to_paint.bottom);
        //     right = double.min (bounds.right, to_paint.right);

        //     context.new_path ();
        //     context.move_to (left, top);
        //     context.line_to (right, top);
        //     context.line_to (right, bottom);
        //     context.line_to (left, bottom);
        //     context.close_path ();
        //     context.clip ();
        // }

        draw_model (context, to_paint);

        if (overlays != null) {
            foreach (var overlay in overlays.values) {
                overlay.draw_layer (context, to_paint, scale);
            }
        }

        context.restore ();

        before_initial_draw = false;
        return false;
    }

    public void draw_model (Cairo.Context context, Geometry.Rectangle bounds) {
        if (model_to_render == null) {
            return;
        }

        var origin = model_to_render.node_from_id (Lib2.Items.Model.ORIGIN_ID);
        if (origin == null || origin.children == null) {
            return;
        }

        foreach (unowned var root in origin.children.data) {
            draw_model_node (root, context, bounds);
        }
    }

    public void draw_model_node (Lib2.Items.ModelNode node, Cairo.Context context, Geometry.Rectangle bounds) {
        if (node.instance.drawable != null) {
            node.instance.drawable.paint (context, bounds, scale);
        }

        if (node.children != null) {
            foreach (unowned var child in node.children.data) {
                draw_model_node (child, context, bounds);
            }
        }
    }

    /*
     * Render target bounds to a cairo context.
     */
    public void render (Cairo.Context context, Geometry.Rectangle bounds, double scale) {
        // TODO
    }
}

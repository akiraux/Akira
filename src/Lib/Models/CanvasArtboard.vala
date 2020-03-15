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
 */

public class Akira.Lib.Models.CanvasArtboard : Goo.CanvasItemSimple, Goo.CanvasItem, Models.CanvasItem {
    private const double LABEL_FONT_SIZE = 14.0;
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
    public bool hidden_fill { get; set; }

    // Border Panel attributes.
    public bool has_border { get; set; default = true; }
    public int border_size { get; set; }
    public Gdk.RGBA border_color { get; set; }
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
    private double label_height;
    private List<Models.CanvasItem> items;
    public new Akira.Lib.Canvas canvas { get; set; }
    public Models.CanvasArtboard? artboard { get; set; }
    public double relative_x { get; set; }
    public double relative_y { get; set; }

    public double initial_relative_x { get; set; }
    public double initial_relative_y { get; set; }

    public CanvasArtboard (
        double _x = 0,
        double _y = 0,
        Goo.CanvasItem? _parent = null
        ) {
        parent_item = _parent;

        canvas = parent_item.get_canvas () as Akira.Lib.Canvas;
        parent_item.add_child (this, -1);

        // Artboards can't be nested
        artboard = null;

        item_type = Models.CanvasItemType.ARTBOARD;
        id = Models.CanvasItem.create_item_id (this);
        Models.CanvasItem.init_item (this);

        width = 1;
        height = 1;
        x = 0;
        y = 0;

        show_border_radius_panel = false;
        show_fill_panel = false;
        show_border_panel = false;
        is_radius_uniform = true;
        is_radius_autoscale = false;

        set_transform (Cairo.Matrix.identity ());

        // Keep the item always in the origin
        // move the entire coordinate system every time
        translate (_x, _y);

        // Get colors from settings
        // TODO

        // Get artboard name pixel extent
        get_label_extent ();

        // Init items list
        items = new List<Models.CanvasItem> ();
    }

    public uint get_items_length () {
        return this.items.length ();
    }

    public void move_items (double delta_x, double delta_y) {
        foreach (var item in items) {
            item.translate (delta_x, delta_y);
        }
    }

    public void remove_item (Models.CanvasItem item) {
      items.remove (item);
    }

    public void remove_all_items () {
      Models.CanvasItem item;

      while (items != null) {
        // Get the new head of the list
        item = items.nth_data (0);

        canvas.window.event_bus.request_delete_item (item);
      }

      items = new List<Models.CanvasItem> ();
    }

    public bool is_inside (double x, double y) {
        return x <= this.bounds.x2
            && x >= this.bounds.x1
            && y >= this.bounds.y1
            && y <= this.bounds.y2;
    }

    public void add_child (Goo.CanvasItem item, int position = -1) {
        var canvas_item = item as Models.CanvasItem;

        if (canvas_item.id == null) {
            return;
        }

        this.items.append (canvas_item);
        item.set_parent (this);
        request_update ();
    }

    private void get_label_extent () {
        Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 290, 256);
        Cairo.Context cr = new Cairo.Context (surface);

        Cairo.TextExtents extents;
        cr.select_font_face (
            "Sans",
            Cairo.FontSlant.NORMAL,
            Cairo.FontWeight.NORMAL
            );
        cr.set_font_size (LABEL_FONT_SIZE);

        cr.text_extents (id, out extents);

        label_height = extents.height;
    }

    public override void simple_update (Cairo.Context cr) {
        this.bounds.x1 = x;
        this.bounds.y1 = y - label_height - LABEL_BOTTOM_PADDING;
        this.bounds.x2 = x + width;
        this.bounds.y2 = y + height;
    }

    public override void simple_paint (Cairo.Context cr, Goo.CanvasBounds bounds) {
        cr.set_source_rgba (0.3, 0.3, 0.3, 1);

        cr.select_font_face (
            "Sans",
            Cairo.FontSlant.NORMAL,
            Cairo.FontWeight.NORMAL
            );
        cr.set_font_size (LABEL_FONT_SIZE);

        cr.move_to (x, y - LABEL_BOTTOM_PADDING);
        cr.show_text (name != null ? name : id);

        // Add a bit of "emulated" shadow around the Artboard
        cr.set_source_rgba (0.90, 0.90, 0.90, 1);
        cr.save ();
        cr.translate (2, 2);
        cr.rectangle (x, y, width, height);
        cr.restore ();
        cr.fill ();

        cr.set_source_rgba (1, 1, 1, 1);
        cr.rectangle (x, y, width, height);
        cr.fill ();

        if (items.length () > 0) {
            foreach (var item in items) {
                cr.save ();

                cr.translate (item.relative_x, item.relative_y);

                if (item is Goo.CanvasItemSimple) {
                    (item as Goo.CanvasRect).simple_paint (cr, bounds);
                }

                cr.restore ();
            }
        }
    }

    public override bool simple_is_item_at (double x, double y, Cairo.Context cr, bool is_pointer_event) {
        var is_on_handle = y < 0;

        return is_on_handle;
    }

    public double get_label_height () {
        return label_height + LABEL_BOTTOM_PADDING;
    }

    public unowned GLib.List<Goo.CanvasItem> get_items_at (
      double x, double y,
      Cairo.Context cr, bool is_pointer_event,
      bool parent_is_visible, GLib.List<Goo.CanvasItem> found_items) {
      var artboard_x = x;
      var artboard_y = y;

      canvas.convert_to_item_space (this, ref artboard_x, ref artboard_y);
      if (simple_is_item_at (
          artboard_x, artboard_y,
          cr, is_pointer_event)
      ) {
        found_items.append (this);
      }

      foreach (var item in items) {
        var item_x = x;
        var item_y = y;

        canvas.convert_to_item_space (item, ref item_x, ref item_y);

        var item_is_inside = item.simple_is_item_at (
          x, y,
          cr, is_pointer_event
        );

        if (item_is_inside) {
          found_items.append (item);
        }
      }

      return found_items;
    }
}

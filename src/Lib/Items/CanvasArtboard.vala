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
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

using Akira.Lib.Components;

/**
 * Generate the Artboard, based on the CanvasGroup item, which is basically a rectangle.
 */
public class Akira.Lib.Items.CanvasArtboard : Goo.CanvasGroup, Akira.Lib.Items.CanvasItem {
   public Gee.ArrayList<Component> components { get; set; }

   public Items.CanvasArtboard? artboard { get; set; }

   public bool is_loaded { get; set; }

   // Override the list type from the CanvasGroup.
   public new Akira.Models.ListModel<Lib.Items.CanvasItem> items;

   // Private attributes of the Artboard.
   public Goo.CanvasRect background;
   public Goo.CanvasText label;

   public CanvasArtboard (double _x, double _y, Goo.CanvasItem? _parent) {
      parent = _parent;

      // Artboards can't be nested.
      artboard = null;

      // Create the Artboard.
      x = y = 0;
      width = height = 1;
      init_position (this, _x, _y);

      create_background ();

      // Add extra attributes.
      is_loaded = _is_loaded;

      // Add the newly created item to the Canvas.
      parent.add_child (this, -1);

      // Force the generation of the item bounds on creation.
      Goo.CanvasBounds bounds;
      this.get_bounds (out bounds);

      // Add all the components that this item uses.
      components = new Gee.ArrayList<Component> ();
      components.add (new Name (this));
      components.add (new Transform (this));
      components.add (new Opacity (this));
      // Artboards have fills that can be edited, but they always start
      // with a full white background.
      var fill_color = Gdk.RGBA ();
      fill_color.parse ("#fff");
      components.add (new Fills (this, fill_color));
      components.add (new Size (this));
      components.add (new Layer ());

      // Init the items list.
      items = new Models.ListModel<Items.CanvasItem> ();

      create_label ();
   }

   private void create_background () {
      background = new Goo.CanvasRect (this, 0, 0, 1, 1, "line-width", 0.0, null);
      background.translate (0, 0);
      background.can_focus = false;

      this.bind_property ("width", background, "width", BindingFlags.SYNC_CREATE);
      this.bind_property ("height", background, "height", BindingFlags.SYNC_CREATE);
   }

   private void create_label () {
      // Create the text with the base Canvas as initial parent.
      label = new Goo.CanvasText (
         parent, name.name, x, y, 1.0,
         Goo.CanvasAnchorType.SW,
         "font", "Open Sans 10",
         "ellipsize", Pango.EllipsizeMode.END,
         null);
      label.can_focus = false;
      // Change the parent to allow mouse pointer selection.
      label.parent = this;

      this.transform.bind_property ("x", label, "x", BindingFlags.SYNC_CREATE);
      this.transform.bind_property ("y", label, "y", BindingFlags.SYNC_CREATE);
      this.bind_property ("width", label, "width", BindingFlags.SYNC_CREATE);

      this.name.bind_property ("name", label, "text", BindingFlags.SYNC_CREATE);
   }

   /**
    * Helper method to determine if a click event happened inside an artboard.
    */
   public bool is_inside (double x, double y) {
      return x <= bounds.x2
          && x >= bounds.x1
          && y >= bounds.y1
          && y <= bounds.y2;
  }

  /**
   * Helper method to determine if an item was moved inside an artboard.
   */
  public bool dropped_inside (Items.CanvasItem item) {
      return item.bounds.x1 < bounds.x2
         && item.bounds.x2 > bounds.x1
         && item.bounds.y1 < bounds.y2
         && item.bounds.y2 > bounds.y1;
   }

   public uint get_items_length () {
      return items.get_n_items ();
   }

   public void remove_item (Items.CanvasItem item) {
      items.remove_item.begin (item);
      item.artboard = null;
   }

   public void delete () {
      background.remove ();
      // Reassign the Canvas as parent to the label in order to remove it.
      label.parent = parent;
      label.remove ();
   }
}

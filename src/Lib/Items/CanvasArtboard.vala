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

   // Override the list type from he CanvasGroup.
   public new Akira.Models.ListModel<Lib.Items.CanvasItem> items;

   public CanvasArtboard (double _x, double _y, Goo.CanvasItem? _parent) {
      parent = _parent;

      // Artboards can't be nested.
      artboard = null;

      // Create the Artboard.
      x = _x;
      y = _y;
      width = height = 1;

      // Add extra attributes.
      is_loaded = _is_loaded;

      // Add the newly created item to the Canvas.
      parent.add_child (this, -1);

      // Force the generation of the item bounds on creation.
      Goo.CanvasBounds bounds;
      this.get_bounds (out bounds);

      // Add all the components that this item uses.
      components = new Gee.ArrayList<Component> ();
      components.add (new Components.Type (typeof (CanvasArtboard)));
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
}

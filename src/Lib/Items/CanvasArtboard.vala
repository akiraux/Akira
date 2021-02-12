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

   public CanvasArtboard (double _x, double _y, Goo.CanvasItem? _parent) {
      parent = _parent;
      canvas = parent.get_canvas () as Akira.Lib.Canvas;
      parent.add_child (this, -1);

      // Artboards can't be nested.
      artboard = null;

      // Create the Artboard.
      x = _x;
      y = _y;
      width = height = 1;

      // Add all the components that this item uses.
      components = new Gee.ArrayList<Component> ();
      components.add (new Components.Type (typeof (CanvasArtboard)));
      // Only the Name component needs the class to be passed on construct.
      // All the other components after this will inherit the class from the
      // main Component.
      components.add (new Name (this));
      components.add (new Transform ());
      components.add (new Opacity ());
      // Artboards have fills that can be edited, but they always start
      // with a full white background.
      var fill_color = Gdk.RGBA ();
      fill_color.parse ("rgba (255, 255, 255, 1)");
      components.add (new Fills (fill_color));
      components.add (new Size ());
      components.add (new Layer ());

      // Add extra attributes.
      is_loaded = _is_loaded;
   }
}

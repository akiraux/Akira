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

   // Override the list type of the Goo.CanvasGroup.
   public new Akira.Models.ListModel<Lib.Items.CanvasItem> items;

   // Unique attributes of the Artboard.
   public Goo.CanvasRect background;
   public Goo.CanvasText label;

   private const int FONT_SIZE = 10;
   private uint light_color;
   private uint dark_color;

   public CanvasArtboard (double _x, double _y, Goo.CanvasItem? _parent) {
      parent = _parent;

      // Artboards can't be nested.
      artboard = null;

      // Create the Artboard.
      x = y = 0;
      width = height = 1;
      init_position (this, _x, _y);

      // Add the newly created item to the Canvas.
      parent.add_child (this, -1);

      // Force the generation of the item bounds on creation.
      Goo.CanvasBounds bounds;
      this.get_bounds (out bounds);

      // Add all the components that this item uses.
      components = new Gee.ArrayList<Component> ();
      components.add (new Name (this));
      components.add (new Coordinates (this));
      components.add (new Opacity (this));
      components.add (new Size (this));

      // Create the background element before adding the Fills component.
      create_background ();

      // Artboards have fills that can be edited, but they always start
      // with a full white background.
      var fill_color = Gdk.RGBA ();
      fill_color.parse ("#fff");
      components.add (new Fills (this, fill_color));
      components.add (new Layer ());

      // Init the items list.
      items = new Models.ListModel<Items.CanvasItem> ();

      create_label ();
   }

   private void create_background () {
      background = new Goo.CanvasRect (this, 0, 0, 1, 1, "line-width", 0.0, null);
      background.translate (0, 0);
      background.can_focus = false;
      // Even if this item doesn't receive any pointer events we can't set NONE
      // since users should be able to click on the artboard's background to drag
      // the artboard around when the artboard is selected.

      this.size.bind_property ("width", background, "width", BindingFlags.SYNC_CREATE);
      this.size.bind_property ("height", background, "height", BindingFlags.SYNC_CREATE);
   }

   private void create_label () {
      // Define the label colors for dark/light theme variation.
      light_color = Utils.Color.color_string_to_uint ("rgba(255, 255, 255, 0.75)");
      dark_color = Utils.Color.color_string_to_uint ("rgba(0, 0, 0, 0.75)");

      // Type cast the akira canvas to gain access to its attributes.
      var akira_canvas = canvas as Lib.Canvas;

      // Create the text with the base Canvas as initial parent.
      label = new Goo.CanvasText (
         parent, name.name, x, y, 1.0,
         Goo.CanvasAnchorType.SW,
         "font", "Open Sans " + (FONT_SIZE / akira_canvas.current_scale).to_string (),
         "ellipsize", Pango.EllipsizeMode.END,
         "fill-color-rgba", settings.dark_theme ? light_color : dark_color,
         null);
      label.can_focus = false;
      // Change the parent to allow mouse pointer selection.
      label.parent = this;

      this.bind_property ("visibility", label, "visibility", BindingFlags.SYNC_CREATE);
      this.bind_property ("pointer_events", label, "pointer_events", BindingFlags.SYNC_CREATE);
      this.name.bind_property ("name", label, "text", BindingFlags.SYNC_CREATE);
      this.size.bind_property ("width", label, "width", BindingFlags.SYNC_CREATE);

      // Listen to the theme changing event to update the label color.
      akira_canvas.window.event_bus.change_theme.connect (on_theme_changed);

      // Update the label font size when the canvas zoom changes.
      akira_canvas.window.event_bus.set_scale.connect (on_canvas_scaled);
   }

   /*
    * Update the color of the artboard label based on the light/dark theme.
    */
   private void on_theme_changed () {
      label.set ("fill-color-rgba", settings.dark_theme ? light_color : dark_color);
   }

   /*
    * Update the artboard label font size based on the current scale.
    */
   private void on_canvas_scaled (double scale) {
      label.set ("font", "Open Sans " + (FONT_SIZE / scale).to_string ());
   }

   /**
    * Helper method to determine if a click event happened inside an artboard.
    */
   public bool is_inside (double x, double y) {
      return x <= background.bounds.x2
          && x >= background.bounds.x1
          && y >= background.bounds.y1
          && y <= background.bounds.y2;
  }

   /**
    * Detect if an item was moved outside the artboard's sizing limits.
    * We use the background bounds because the artboard bounds grow based
    * on the location of the child items. So if an item is outside the
    * artboard's background, the artboard bounds will reflect the new group bounds.
    */
   public bool is_outside (Items.CanvasItem item) {
      return item.coordinates.x1 > background.bounds.x2 ||
             item.coordinates.y1 > background.bounds.y2 ||
             item.coordinates.x2 < background.bounds.x1 ||
             item.coordinates.y2 < background.bounds.y1;
   }

   public uint get_items_length () {
      return items.get_n_items ();
   }

   public void remove_item (Items.CanvasItem item) {
      // Remove the child from the GooCanvasItem parent.
      remove_child (find_child (item));
      // Remove the item from the ListModel.
      items.remove_item.begin (item);
      // Unset the artboard attribute.
      item.artboard = null;
   }

   public void delete () {
      background.remove ();

      // Type cast the akira canvas to gain access to its attributes.
      var akira_canvas = canvas as Lib.Canvas;
      // Disconnect previously set events.
      akira_canvas.window.event_bus.change_theme.disconnect (on_theme_changed);
      akira_canvas.window.event_bus.set_scale.disconnect (on_canvas_scaled);

      // Reassign the Canvas as parent to the label in order to remove it.
      label.parent = parent;
      label.remove ();
   }
}

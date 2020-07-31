/*
 * Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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

 /*
  * This class is used to create a ghost duplicate of each item to keep attached
  * to the main canvas. These ghost items will always be CanvasRect items, ignoring
  * rotation and skew, in order to always return the correct bounds and enable the
  * rulers distance overlay feature.
  */
public class Akira.Lib.Managers.GhostBoundsManager : Object {
    private const string STROKE_COLOR = "#41c9fd";
    private const double LINE_WIDTH = 1.0;

    public weak Akira.Lib.Canvas canvas;

    // Matches the original item in order to keep the translation and rotation accurate.
    private Goo.CanvasRect item;
    // Bounding Box item to be generated on the fly when the user requires it.
    private Goo.CanvasRect ghost;

    public Goo.CanvasBounds bounds {
        get {
            return item.bounds;
        }
    }

    public GhostBoundsManager (Models.CanvasItem original_item) {
        canvas = original_item.canvas;
        item = new Goo.CanvasRect (null, 0, 0, 1, 1, "line-width", 0, null);
        item.visibility = Goo.CanvasItemVisibility.HIDDEN;
        item.set ("parent", canvas.get_root_item ());
        item.can_focus = false;
    }

    /*
     * Update the item to match size and transform matrix of the original item.
     */
    public void update (Models.CanvasItem original_item) {
        double width, height;
        original_item.get ("width", out width, "height", out height);

        item.set ("width", width);
        item.set ("height", height);
        item.set_transform (original_item.get_real_transform ());
    }

    public void delete () {
        item.remove ();
        hide ();
    }

    /*
     * Show the ghost effect.
     */
    public void show () {
        if (ghost != null) {
            return;
        }

        ghost = new Goo.CanvasRect (
            null,
            item.bounds.x1, item.bounds.y1,
            item.bounds.x2 - item.bounds.x1, item.bounds.y2 - item.bounds.y1,
            "line-width", LINE_WIDTH / canvas.current_scale,
            "stroke-color", STROKE_COLOR,
            null
        );
        ghost.set ("parent", item.canvas.get_root_item ());
        ghost.can_focus = false;
    }

    /*
     * Hide the ghost effect.
     */
    public void hide () {
        ghost.remove ();
        ghost = null;
    }
}

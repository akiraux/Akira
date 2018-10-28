/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Felipe Escoto <felescoto95@hotmail.com>
* Edited by: Alessandro Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Canvas : Goo.Canvas {
    private const int MIN_SIZE = 40;

    /**
     * Signal triggered when item was clicked by the user
     */
    public signal void item_clicked (Goo.CanvasItem? item);

    /**
     * Signal triggered when item has finished moving by the user,
     * and a change of it's coordenates was made
     */
    public signal void item_moved (Goo.CanvasItem? item);

    public weak Goo.CanvasItem? selected_item;
    public weak Goo.CanvasItem? select_effect;

    public Goo.CanvasItem[] nobs;
    private Goo.CanvasItem? nob_tl;
    private weak Goo.CanvasItem? nob_tc;
    private weak Goo.CanvasItem? nob_tr;
    private weak Goo.CanvasItem? nob_rc;
    private weak Goo.CanvasItem? nob_bl;
    private weak Goo.CanvasItem? nob_bc;
    private weak Goo.CanvasItem? nob_br;
    private weak Goo.CanvasItem? nob_lc;

    public weak Goo.CanvasItem? hovered_item;
    public weak Goo.CanvasRect? hover_effect;

    private bool holding;
    private double event_x_root;
    private double event_y_root;
    private double start_x;
    private double start_y;
    private double delta_x;
    private double delta_y;
    private double hover_x;
    private double hover_y;
    private double nob_size;
    private double current_scale;
    private int holding_id = 0;

    construct {
        events |= Gdk.EventMask.BUTTON_PRESS_MASK;
        events |= Gdk.EventMask.BUTTON_RELEASE_MASK;
        events |= Gdk.EventMask.POINTER_MOTION_MASK;
    }

    public override bool button_press_event (Gdk.EventButton event) {
        remove_hover_effect ();
        remove_select_effect ();

        current_scale = get_scale ();
        event_x_root = event.x;
        event_y_root = event.y;

        selected_item = get_item_at (event.x / current_scale, event.y / current_scale, true);

        if (selected_item != null) {
            if (selected_item is Goo.CanvasItemSimple) {
                start_x = (selected_item as Goo.CanvasItemSimple).x;
                start_y = (selected_item as Goo.CanvasItemSimple).y;
            }

            holding = true;
            add_select_effect (selected_item);
            grab_focus (selected_item);
        } else {
            grab_focus (get_root_item ());
        }

        return true;
    }

    public override bool button_release_event (Gdk.EventButton event) {
        if (!holding) return false;

        holding = false;

        if (delta_x == 0 && delta_y == 0) { // Hidden for now. Just change poss && (start_w == real_width) && (start_h == real_height)) {
            return false;
        }

        item_moved (selected_item);
        add_hover_effect (selected_item);

        delta_x = 0;
        delta_y = 0;

        return false;
    }

    public override bool motion_notify_event (Gdk.EventMotion event) {
        if (!holding) {
            motion_hover_event (event);

            return false;
        }

        delta_x = (event.x - event_x_root) / current_scale;
        delta_y = (event.y - event_y_root) / current_scale;

        var item = ((Goo.CanvasItemSimple) selected_item);
        var stroke = item.line_width;
        var width = item.bounds.x2 - item.bounds.x1 + stroke;
        var height = item.bounds.y2 - item.bounds.y1 + stroke;
        switch (holding_id) {
            case 0: // Moving
                ((Goo.CanvasItemSimple) selected_item).x = delta_x + start_x;
                ((Goo.CanvasItemSimple) selected_item).y = delta_y + start_y;

                // Bounding box
                ((Goo.CanvasItemSimple) select_effect).x = delta_x + start_x - ((Goo.CanvasItemSimple) selected_item).line_width;
                ((Goo.CanvasItemSimple) select_effect).y = delta_y + start_y - ((Goo.CanvasItemSimple) selected_item).line_width;

                // TOP LEFT nob
                ((Goo.CanvasItemSimple) nob_tl).x = delta_x + start_x - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_tl).y = delta_y + start_y - (nob_size / 2) - stroke;

                // TOP RIGHT nob
                ((Goo.CanvasItemSimple) nob_tr).x = delta_x + start_x + width - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_tr).y = delta_y + start_y - (nob_size / 2) - stroke;

                // BOTTOM RIGHT nob
                ((Goo.CanvasItemSimple) nob_br).x = delta_x + start_x + width - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_br).y = delta_y + start_y + height - (nob_size / 2) - stroke;

                // BOTTOM LEFT nob
                ((Goo.CanvasItemSimple) nob_bl).x = delta_x + start_x - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_bl).y = delta_y + start_y + height - (nob_size / 2) - stroke;

                // TOP CENTER nob
                ((Goo.CanvasItemSimple) nob_tc).x = delta_x + start_x + (width / 2) - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_tc).y = delta_y + start_y - (nob_size / 2) - stroke;

                // RIGHT CENTER nob
                ((Goo.CanvasItemSimple) nob_rc).x = delta_x + start_x + width - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_rc).y = delta_y + start_y + (height / 2) - (nob_size / 2) - stroke;

                // BOTTOM CENTER nob
                ((Goo.CanvasItemSimple) nob_bc).x = delta_x + start_x + (width / 2) - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_bc).y = delta_y + start_y + height - (nob_size / 2) - stroke;

                // LEFT CENTER nob
                ((Goo.CanvasItemSimple) nob_lc).x = delta_x + start_x - (nob_size / 2) - stroke;
                ((Goo.CanvasItemSimple) nob_lc).y = delta_y + start_y + (height / 2) - (nob_size / 2) - stroke;

                debug ("X:%f - Y:%f\n", ((Goo.CanvasItemSimple) selected_item).x, ((Goo.CanvasItemSimple) selected_item).y);
                break;
            //  case 1: // Top left
            //      delta_x = fix_position (x, real_width, start_w);
            //      delta_y = fix_position (y, real_height, start_h);
            //      real_height = fix_size ((int) (start_h - 1 / current_scale * y));
            //      real_width = fix_size ((int) (start_w - 1 / current_scale * x));
            //      break;
            //  case 2: // Top
            //      delta_y = fix_position (y, real_height, start_h);
            //      real_height = fix_size ((int)(start_h - 1 / current_scale * y));
            //      break;
            //  case 3: // Top right
            //      delta_y = fix_position (y, real_height, start_h);
            //      real_height = fix_size ((int)(start_h - 1 / current_scale * y));
            //      real_width = fix_size ((int)(start_w + 1 / current_scale * x));
            //      break;
            //  case 4: // Right
            //      real_width = fix_size ((int)(start_w + 1 / current_scale * x));
            //      break;
            //  case 5: // Bottom Right
            //      real_width = fix_size ((int)(start_w + 1 / current_scale * x));
            //      real_height = fix_size ((int)(start_h + 1 / current_scale * y));
            //      break;
            //  case 6: // Bottom
            //      real_height = fix_size ((int)(start_h + 1 / current_scale * y));
            //      break;
            //  case 7: // Bottom left
            //      real_height = fix_size ((int)(start_h + 1 / current_scale * y));
            //      real_width = fix_size ((int)(start_w - 1 / current_scale * x));
            //      delta_x = fix_position (x, real_width, start_w);
            //      break;
            //  case 8: // Left
            //      real_width = fix_size ((int) (start_w - 1 / current_scale * x));
            //      delta_x = fix_position (x, real_width, start_w);
            //      break;
        }

        return false;
    }

    private void motion_hover_event (Gdk.EventMotion event) {
        hovered_item = get_item_at (event.x / get_scale (), event.y / get_scale (), true);

        if (!(hovered_item is Goo.CanvasItem)) {
            remove_hover_effect ();
            return;
        }

        add_hover_effect (hovered_item);

        if ((hover_x != (hovered_item as Goo.CanvasItemSimple).x
            || hover_y != (hovered_item as Goo.CanvasItemSimple).y)
            && hover_effect != hovered_item) {
            remove_hover_effect ();
        }

        hover_x = (hovered_item as Goo.CanvasItemSimple).x;
        hover_y = (hovered_item as Goo.CanvasItemSimple).y;
    }

    private void add_select_effect (Goo.CanvasItem? target) {
        if (target == null || target == select_effect) {
            return;
        }

        var item = (target as Goo.CanvasItemSimple);

        var line_width = 1.0 / current_scale;
        var stroke = item.line_width;
        var x = item.x - stroke;
        var y = item.y - stroke;
        var width = item.bounds.x2 - item.bounds.x1 + stroke;
        var height = item.bounds.y2 - item.bounds.y1 + stroke;

        select_effect = Goo.CanvasRect.create (get_root_item (), x, y, width, height,
                                   "line-width", line_width, 
                                   "stroke-color", "#666"
                                   );

        nob_size = 10 / current_scale;
        //  nob_tl = Goo.CanvasRect.create (get_root_item (), x - (nob_size / 2), y - (nob_size / 2), nob_size, nob_size,
        //                          "line-width", line_width, 
        //                          "stroke-color", "#41c9fd",
        //                          "fill-color", "#fff"
        //                          );

        nob_tl = new Akira.Lib.Selection.Nob.with_values (get_root_item (), x, y, current_scale);

        nob_tr = Goo.CanvasRect.create (get_root_item (), x + width - (nob_size / 2), y - (nob_size / 2), nob_size, nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_bl = Goo.CanvasRect.create (get_root_item (), x - (nob_size / 2), y + height - (nob_size / 2), nob_size, nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_br = Goo.CanvasRect.create (get_root_item (), x + width - (nob_size / 2), y + height - (nob_size / 2), nob_size, nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_tc = Goo.CanvasRect.create (get_root_item (), x + (width / 2) - (nob_size / 2), y - (nob_size / 2), nob_size, nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_rc = Goo.CanvasRect.create (get_root_item (), 
                                x + width - (nob_size / 2), 
                                y + (height / 2) - (nob_size / 2), 
                                nob_size, 
                                nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_bc = Goo.CanvasRect.create (get_root_item (), 
                                x + (width / 2) - (nob_size / 2), 
                                y + height - (nob_size / 2), 
                                nob_size, 
                                nob_size,
                                "line-width", line_width, 
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        nob_lc = Goo.CanvasRect.create (get_root_item (),
                                x - (nob_size / 2),
                                y + (height / 2) - (nob_size / 2),
                                nob_size,
                                nob_size,
                                "line-width", line_width,
                                "stroke-color", "#41c9fd",
                                "fill-color", "#fff"
                                );

        select_effect.can_focus = false;
        nob_tl.can_focus = false;
        nob_tr.can_focus = false;
        nob_bl.can_focus = false;
        nob_br.can_focus = false;
        nob_tc.can_focus = false;
        nob_rc.can_focus = false;
        nob_bc.can_focus = false;
        nob_lc.can_focus = false;

        nobs = {nob_tl, nob_tr, nob_bl, nob_br, nob_tc, nob_rc, nob_bc, nob_lc};
    }

    private void remove_select_effect () {
        if (select_effect == null) {
            return;
        }

        select_effect.remove ();
        select_effect = null;

        nob_tl.remove ();
        nob_bl.remove ();
        nob_tr.remove ();
        nob_br.remove ();
        nob_tc.remove ();
        nob_rc.remove ();
        nob_bc.remove ();
        nob_lc.remove ();
    }

    private void add_hover_effect (Goo.CanvasItem? target) {
        if (target == null || hover_effect != null || target == selected_item || target == select_effect) {
            return;
        }

        if (target in nobs) {
            set_cursor_for_nob (target);
            return;
        }

        var item = (target as Goo.CanvasItemSimple);

        var line_width = 2.0 / get_scale ();
        var stroke = item.line_width;
        var x = item.x - stroke;
        var y = item.y - stroke;
        var width = item.bounds.x2 - item.bounds.x1 + stroke;
        var height = item.bounds.y2 - item.bounds.y1 + stroke;

        hover_effect = Goo.CanvasRect.create (get_root_item (), x, y, width, height,
                                   "line-width", line_width, 
                                   "stroke-color", "#41c9fd"
                                   );

        hover_effect.can_focus = false;
    }

    private void remove_hover_effect () {
        set_cursor (Gdk.CursorType.ARROW);

        if (hover_effect == null) {
            return;
        }

        hover_effect.remove ();
        hover_effect = null;
    }

    private void set_cursor_for_nob (Goo.CanvasItem? target) {
        if (target == nob_tl) {
            set_cursor (Gdk.CursorType.TOP_LEFT_CORNER);
        } else if (target == nob_tr) {
            set_cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
        } else if (target == nob_br) {
            set_cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
        } else if (target == nob_bl) {
            set_cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);
        } else if (target == nob_rc) {
            set_cursor (Gdk.CursorType.RIGHT_SIDE);
        } else if (target == nob_bc) {
            set_cursor (Gdk.CursorType.BOTTOM_SIDE);
        } else if (target == nob_lc) {
            set_cursor (Gdk.CursorType.LEFT_SIDE);
        } else if (target == nob_tc) {
            set_cursor (Gdk.CursorType.TOP_SIDE);
        } else {
            set_cursor (Gdk.CursorType.ARROW);
        }
    }

    private void set_cursor (Gdk.CursorType cursor_type) {
        var cursor = new Gdk.Cursor.for_display (Gdk.Display.get_default (), cursor_type);
        get_window ().get_screen ().get_root_window ().set_cursor (cursor);
    }

    // To make it so items can't become imposible to grab. TODOs
    //  private int fix_position (int delta, int length, int initial_length) {
    //      var max_delta = (initial_length - MIN_SIZE) * current_scale;
    //      if (delta < max_delta) {
    //          return delta;
    //      } else {
    //          return (int) max_delta;
    //      }
    //  }

    //  private int fix_size (int size) {
    //      return size > MIN_SIZE ? size : MIN_SIZE;
    //  }
}
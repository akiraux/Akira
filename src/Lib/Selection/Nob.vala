/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Lib.Selection.Nob : Goo.CanvasRect {
    enum Type {
        NONE=-1,
        TOP_LEFT,
        TOP_CENTER,
        TOP_RIGHT,
        RIGHT_CENTER,
        BOTTOM_RIGHT,
        BOTTOM_CENTER,
        BOTTOM_LEFT,
        LEFT_CENTER,
        ROTATE
    }

    private new Akira.Lib.Canvas canvas;

    private string color_fill { get; set; default = "#fff"; }
    private string color_stroke { get; set; default = "#41c9fd"; }
    private double current_scale { get; set; default = 1.0; }
    public int nob_type;
    private double nob_size;

    public Nob (Akira.Lib.Canvas _canvas, Goo.CanvasItem? root, double scale, int i) {
        canvas = _canvas;
        nob_type = i;
        current_scale = scale;
        can_focus = false;

        parent = null;
        height = 10 / current_scale;
        width = 10 / current_scale;
        nob_size = width;
        line_width = 1.0 / current_scale;
        fill_color = color_fill;
        stroke_color = color_stroke;
        radius_x = i == 8 ? width : 0;
        radius_y = i == 8 ? width : 0;

        set ("parent", root);
    }

    public void update_position (Goo.CanvasItem? target, Goo.CanvasItem? select_effect) {
        var item = (target as Goo.CanvasItemSimple);

        var stroke = (item.line_width / 2);
        double x, y, width, height;
        target.get ("x", out x, "y", out y, "width", out width, "height", out height);

        bool print_middle_width_nobs = width > nob_size * 3;
        bool print_middle_height_nobs = height > nob_size * 3;

        var nob_offset = (nob_size / 2);

        var transform = Cairo.Matrix.identity ();
        item.get_transform (out transform);

        // TOP LEFT nob
        if (nob_type == Type.TOP_LEFT) {
            set_transform (transform);
            if (print_middle_width_nobs && print_middle_height_nobs) {
                translate (x - (nob_offset + stroke), y - (nob_offset + stroke));
            } else {
                translate (x - nob_size - stroke, y - nob_size - stroke);
            }
            raise (item);
        }

        // TOP CENTER nob
        if (nob_type == Type.TOP_CENTER) {
            if (print_middle_width_nobs) {
                set_transform (transform);
                if (print_middle_height_nobs) {
                    translate (x + (width / 2) - nob_offset, y - (nob_offset + stroke));
                } else {
                    translate (x + (width / 2) - nob_offset, y - (nob_size + stroke));
                }
                set_visibility (Goo.CanvasItemVisibility.VISIBLE);
            } else {
                set_visibility (Goo.CanvasItemVisibility.HIDDEN);
            }
            raise (item);
        }

        // TOP RIGHT nob
        if (nob_type == Type.TOP_RIGHT) {
            set_transform (transform);
            if (print_middle_width_nobs && print_middle_height_nobs) {
                translate (x + width - (nob_offset - stroke), y - (nob_offset + stroke));
            } else {
                translate (x + width + stroke, y - (nob_size + stroke));
            }
            raise (item);
        }

        // RIGHT CENTER nob
        if (nob_type == Type.RIGHT_CENTER) {
            if (print_middle_height_nobs) {
                set_transform (transform);
                if (print_middle_width_nobs) {
                    translate (x + width - (nob_offset - stroke), y + (height / 2) - nob_offset);
                } else {
                    translate (x + width + stroke, y + (height / 2) - nob_offset);
                }
                set_visibility (Goo.CanvasItemVisibility.VISIBLE);
            } else {
                set_visibility (Goo.CanvasItemVisibility.HIDDEN);
            }
            raise (item);
        }

        // BOTTOM RIGHT nob
        if (nob_type == Type.BOTTOM_RIGHT) {
            set_transform (transform);
            if (print_middle_width_nobs && print_middle_height_nobs) {
                translate (x + width - (nob_offset - stroke), y + height - (nob_offset - stroke));
            } else {
                translate (x + width + stroke, y + height + stroke);
            }
            raise (item);
        }

        // BOTTOM CENTER nob
        if (nob_type == Type.BOTTOM_CENTER) {
            if (print_middle_width_nobs) {
                set_transform (transform);
                if (print_middle_height_nobs) {
                    translate (x + (width / 2) - nob_offset, y + height - (nob_offset - stroke));
                } else {
                    translate (x + (width / 2) - nob_offset, y + height + stroke);
                }
                set_visibility (Goo.CanvasItemVisibility.VISIBLE);
            } else {
                set_visibility (Goo.CanvasItemVisibility.HIDDEN);
            }
            raise (item);
        }

        // BOTTOM LEFT nob
        if (nob_type == Type.BOTTOM_LEFT) {
            set_transform (transform);
            if (print_middle_width_nobs && print_middle_height_nobs) {
                translate (x - (nob_offset + stroke), y + height - (nob_offset - stroke));
            } else {
                translate (x - (nob_size + stroke), y + height + stroke);
            }
            raise (item);
        }

        // LEFT CENTER nob
        if (nob_type == Type.LEFT_CENTER) {
            if (print_middle_height_nobs) {
                set_transform (transform);
                if (print_middle_width_nobs) {
                    translate (x - (nob_offset + stroke), y + (height / 2) - nob_offset);
                } else {
                    translate (x - (nob_size + stroke), y + (height / 2) - nob_offset);
                }
                set_visibility (Goo.CanvasItemVisibility.VISIBLE);
            } else {
                set_visibility (Goo.CanvasItemVisibility.HIDDEN);
            }
            raise (item);
        }

        // ROTATE nob
        if (nob_type == Type.ROTATE) {
            double distance = 40;
            if (current_scale < 1) {
                distance = 40 * (2 * current_scale - 1);
            }

            set_transform (transform);
            translate (x + (width / 2) - nob_offset, y - nob_offset - distance);
            raise (item);
        }
    }

    private void set_visibility (Goo.CanvasItemVisibility visibility) {
        set ("visibility", visibility);
    }

    public void set_cursor () {
        switch (nob_type) {
            case Type.NONE:
                canvas.set_cursor_by_edit_mode ();
                break;
            case Type.TOP_LEFT:
                canvas.set_cursor (Gdk.CursorType.TOP_LEFT_CORNER);
                break;
            case Type.TOP_CENTER:
                canvas.set_cursor (Gdk.CursorType.TOP_SIDE);
                break;
            case Type.TOP_RIGHT:
                canvas.set_cursor (Gdk.CursorType.TOP_RIGHT_CORNER);
                break;
            case Type.RIGHT_CENTER:
                canvas.set_cursor (Gdk.CursorType.RIGHT_SIDE);
                break;
            case Type.BOTTOM_RIGHT:
                canvas.set_cursor (Gdk.CursorType.BOTTOM_RIGHT_CORNER);
                break;
            case Type.BOTTOM_CENTER:
                canvas.set_cursor (Gdk.CursorType.BOTTOM_SIDE);
                break;
            case Type.BOTTOM_LEFT:
                canvas.set_cursor (Gdk.CursorType.BOTTOM_LEFT_CORNER);
                break;
            case Type.LEFT_CENTER:
                canvas.set_cursor (Gdk.CursorType.LEFT_SIDE);
                break;
            case Type.ROTATE:
                canvas.set_cursor (Gdk.CursorType.ICON);
                break;
        }
    }
}

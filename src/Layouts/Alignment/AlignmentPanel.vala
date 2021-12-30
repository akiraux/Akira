/*
 * Copyright (c) 2019 Alecaddd (http://alecaddd.com)
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
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */
public class Akira.Layouts.Alignment.AlignmentPanel : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public int current_button_column { get; set; default = 0; }

    private struct AlignBoxItem {
        public string type;
        public Utils.ItemAlignment.AlignmentDirection? alignment_direction;
        public string? icon_name;
        public string? tooltip_text;
        public string[]? accels;

        public AlignBoxItem (
            string type,
            Utils.ItemAlignment.AlignmentDirection? alignment_direction = null,
            string? icon_name = null,
            string? tooltip_text = null,
            string[]? accels = null) {
            this.type = type;
            this.alignment_direction = alignment_direction;
            this.icon_name = icon_name;
            this.tooltip_text = tooltip_text;
            this.accels = accels;
        }
    }

    private AlignBoxItem[] align_items_panel_buttons = {
        //AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.HEVEN, "distribute-horizontal-center", _("Distribute Horizontally"), {"<Ctrl><Shift>1"}),
        //AlignBoxItem ("btn", Utils.ItemAlignment.AlignemtDirection.VEVEN, "distribute-vertical-center", _("Distribute Vertically"), {"<Ctrl><Shift>2"}),
        //AlignBoxItem ("sep"),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.LEFT, "align-horizontal-left", _("Align Left"), {"<Ctrl><Shift>3"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.HCENTER, "align-horizontal-center", _("Align Center"), {"<Ctrl><Shift>4"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.RIGHT, "align-horizontal-right", _("Align Right"), {"<Ctrl><Shift>5"}),
        AlignBoxItem ("sep"),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.TOP, "align-vertical-top", _("Align Top"), {"<Ctrl><Shift>6"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.VCENTER, "align-vertical-center", _("Align Middle"), {"<Ctrl><Shift>7"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.BOTTOM, "align-vertical-bottom", _("Align Bottom"), {"<Ctrl><Shift>8"})
    };

    public AlignmentPanel (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        get_style_context ().add_class ("alignment-box");
        column_homogeneous = true;
        hexpand = true;

        foreach (var item in align_items_panel_buttons) {
            switch (item.type) {
                case "sep":
                    var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
                    separator.halign = Gtk.Align.CENTER;
                    separator.margin_top = separator.margin_bottom = 4;

                    attach (separator, current_button_column++, 0, 1, 1);
                    break;

                case "btn":
                    var tmp_align_box_button =
                        new Layouts.Alignment.AlignmentButton (
                            view_canvas,
                            item.alignment_direction,
                            item.icon_name,
                            item.tooltip_text,
                            item.accels);

                    attach (tmp_align_box_button, current_button_column++, 0, 1, 1);
                    break;
            }
        }
    }
}

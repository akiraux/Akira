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
public class Akira.Layouts.Partials.AlignItemsPanel : Gtk.Grid {
    private Gtk.Grid alignment_box;

    private struct AlignBoxItem {
        public string type;
        public string action;
        public string icon_name;
        public string tooltip_text;
    }

    private const AlignBoxItem[] align_items_panel_buttons = {
        { "btn", "even-h", "distribute-horizontal-center", "Distribute centers evenly horizontally" },
        { "btn", "even-v", "distribute-vertical-center", "Distribute center evenly vertically" },
        { "sep" },
        { "btn", "alig-h-l", "align-horizontal-left", "Align left sides" },
        { "btn", "alig-h-c", "align-horizontal-center", "Center on horizontal axis" },
        { "btn", "alig-h-r", "align-horizontal-right", "Align right sides" },
        { "sep" },
        { "btn", "alig-v-t", "align-vertical-top", "Align top sides" },
        { "btn", "alig-v-c", "align-vertical-center", "Center on vertical axis" },
        { "btn", "alig-v-b", "align-vertical-bottom", "Align bottom sides" }
    };

    public AlignItemsPanel () {
        Object (
            orientation: Gtk.Orientation.VERTICAL
            );
    }

    construct {
        vexpand = false;
        hexpand = true;

        alignment_box = new Gtk.Grid ();
        alignment_box.halign = Gtk.Align.CENTER;

        int current_button_column = 0;

        foreach (var item in align_items_panel_buttons) {
            switch (item.type) {
                case "sep":
                    alignment_box.attach (new Gtk.Separator
                                          (Gtk.Orientation.VERTICAL),
                                          current_button_column++, 0, 1, 1 );
                    break;

                case "btn":
                    var tmp_align_box_button =
                        new Akira.Partials.AlignBoxButton (item.action,
                                                           item.icon_name,
                                                           item.tooltip_text);

                    alignment_box.attach (tmp_align_box_button,
                                          current_button_column++,
                                          0, 1, 1);
                    break;
            }
        }

        get_style_context ().add_class ("alignment-box");

        attach (alignment_box, 1, 0, 1, 1);
    }
}

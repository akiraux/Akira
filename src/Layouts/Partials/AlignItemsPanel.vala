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
    public weak Akira.Window window { get; construct; }

    public int current_button_column { get; set; default = 0;}

    private struct AlignBoxItem {
        public string type;
        public string action_name;
        public string icon_name;
        public string tooltip_text;
    }

    private const AlignBoxItem[] ALIGN_ITEMS_PANEL_BUTTONS = {
        { "btn", "even-h", "distribute-horizontal-center", "Distribute Horizontally" },
        { "btn", "even-v", "distribute-vertical-center", "Distribute Vertically" },
        { "sep" },
        { "btn", "alig-h-l", "align-horizontal-left", "Align Left" },
        { "btn", "alig-h-c", "align-horizontal-center", "Align Center" },
        { "btn", "alig-h-r", "align-horizontal-right", "Align Right" },
        { "sep" },
        { "btn", "alig-v-t", "align-vertical-top", "Align Top" },
        { "btn", "alig-v-c", "align-vertical-center", "Align Middle" },
        { "btn", "alig-v-b", "align-vertical-bottom", "Align Bottom" }
    };

    public AlignItemsPanel (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        halign = Gtk.Align.FILL;
        get_style_context ().add_class ("alignment-box");

        var alignment_box = new Gtk.Grid ();
        alignment_box.halign = Gtk.Align.CENTER;
        alignment_box.hexpand = true;

        foreach (var item in ALIGN_ITEMS_PANEL_BUTTONS) {
            switch (item.type) {
                case "sep":
                    alignment_box.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL),
                                                             current_button_column++, 0, 1, 1 );
                    break;

                case "btn":
                    var tmp_align_box_button = new Akira.Partials.AlignBoxButton (
                                                                  window,
                                                                  item.action_name,
                                                                  item.icon_name,
                                                                  item.tooltip_text);

                    alignment_box.attach (tmp_align_box_button, current_button_column++, 0, 1, 1);
                    break;
            }
        }

        attach (alignment_box, 1, 0, 1, 1);
    }
}

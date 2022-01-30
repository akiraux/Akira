/*
 * Copyright (c) 2019-2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 *              Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */
public class Akira.Layouts.Alignment.AlignmentPanel : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    private Gee.ArrayList<Gtk.Button> buttons;
    private int grid_column { get; set; default = 0; }

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

    private AlignBoxItem[] align_items_buttons = {
        //AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.HEVEN, "distribute-horizontal-center", _("Distribute Horizontally"), {"<Ctrl><Shift>1"}),
        //AlignBoxItem ("btn", Utils.ItemAlignment.AlignemtDirection.VEVEN, "distribute-vertical-center", _("Distribute Vertically"), {"<Ctrl><Shift>2"}),
        //AlignBoxItem ("sep"),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.LEFT, "align-horizontal-left", _("Align Left"), {"<Alt>1"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.HCENTER, "align-horizontal-center", _("Align Center"), {"<Alt>2"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.RIGHT, "align-horizontal-right", _("Align Right"), {"<Alt>3"}),
        AlignBoxItem ("sep"),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.TOP, "align-vertical-top", _("Align Top"), {"<Alt>4"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.VCENTER, "align-vertical-center", _("Align Middle"), {"<Alt>5"}),
        AlignBoxItem ("btn", Utils.ItemAlignment.AlignmentDirection.BOTTOM, "align-vertical-bottom", _("Align Bottom"), {"<Alt>6"})
    };

    public AlignmentPanel (Lib.ViewCanvas view_canvas) {
        Object (view_canvas: view_canvas);
    }

    construct {
        get_style_context ().add_class ("alignment-panel");
        column_homogeneous = true;
        hexpand = true;
        buttons = new Gee.ArrayList<Gtk.Button> ();

        foreach (var item in align_items_buttons) {
            switch (item.type) {
                case "sep":
                    var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL) {
                        halign = Gtk.Align.CENTER,
                        margin_top = margin_bottom = 4
                    };

                    attach (separator, grid_column++, 0, 1, 1);
                    break;

                case "btn":
                    var button = new Gtk.Button () {
                        halign = valign = Gtk.Align.CENTER,
                        can_focus = false,
                        sensitive = false,
                        tooltip_markup = Granite.markup_accel_tooltip (item.accels, item.tooltip_text)
                    };
                    button.add (new Widgets.ButtonImage (item.icon_name, Gtk.IconSize.SMALL_TOOLBAR));
                    button.clicked.connect (() => {
                        view_canvas.window.event_bus.selection_align (item.alignment_direction);
                    });
                    button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
                    button.get_style_context ().add_class ("button-rounded");

                    attach (button, grid_column++, 0, 1, 1);
                    buttons.add (button);
                    break;
            }
        }

        view_canvas.window.event_bus.selection_modified.connect (on_selection_modified);
    }

    private void on_selection_modified () {
        unowned var sm = view_canvas.selection_manager;
        foreach (var button in buttons) {
            button.sensitive = sm.count () > 1;
        }
    }
}

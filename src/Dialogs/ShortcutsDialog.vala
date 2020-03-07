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

public class Akira.Dialogs.ShortcutsDialog : Gtk.Dialog {
    public weak Akira.Window window { get; construct; }

    public ShortcutsDialog (Akira.Window window) {
        Object (
            window: window,
            border_width: 0,
            deletable: true,
            resizable: true,
            modal: true
        );
    }

    construct {
        transient_for = window;
        default_width = 800;

        var column_start = new Gtk.Grid ();
        column_start.column_spacing = 12;
        column_start.row_spacing = 12;
        column_start.hexpand = true;
        column_start.column_homogeneous = true;

        column_start.attach (new Granite.HeaderLabel (_("General")), 0, 0, 2);
        column_start.attach (new NameLabel (_("New window:")), 0, 1);
        column_start.attach (new ShortcutLabel ({"Ctrl", "N"}), 1, 1);
        column_start.attach (new NameLabel (_("Preferences:")), 0, 2);
        column_start.attach (new ShortcutLabel ({"Ctrl", ","}), 1, 2);
        column_start.attach (new NameLabel (_("Quit:")), 0, 3);
        column_start.attach (new ShortcutLabel ({"Ctrl", "Q"}), 1, 3);
        column_start.attach (new NameLabel (_("Presentation Mode:")), 0, 4);
        column_start.attach (new ShortcutLabel ({"Ctrl", "."}), 1, 4);

        column_start.attach (new Granite.HeaderLabel (_("File")), 0, 5, 2);
        column_start.attach (new NameLabel (_("Open:")), 0, 6);
        column_start.attach (new ShortcutLabel ({"Ctrl", "O"}), 1, 6);
        column_start.attach (new NameLabel (_("Save:")), 0, 7);
        column_start.attach (new ShortcutLabel ({"Ctrl", "S"}), 1, 7);
        column_start.attach (new NameLabel (_("Save As:")), 0, 8);
        column_start.attach (new ShortcutLabel ({"Ctrl", "Shift", "S"}), 1, 8);

        column_start.attach (new Granite.HeaderLabel (_("Export")), 0, 9, 2);
        column_start.attach (new NameLabel (_("Export Artboards:")), 0, 10);
        column_start.attach (new ShortcutLabel ({"Ctrl", "Alt", "A"}), 1, 10);
        column_start.attach (new NameLabel (_("Export Selection:")), 0, 11);
        column_start.attach (new ShortcutLabel ({"Ctrl", "Alt", "E"}), 1, 11);
        column_start.attach (new NameLabel (_("Highlight Area to Export:")), 0, 12);
        column_start.attach (new ShortcutLabel ({"Ctrl", "Alt", "G"}), 1, 12);

        var column_end = new Gtk.Grid ();
        column_end.column_spacing = 12;
        column_end.row_spacing = 12;
        column_end.hexpand = true;
        column_end.column_homogeneous = true;

        column_end.attach (new Granite.HeaderLabel (_("Canvas")), 0, 0, 2);
        column_end.attach (new NameLabel (_("Zoom in:")), 0, 1);
        column_end.attach (new ShortcutLabel ({"Ctrl", "+"}), 1, 1);
        column_end.attach (new NameLabel (_("Zoom out:")), 0, 2);
        column_end.attach (new ShortcutLabel ({"Ctrl", "-"}), 1, 2);
        column_end.attach (new NameLabel (_("Zoom reset:")), 0, 3);
        column_end.attach (new ShortcutLabel ({"Ctrl", "0"}), 1, 3);

        column_end.attach (new Granite.HeaderLabel (_("Item creation")), 0, 4, 2);
        column_end.attach (new NameLabel (_("Artboard:")), 0, 5);
        column_end.attach (new ShortcutLabel ({"A"}), 1, 5);
        column_end.attach (new NameLabel (_("Rectangle:")), 0, 6);
        column_end.attach (new ShortcutLabel ({"R"}), 1, 6);
        column_end.attach (new NameLabel (_("Ellipse:")), 0, 7);
        column_end.attach (new ShortcutLabel ({"E"}), 1, 7);
        column_end.attach (new NameLabel (_("Text:")), 0, 8);
        column_end.attach (new ShortcutLabel ({"T"}), 1, 8);
        column_end.attach (new NameLabel (_("Image:")), 0, 9);
        column_end.attach (new ShortcutLabel ({"I"}), 1, 9);

        column_end.attach (new Granite.HeaderLabel (_("Transform")), 0, 10, 2);
        column_end.attach (new NameLabel (_("Raise selection:")), 0, 11);
        column_end.attach (new ShortcutLabel ({"Ctrl", "↑"}), 1, 11);
        column_end.attach (new NameLabel (_("Lower selection:")), 0, 12);
        column_end.attach (new ShortcutLabel ({"Ctrl", "↓"}), 1, 12);
        column_end.attach (new NameLabel (_("Raise selection to top:")), 0, 13);
        column_end.attach (new ShortcutLabel ({"Ctrl", "Shift", "↑"}), 1, 13);
        column_end.attach (new NameLabel (_("Lower selection to bottom:")), 0, 14);
        column_end.attach (new ShortcutLabel ({"Ctrl", "Shift", "↓"}), 1, 14);
        column_end.attach (new NameLabel (_("Flip horizontally:")), 0, 15);
        column_end.attach (new ShortcutLabel ({"Ctrl", "["}), 1, 15);
        column_end.attach (new NameLabel (_("Flip vertically:")), 0, 16);
        column_end.attach (new ShortcutLabel ({"Ctrl", "]"}), 1, 16);

        var grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.hexpand = true;
        grid.attach (column_start, 0, 0);
        grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0);
        grid.attach (column_end, 2, 0);

        var content_area = get_content_area ();
        content_area.border_width = 12;
        content_area.add (grid);
    }

    private class NameLabel : Gtk.Label {
        public NameLabel (string label) {
            Object (
                label: label
            );
        }

        construct {
            halign = Gtk.Align.END;
            xalign = 1;
        }
    }

    private class ShortcutLabel : Gtk.Grid {
        public string[] accels { get; set construct; }

        public ShortcutLabel (string[] accels) {
            Object (accels: accels);
        }

        construct {
            column_spacing = 6;

            foreach (unowned string accel in accels) {
                if (accel == "") {
                    continue;
                }
                var label = new Gtk.Label (accel);
                label.get_style_context ().add_class ("keycap");
                add (label);
            }
            halign = Gtk.Align.START;
        }
    }
}

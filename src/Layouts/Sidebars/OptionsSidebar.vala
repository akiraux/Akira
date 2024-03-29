/*
* Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Sidebars.OptionsSidebar : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public Layouts.FillsList.FillsPanel fills_panel;
    public Layouts.BordersList.BordersPanel borders_panel;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public OptionsSidebar (Lib.ViewCanvas view_canvas) {
        Object (
            view_canvas: view_canvas
        );
    }

    construct {
        get_style_context ().add_class ("sidebar-l");

        // The alignment panel is the only widget that doesn't scroll.
        attach (new Layouts.Alignment.AlignmentPanel (view_canvas), 0, 0);

        var main_scroll = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            expand = true
        };

        fills_panel = new Layouts.FillsList.FillsPanel (view_canvas);
        borders_panel = new Layouts.BordersList.BordersPanel (view_canvas);

        var main_grid = new Gtk.Grid ();
        main_grid.attach (new Layouts.Transforms.TransformPanel (view_canvas), 0, 0);
        main_grid.attach (fills_panel, 0, 1);
        main_grid.attach (borders_panel, 0, 2);

        main_scroll.add (main_grid);
        attach (main_scroll, 0, 1);

        // Connect signals.
        view_canvas.window.event_bus.toggle_presentation_mode.connect (toggle);
    }

    private void toggle () {
        toggled = !toggled;
    }
}

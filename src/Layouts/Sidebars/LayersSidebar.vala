/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * Layout component containing the layers and pages containers.
 */
public class Akira.Layouts.Sidebars.LayersSidebar : Gtk.Grid {
    public unowned Lib2.ViewCanvas view_canvas { get; construct; }

    /*
     * Boolean attribute to show/hide the layers sidebar when requested for the
     * presentation mode option byt the user.
     */
    private bool toggled {
        get {
            return visible;
        }
        set {
            visible = value;
            no_show_all = !value;
        }
    }

    // Drag and Drop properties.
    private Gtk.Revealer motion_revealer;
    private Gtk.TargetList drop_targets;
    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 },
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

    public Layouts.Sidebars.Partials.LayersPanel layers_panel;
    public Gtk.ScrolledWindow layers_scroll;

    public LayersSidebar (Lib2.ViewCanvas canvas) {
        Object (
            orientation: Gtk.Orientation.VERTICAL,
            view_canvas: canvas
        );
    }

    construct {
        get_style_context ().add_class ("sidebar-r");
        width_request = 220;

        drop_targets = new Gtk.TargetList (TARGET_ENTRIES);

        var pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        pane.expand = true;
        pane.wide_handle = false;
        pane.position = 600;

        layers_panel = new Layouts.Sidebars.Partials.LayersPanel (view_canvas);
        var layers_grid = new Gtk.Grid ();
        layers_grid.vexpand = true;
        layers_grid.add (layers_panel);

        layers_scroll = new Gtk.ScrolledWindow (null, null);
        layers_scroll.expand = true;
        layers_scroll.add (layers_grid);

        var scrolled_child = layers_scroll.get_child ();
        if (scrolled_child is Gtk.Container) {
           ((Gtk.Container) scrolled_child).set_focus_vadjustment (
               new Gtk.Adjustment (0, 0, 0, 0, 0, 0)
            );
        }

        // Motion revealer for Drag and Drop on the top search bar.
        var motion_grid = new Gtk.Grid ();
        motion_grid.get_style_context ().add_class ("grid-motion");
        motion_grid.height_request = 2;

        motion_revealer = new Gtk.Revealer ();
        motion_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        motion_revealer.add (motion_grid);

        var top_panel = new Gtk.Grid ();
        top_panel.attach (build_search_bar (), 0, 0, 1, 1);
        top_panel.attach (motion_revealer, 0, 1, 1, 1);
        top_panel.attach (layers_scroll, 0, 2, 1, 1);

        pane.pack1 (top_panel, false, false);

        attach (pane, 0 , 0 , 1, 1);

        // Connect signals.
        view_canvas.window.event_bus.toggle_presentation_mode.connect (toggle);
    }

    private Gtk.Grid build_search_bar () {
        var search = new Gtk.SearchEntry ();
        search.hexpand = true;
        search.margin = 5;
        search.placeholder_text = _("Search Layers");

        search.focus_in_event.connect (handle_focus_in);
        search.focus_out_event.connect (handle_focus_out);

        var search_grid = new Gtk.Grid ();
        search_grid.get_style_context ().add_class ("border-bottom");
        search_grid.add (search);

        return search_grid;
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        view_canvas.window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        view_canvas.window.event_bus.connect_typing_accel ();
        return false;
    }

    /*
     * Toggle the visibility of the entire panel.
     */
    private void toggle () {
        toggled = !toggled;
    }
}

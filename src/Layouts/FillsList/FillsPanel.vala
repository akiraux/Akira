/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.Layouts.FillsList.FillsPanel : Gtk.Grid {
    public unowned Akira.Lib.ViewCanvas view_canvas { get; construct; }

    public FillListBox fills_listbox;

    public FillsPanel (Akira.Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        var title_cont = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            hexpand = true
        };
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Fills")) {
            halign = Gtk.Align.FILL,
            xalign = 0,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var add_btn = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _("Add fill color")
        };
        add_btn.clicked.connect (add_fill);
        add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_btn, 1, 0, 1, 1);

        attach (title_cont, 0, 0, 1, 1);

        fills_listbox = new FillListBox (view_canvas);

        var scrolled_window = new Gtk.ScrolledWindow (null, null) {
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
            expand = false,
            margin = 3
        };
        scrolled_window.add (fills_listbox);
        attach (scrolled_window, 0, 1, 1, 1);

        // Show the widget by default.
        show_all ();
        // But then hide it right after so we can toggle it.
        visible = false;
        no_show_all = true;

        view_canvas.window.event_bus.selection_modified.connect (on_selection_modified);
    }

    private void on_selection_modified () {
        unowned var sm = view_canvas.selection_manager;
        bool is_visible = sm.count () > 0;

        visible = is_visible;
        no_show_all = !is_visible;

        fills_listbox.refresh_list ();
    }

    private void add_fill () {
        unowned var sm = view_canvas.selection_manager;
        if (sm.count () == 0) {
            return;
        }

        var fill_rgba = Gdk.RGBA ();
        fill_rgba.parse (settings.fill_color);
        var color = Lib.Components.Color.from_rgba (fill_rgba);

        unowned var im = _view_canvas.items_manager;
        foreach (var selected in sm.selection.nodes.values) {
            var new_fills = selected.node.instance.components.fills.copy ();
            new_fills.append_fill_with_color (color);
            selected.node.instance.components.fills = new_fills;
            im.item_model.alert_node_changed (selected.node, Lib.Components.Component.Type.COMPILED_FILL);
        }
        im.compile_model ();
        fills_listbox.refresh_list ();
    }
}

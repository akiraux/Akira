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

public class Akira.Layouts.BordersList.BordersPanel : Gtk.Grid {
    public unowned Lib.ViewCanvas view_canvas { get; construct; }

    public BorderListBox borders_listbox;

    public BordersPanel (Lib.ViewCanvas canvas) {
        Object (
            view_canvas: canvas
        );

        var title_cont = new Gtk.Grid () {
            orientation = Gtk.Orientation.HORIZONTAL,
            hexpand = true
        };
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Borders")) {
            halign = Gtk.Align.FILL,
            xalign = 0,
            hexpand = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        var add_btn = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR) {
            can_focus = false,
            valign = Gtk.Align.CENTER,
            halign = Gtk.Align.CENTER,
            tooltip_text = _("Add border color")
        };
        add_btn.clicked.connect (add_border);
        add_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_btn, 1, 0, 1, 1);

        attach (title_cont, 0, 0, 1, 1);

        borders_listbox = new BorderListBox (view_canvas);
        attach (borders_listbox, 0, 1, 1, 1);

        // Show the widget by default.
        show_all ();
        // But then hide it right after so we can toggle it.
        visible = false;
        no_show_all = true;

        view_canvas.window.event_bus.selection_modified.connect (on_selection_modified);
    }

    private void on_selection_modified () {
        unowned var sm = view_canvas.selection_manager;

        bool is_visible = false;
        foreach (var selected in sm.selection.nodes.values) {
            // Show the borders panel only if at least one item is not an artboard.
            if (!selected.node.instance.is_artboard) {
                is_visible = true;
                break;
            }
        }

        visible = is_visible;
        no_show_all = !is_visible;

        if (is_visible) {
            borders_listbox.refresh_list ();
        }
    }

    private void add_border () {
        unowned var sm = view_canvas.selection_manager;
        if (sm.count () == 0) {
            return;
        }

        var border_rgba = Gdk.RGBA ();
        border_rgba.parse (settings.border_color);
        var color = Lib.Components.Color.from_rgba (border_rgba);

        unowned var im = _view_canvas.items_manager;
        foreach (var selected in sm.selection.nodes.values) {
            // Don't add borders for Artboards.
            if (selected.node.instance.is_artboard) {
                continue;
            }

            unowned var old_borders = selected.node.instance.components.borders;
            Lib.Components.Borders? new_borders = (old_borders == null) ? null : old_borders.copy ();
            double? size = null;
            if (new_borders == null) {
                new_borders = new Lib.Components.Borders ();
                size = settings.border_size;
            }

            new_borders.append_border_with_color (color, size);
            selected.node.instance.components.borders = new_borders;
            im.item_model.alert_node_changed (selected.node, Lib.Components.Component.Type.COMPILED_BORDER);
        }
        im.compile_model ();
        borders_listbox.refresh_list ();
    }
}

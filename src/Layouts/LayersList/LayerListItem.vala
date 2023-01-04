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
 * Adapted from the elementary OS Mail's VirtualizingListBox source code created
 * by David Hewitt <davidmhewitt@gmail.com>
 */

/*
 * The single layer row.
 */
public class Akira.Layouts.LayersList.LayerListItem : VirtualizingListBoxRow {
    private LayerItemModel model;

    private Gtk.StyleContext style_ctx;
    // Main grid to attach all other grid widgets.
    private Gtk.Grid grid_main;
    // Grid to collect the label and entry widgets.
    private Gtk.Grid grid_entry;
    // Grid to collect the hide and lock action buttons.
    private Gtk.Grid grid_action;

    public Gtk.Entry entry;
    private Gtk.Label label;
    private Gtk.Image icon;
    private Gtk.Button btn_lock;
    private Gtk.Button btn_view;
    private Gtk.Button btn_toggle;

    private bool _is_editing = false;
    public bool is_editing {
        get {
            return _is_editing;
        }
        set {
            _is_editing = value;
            if (value) {
                grid_action.visible = false;
                return;
            }

            grid_action.visible = true;
        }
    }

    construct {
        style_ctx = get_style_context ();

        btn_toggle = new Gtk.Button.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU) {
            tooltip_text = _("Toggle visibility of child layers"),
            can_focus = false
        };
        btn_toggle.clicked.connect (on_toggle_pressed);
        btn_toggle.get_style_context ().add_class ("flat");
        btn_toggle.get_style_context ().add_class ("button-toggle");
        btn_toggle.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        icon = new Gtk.Image () {
            margin_end = 9,
            vexpand = true,
            valign = Gtk.Align.CENTER
        };
        icon.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

        label = new Gtk.Label (null) {
            halign = Gtk.Align.FILL,
            xalign = 0,
            expand = true,
            ellipsize = Pango.EllipsizeMode.END
        };

        grid_entry = new Gtk.Grid ();
        grid_entry.attach (label, 0, 0, 1, 1);

        btn_lock = new Gtk.Button.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.MENU) {
            tooltip_text = _("Lock layer"),
            can_focus = false
        };
        btn_lock.clicked.connect (toggle_lock);
        btn_lock.get_style_context ().add_class ("flat");

        btn_view = new Gtk.Button.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU) {
            tooltip_text = _("Hide layer"),
            can_focus = false
        };
        btn_view.clicked.connect (toggle_view);
        btn_view.get_style_context ().add_class ("flat");

        grid_action = new Gtk.Grid () {
            margin_end = 6,
            vexpand = true,
            valign = Gtk.Align.CENTER
        };
        grid_action.get_style_context ().add_class ("actions");
        grid_action.attach (btn_lock, 0, 0, 1, 1);
        grid_action.attach (btn_view, 1, 0, 1, 1);

        grid_main = new Gtk.Grid () {
            vexpand = true,
            valign = Gtk.Align.CENTER
        };
        grid_main.attach (icon, 0, 0, 1, 1);
        grid_main.attach (btn_toggle, 1, 0, 1, 1);
        grid_main.attach (grid_entry, 2, 0, 1, 1);
        grid_main.attach (grid_action, 3, 0, 1, 1);

        add (grid_main);
    }

    public void assign (LayerItemModel data) {
        model_item = data;
        model = (LayerItemModel) model_item;

        label.label = model.name;

        // Build a specific UI based on the node instance's type.
        if (data.is_artboard) {
            build_artboard_ui ();
        } else if (data.is_group) {
            build_group_ui ();
        } else {
            build_layer_ui ();
        }

        // Update the state of the action buttons to reflect the model state.
        update_btn_lock ();

        // Indent child layers based on the amount of ancestors.
        grid_main.margin_start = 12 * model.ancestors_size;
    }

    private void build_artboard_ui () {
        // Update the general UI.
        style_ctx.remove_class ("layer");
        style_ctx.remove_class ("group");
        style_ctx.add_class ("artboard");

        // Update icon.
        icon.clear ();
        icon.margin_start = 0;

        // Show the toggle button.
        btn_toggle.no_show_all = false;
        btn_toggle.visible = true;
        update_btn_toggle ();
    }

    private void build_group_ui () {
        // Update the general UI.
        style_ctx.remove_class ("layer");
        style_ctx.remove_class ("artboard");
        style_ctx.add_class ("group");

        // Update icon.
        icon.clear ();
        icon.margin_start = 0;

        // Show the toggle button.
        btn_toggle.no_show_all = false;
        btn_toggle.visible = true;

        update_btn_toggle ();
    }

    private void build_layer_ui () {
        // Update general UI.
        style_ctx.remove_class ("artboard");
        style_ctx.remove_class ("group");
        style_ctx.add_class ("layer");

        // Update icon.
        icon.set_from_icon_name (model.icon, Gtk.IconSize.MENU);
        icon.margin_start = 12;

        // Hide the toggle button.
        btn_toggle.no_show_all = true;
        btn_toggle.visible = false;
    }

    public override void edit () {
        if (entry != null) {
            show_entry ();
            return;
        }

        entry = new Gtk.Entry () {
            expand = true,
            margin_end = 6
        };
        entry.get_style_context ().add_class ("flat");

        grid_entry.attach (entry, 0, 1, 1, 1);

        show_entry ();
    }

    /*
     * The user pressed `Enter` on the layer's entry, so we trigger the update
     * of the layer's name.
     */
    public void update_label () {
        // Trigger the model update.
        model.name = entry.text;
        // Update the visible label with the new model.name, so we're sure the
        // update took effect.
        label.label = model.name;
    }

    private void show_entry () {
        entry.text = label.label;
        entry.visible = true;
        entry.no_show_all = false;
        label.visible = false;
        label.no_show_all = true;
        entry.grab_focus ();
        is_editing = true;
    }

    public override void edit_end () {
        entry.visible = false;
        entry.no_show_all = true;
        label.visible = true;
        label.no_show_all = false;
        is_editing = false;
    }

    private void toggle_lock () {
        model.locked = !model.locked;
        update_btn_lock ();
    }

    private void update_btn_lock () {
        if (model.locked) {
            btn_lock.get_style_context ().add_class ("active");
            btn_lock.image = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.MENU);
            btn_lock.tooltip_text = _("Unlock layer");
            selectable = false;
        } else {
            btn_lock.get_style_context ().remove_class ("active");
            btn_lock.image = new Gtk.Image.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.MENU);
            btn_lock.tooltip_text = _("Lock layer");
            selectable = true;
        }
    }

    // TODO.
    private void toggle_view () {
        print ("view pressed\n");
    }

    /*
     * Hide or show the child layers of this layer when the user clicks on the
     * toggle button.
     */
    private void on_toggle_pressed () {
        model.children_visible = !model.children_visible;
        update_btn_toggle ();
    }

    /*
     * Visually update the toggle button.
     */
    private void update_btn_toggle () {
        if (model.children_visible) {
            btn_toggle.get_style_context ().remove_class ("collapsed");
        } else {
            btn_toggle.get_style_context ().add_class ("collapsed");
        }
    }
}

/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.Artboard : Gtk.ListBoxRow {
    public weak Akira.Window window { get; construct; }

    private const Gtk.TargetEntry TARGET_ENTRIES[] = {
        { "ARTBOARD", Gtk.TargetFlags.SAME_APP, 0 }
    };

    private const Gtk.TargetEntry TARGET_ENTRIES_LAYER[] = {
        { "LAYER", Gtk.TargetFlags.SAME_APP, 0 }
    };

    public Gtk.Label label;
    public Gtk.Entry entry;
    public Gtk.EventBox handle;
    public Gtk.Image icon_locked;
    public Gtk.Image icon_unlocked;
    public Gtk.Image icon_hidden;
    public Gtk.Image icon_visible;
    public Gtk.ToggleButton button_locked;
    public Gtk.ToggleButton button_hidden;
    public Gtk.ToggleButton button;
    public Gtk.Image button_icon;
    public Gtk.Revealer revealer;
    public Gtk.ListBox container;
    public int layers_count { get; set; default = 0; }

    public Akira.Models.LayerModel model { get; construct; }

    private bool _editing { get; set; default = false; }
    public bool editing {
        get { return _editing; } set { _editing = value; }
    }

    public Artboard (Akira.Window window, Akira.Models.LayerModel model) {
        Object (
            window: window,
            model: model
        );
    }

    construct {
        get_style_context ().add_class ("artboard");

        label = new Gtk.Label (model.name);
        label.get_style_context ().add_class ("artboard-name");
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        entry = new Gtk.Entry ();
        entry.expand = true;
        entry.visible = false;
        entry.no_show_all = true;
        entry.set_text (model.name);
        entry.focus_in_event.connect (handle_focus_in);
        entry.focus_out_event.connect (handle_focus_out);

        entry.activate.connect (update_on_enter);
        entry.focus_out_event.connect (update_on_leave);
        entry.key_release_event.connect (update_on_escape);

        var label_grid = new Gtk.Grid ();
        label_grid.expand = true;
        label_grid.attach (label, 0, 0, 1, 1);
        label_grid.attach (entry, 1, 0, 1, 1);

        revealer = new Gtk.Revealer ();
        revealer.hexpand = true;
        revealer.reveal_child = true;

        container = new Gtk.ListBox ();
        container.get_style_context ().add_class ("artboard-container");
        container.activate_on_single_click = false;
        container.selection_mode = Gtk.SelectionMode.SINGLE;
        Gtk.drag_dest_set (container, Gtk.DestDefaults.ALL, TARGET_ENTRIES_LAYER, Gdk.DragAction.MOVE);
        container.drag_data_received.connect (on_drag_data_received);
        revealer.add (container);

        handle = new Gtk.EventBox ();
        handle.hexpand = true;
        handle.add (label_grid);
        handle.event.connect (on_click_event);

        button_locked = new Gtk.ToggleButton ();
        button_locked.tooltip_text = _("Lock Layer");
        button_locked.get_style_context ().remove_class ("button");
        button_locked.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button_locked.get_style_context ().add_class ("layer-action");
        button_locked.valign = Gtk.Align.CENTER;
        icon_locked = new Gtk.Image.from_icon_name ("changes-allow-symbolic", Gtk.IconSize.MENU);
        icon_unlocked = new Gtk.Image.from_icon_name ("changes-prevent-symbolic", Gtk.IconSize.MENU);
        icon_unlocked.visible = false;
        icon_unlocked.no_show_all = true;

        button_hidden = new Gtk.ToggleButton ();
        button_hidden.tooltip_text = _("Hide Layer");
        button_hidden.get_style_context ().remove_class ("button");
        button_hidden.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button_hidden.get_style_context ().add_class ("layer-action");
        button_hidden.valign = Gtk.Align.CENTER;
        icon_hidden = new Gtk.Image.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU);
        icon_visible = new Gtk.Image.from_icon_name ("layer-hidden-symbolic", Gtk.IconSize.MENU);
        icon_visible.visible = false;
        icon_visible.no_show_all = true;

        var button_locked_grid = new Gtk.Grid ();
        button_locked_grid.margin_end = 6;
        button_locked_grid.attach (icon_locked, 0, 0, 1, 1);
        button_locked_grid.attach (icon_unlocked, 1, 0, 1, 1);

        var button_hidden_grid = new Gtk.Grid ();
        button_hidden_grid.margin_end = 14;
        button_hidden_grid.attach (icon_hidden, 0, 0, 1, 1);
        button_hidden_grid.attach (icon_visible, 1, 0, 1, 1);

        button_hidden.add (button_hidden_grid);
        button_locked.add (button_locked_grid);

        button = new Gtk.ToggleButton ();
        button.active = true;
        button.get_style_context ().remove_class ("button");
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button.get_style_context ().add_class ("revealer-button");
        button_icon = new Gtk.Image.from_icon_name ("pan-down-symbolic", Gtk.IconSize.MENU);
        button.add (button_icon);

        var artboard_handle = new Gtk.Grid ();
        artboard_handle.get_style_context ().add_class ("artboard-handle");
        artboard_handle.attach (handle, 0, 0, 1, 1);
        artboard_handle.attach (button_locked, 1, 0, 1, 1);
        artboard_handle.attach (button_hidden, 2, 0, 1, 1);
        artboard_handle.attach (button, 3, 0, 1, 1);

        var grid = new Gtk.Grid ();
        grid.attach (artboard_handle, 0, 0, 1, 1);
        grid.attach (revealer, 0, 1, 1, 1);

        add (grid);

        get_style_context ().add_class ("artboard");

        build_drag_and_drop ();

        button.toggled.connect (() => {
            revealer.reveal_child = ! revealer.get_reveal_child ();

            if (revealer.get_reveal_child ()) {
                button.get_style_context ().remove_class ("closed");
            } else {
                button.get_style_context ().add_class ("closed");
            }
        });

        model.item.notify["selected"].connect (() => {
            if (model.selected) {
              activate ();
              return;
            }

            (parent as Gtk.ListBox).unselect_row (this);
        });

        handle.enter_notify_event.connect (event => {
            get_style_context ().add_class ("hover");
            return false;
        });

        handle.leave_notify_event.connect (event => {
            get_style_context ().remove_class ("hover");
            return false;
        });

        container.bind_model (model.items, item => {
            // TODO: Differentiate between layer and artboard
            // based upon item "type" of some sort
            var layer_model = (Akira.Models.LayerModel) item;

            return new Akira.Layouts.Partials.Layer (window, layer_model);
        });
    }

    private void on_drag_data_received (Gdk.DragContext context, int x, int y, Gtk.SelectionData selection_data,
        uint target_type, uint time) {
        window.main_window.right_sidebar.indicator.visible = false;

        Akira.Layouts.Partials.Layer target;
        Gtk.Widget row;
        Akira.Layouts.Partials.Layer source;
        int new_position;
        var before_group = false;

        target = (Akira.Layouts.Partials.Layer) container.get_row_at_y (y);
        row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Akira.Layouts.Partials.Layer) row.get_ancestor (typeof (Akira.Layouts.Partials.Layer));
        int index = target.get_index ();
        Gtk.Allocation alloc;

        if (target == null) {
            new_position = -1;
        } else if (target.grouped && source.layer_group == null) {
            source.get_allocation (out alloc);
            y = y - (index * alloc.height);

            var group = (Akira.Layouts.Partials.Layer) target.container.get_row_at_y (y);

            if (group is Akira.Layouts.Partials.Layer) {
                new_position = group.get_index ();
            } else {
                new_position = -1;
            }

            if ((y + alloc.height) < (alloc.height / 2)) {
                new_position = target.get_index () > 1 && source.get_index () > new_position ?
                    target.get_index () - 1 : target.get_index ();
                debug ("Layer dropped ABOVE group: %i", new_position);
                before_group = true;
            } else {
                before_group = false;
                debug ("Layer dropped INSIDE a group from OUTSIDE: %i", new_position);

                if (y > ((new_position * alloc.height) - (alloc.height / 2)) && new_position > 1) {
                    debug ("drop below");
                    new_position++;
                }
            }
        } else if (target.grouped && source.layer_group != null) {
            source.get_allocation (out alloc);
            y = y - (index * alloc.height);

            var group = (Akira.Layouts.Partials.Layer) target.container.get_row_at_y (y);

            if (group is Akira.Layouts.Partials.Layer) {
                new_position = group.get_index ();
            } else {
                new_position = -1;
            }

            if ((y + alloc.height) < (alloc.height / 2)) {
                new_position = target.get_index () > 1 && source.get_index () > new_position ?
                    target.get_index () - 1 : target.get_index ();
                debug ("Layer dropped ABOVE group: %i", new_position);
                before_group = true;
            } else {
                before_group = false;
                debug ("%i", y);
                debug ("%i", new_position);
                debug ("%i", (new_position * alloc.height) - (alloc.height / 2));

                if (y > ((new_position * alloc.height) - (alloc.height / 2)) && source.get_index () > new_position) {
                    debug ("dropped below");
                    new_position++;
                } else if (y <= ((new_position * alloc.height) - (alloc.height / 2))
                    && source.get_index () < new_position) {
                    debug ("dropped above");
                    new_position--;
                }
                debug ("Layer dropped WHITIN group: %i", new_position);
            }
        } else if (!target.grouped && source.layer_group != null) {
            var parent = (Akira.Layouts.Partials.Artboard) target.get_ancestor (
                typeof (Akira.Layouts.Partials.Artboard));
            var group = parent.container.get_row_at_y (y);
            group.get_allocation (out alloc);

            if (group is Akira.Layouts.Partials.Layer) {
                new_position = group.get_index ();
            } else {
                new_position = -1;
            }

            if (y > ((new_position * alloc.height) - (alloc.height / 2))) {
                debug ("drop below");
                new_position++;
            }

            debug ("Layer dropped OUTSIDE from INSIDE a group: %i", new_position);
        } else {
            target.get_allocation (out alloc);
            new_position = target.get_index ();

            if (y <= ((new_position * alloc.height) - (alloc.height / 2))
                && new_position > 1 && source.get_index () < new_position) {
                new_position--;
            }
            debug ("Layer dropped: %i", new_position);
        }

        if (source == target) {
            return;
        }

        if (source.layer_group != null) {
            source.layer_group.container.remove (source);
            source.layer_group = null;
        } else {
            container.remove (source);
        }

        if (before_group) {
            container.insert (source, new_position);
        } else if (target.grouped && source.layer_group == null) {
            source.layer_group = target;
            target.container.insert (source, new_position);
        } else if (target.grouped && source.layer_group != null) {
            source.layer_group = target;
            target.container.insert (source, new_position);
        } else if (!target.grouped && source.layer_group != null) {
            source.layer_group = null;
            container.insert (source, new_position);
        } else {
            container.insert (source, new_position);
        }

        window.main_window.right_sidebar.layers_panel.reload_zebra ();
        show_all ();
    }

    private void build_drag_and_drop () {
        Gtk.drag_source_set (this, Gdk.ModifierType.BUTTON1_MASK, TARGET_ENTRIES, Gdk.DragAction.MOVE);

        drag_begin.connect (on_drag_begin);
        drag_data_get.connect (on_drag_data_get);

        drag_leave.connect (on_drag_leave);
    }

    private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        var row = (Akira.Layouts.Partials.Artboard) widget.get_ancestor (typeof (Akira.Layouts.Partials.Artboard));
        Gtk.Allocation alloc;
        row.get_allocation (out alloc);

        var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (0, 0, 0, 0.3);
        cr.set_line_width (1);

        cr.move_to (0, 0);
        cr.line_to (alloc.width, 0);
        cr.line_to (alloc.width, alloc.height);
        cr.line_to (0, alloc.height);
        cr.line_to (0, 0);
        cr.stroke ();

        cr.set_source_rgba (255, 255, 255, 0.5);
        cr.rectangle (0, 0, alloc.width, alloc.height);
        cr.fill ();

        row.draw (cr);

        Gtk.drag_set_icon_surface (context, surface);
    }

    private void on_drag_data_get (Gtk.Widget widget, Gdk.DragContext context, Gtk.SelectionData selection_data,
        uint target_type, uint time) {
        uchar[] data = new uchar[(sizeof (Akira.Layouts.Partials.Artboard))];
        ((Gtk.Widget[])data)[0] = widget;

        selection_data.set (
            Gdk.Atom.intern_static_string ("ARTBOARD"), 32, data
        );
    }

    public void on_drag_leave (Gdk.DragContext context, uint time) {
        get_style_context ().remove_class ("highlight");
        window.main_window.right_sidebar.indicator.visible = false;
    }

    public bool on_click_event (Gdk.Event event) {
        if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
            entry.visible = true;
            entry.no_show_all = false;
            label.visible = false;
            label.no_show_all = true;

            editing = true;

            Timeout.add (200, () => {
                entry.grab_focus ();
                return false;
            });
        }

        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            window.event_bus.request_add_item_to_selection (model.item);

            return true;
        }

        return false;
    }

    private bool delete_object () {
        if (is_selected () && !editing) {
            window.main_window.right_sidebar.layers_panel.remove (this);

            return true;
        }

        var layers = container.get_selected_rows ();

        check_delete_object (layers);

        container.foreach (child => {
            if (child is Akira.Layouts.Partials.Layer) {
                Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) child;
                if (layer.grouped) {
                    check_delete_object (layer.container.get_selected_rows ());
                }
            }
        });

        window.main_window.right_sidebar.layers_panel.reload_zebra ();

        return true;
    }

    public void check_delete_object (GLib.List<weak Gtk.ListBoxRow> layers) {
        layers.foreach (row => {
            Akira.Layouts.Partials.Layer layer = (Akira.Layouts.Partials.Layer) row;
            do_delete_object (layer);

            if (layer.grouped) {
                check_delete_object (layer.container.get_selected_rows ());
            }
        });
    }

    public void do_delete_object (Akira.Layouts.Partials.Layer layer) {
        if (layer.is_selected () && !layer.editing) {
            if (layer.layer_group != null) {
                layer.layer_group.container.remove (layer);
            } else {
                container.remove (layer);
            }
        }
    }

    public void update_on_enter () {
        update_label ();
    }

    public bool update_on_leave () {
        update_label ();
        return false;
    }

    public bool update_on_escape (Gdk.EventKey key) {
        if (key.keyval == Gdk.Key.Escape) {
            entry.text = label.label;

            update_label ();
        }
        return false;
    }

    private void update_label () {
        entry.visible = false;
        entry.no_show_all = true;
        label.visible = true;
        label.no_show_all = false;

        editing = false;

        var new_label = entry.get_text ();

        if (label.label == new_label) {
            return;
        }

        label.label = model.name = new_label;

        window.event_bus.set_focus_on_canvas ();
    }

    public void count_layers () {
        layers_count = 0;

        container.foreach (child => {
            if (child is Akira.Layouts.Partials.Layer) {
                layers_count++;
            }
        });
    }

    private bool handle_focus_in (Gdk.EventFocus event) {
        window.event_bus.disconnect_typing_accel ();
        return false;
    }

    private bool handle_focus_out (Gdk.EventFocus event) {
        window.event_bus.connect_typing_accel ();
        return false;
    }
}

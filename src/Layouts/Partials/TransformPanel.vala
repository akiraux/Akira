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
* Authored by: Ana Gelez <ana@gelez.xyz>
*/
public class Akira.Layouts.Partials.TransformPanel : Gtk.Grid {
    // Should probably be associated with the currently selected object
    // once the canvas is working
    public bool size_lock { get; set; default = false; }
    
    double size_ratio = 1.0;
    
    construct {
        border_width = 12;
        row_spacing = 6;
        column_spacing = 6;
        hexpand = true;
        
        var width = new Akira.Partials.LinkedInput (C_("The first letter of Width", "W"));
        var height = new Akira.Partials.LinkedInput (C_("The first letter of Height", "H"));
        width.notify["value"].connect (() => {
            if (size_lock) {
                height.value = width.value / size_ratio;
            } else {
                size_ratio = width.value / height.value;
            }
        });
        height.notify["value"].connect (() => {
            if (size_lock) {
                width.value = height.value * size_ratio;
            } else {
                size_ratio = width.value / height.value;
            }
        });
        
        var lock_changes = new Gtk.Button.from_icon_name ("changes-allow-symbolic");
        lock_changes.can_focus = false;
        lock_changes.tooltip_text = _("Keep Ratio");
        lock_changes.get_style_context ().add_class ("flat");
        bind_property (
            "size-lock", lock_changes, "image", BindingFlags.SYNC_CREATE,
            (binding, val, ref res) => {
                var icon = val.get_boolean() ? "changes-prevent-symbolic" : "changes-allow-symbolic";
                var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.BUTTON);
                res = image;
                return true;
            });
        lock_changes.clicked.connect (() => {
            size_lock = !size_lock;
        });
        
        var rotation = new Akira.Partials.LinkedInput (C_("The first letter of Rotation", "R"), "°");
        rotation.unit = "°";

        var hflip_button = new Gtk.Button.from_icon_name ("object-flip-horizontal", Gtk.IconSize.LARGE_TOOLBAR);
        hflip_button.get_style_context ().add_class ("flat");
        hflip_button.hexpand = false;
        hflip_button.halign = Gtk.Align.CENTER;
        hflip_button.can_focus = false;
        hflip_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketleft"}, _("Flip Horizontally"));

        var vflip_button = new Gtk.Button.from_icon_name ("object-flip-vertical", Gtk.IconSize.LARGE_TOOLBAR);
        vflip_button.get_style_context ().add_class ("flat");
        vflip_button.hexpand = false;
        vflip_button.halign = Gtk.Align.CENTER;
        vflip_button.can_focus = false;
        vflip_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl><Shift>bracketright"}, _("Flip Vertically"));

        var align_grid = new Gtk.Grid ();
        align_grid.hexpand = true;
        align_grid.column_homogeneous = true;
        align_grid.attach (hflip_button, 0, 0, 1, 1);
        align_grid.attach (vflip_button, 1, 0, 1, 1);
        
        var opacity = new Gtk.Adjustment (0, 0, 100, 0.5, 0, 0);
        var scale = new Gtk.Scale (Gtk.Orientation.HORIZONTAL, opacity);
        scale.hexpand = true;
        scale.draw_value = false;
        scale.sensitive = true;
        scale.round_digits = 1;
        var opacity_entry = new Akira.Partials.LinkedInput ("%", "", true);
        opacity_entry.bind_property (
            "value", opacity, "value", BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
        
        attach (group_title (_("Position")), 0, 0, 3);
        attach (new Akira.Partials.LinkedInput (C_("The horizontal coordinate", "X")), 0, 1, 1);
        attach (new Akira.Partials.LinkedInput (C_("The vertical coordinate", "Y")), 2, 1, 1);
        
        attach (group_title (_("Size")), 0, 2, 3);
        attach (width, 0, 3, 1);
        attach (lock_changes, 1, 3, 1);
        attach (height, 2, 3, 1);
        
        attach (group_title (_("Transform")), 0, 4, 3);
        attach (rotation, 0, 5, 1);
        attach (align_grid, 2, 5, 1);
        
        attach (group_title (_("Opacity")), 0, 6, 3);
        attach (scale, 0, 7, 2);
        attach (opacity_entry, 2, 7, 1);
    }
    
    private Gtk.Label group_title (string title) {
        var title_label = new Gtk.Label ("%s".printf (title));
        title_label.get_style_context ().add_class ("group-title");
        title_label.halign = Gtk.Align.START;
        title_label.margin_bottom = 2;
        return title_label;
    }
}

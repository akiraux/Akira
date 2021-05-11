/*
* Copyright (c) 2019 Alecaddd (https://alecaddd.com)
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
* Authored by: Abdallah "Abdallah-Moh" Mohammad <abdullah_mam1@icloud.com>
*/

public class Akira.Layouts.Partials.TextOptionsPanel : Gtk.Grid {
    public weak Akira.Window window { get; construct; }

    public Gtk.Label label;
    //  private Akira.Partials.InputField font_size_input;
    private Gtk.ComboBoxText font_weight;
    private Gtk.ComboBoxText selected_font;
    private Akira.Partials.InputField font_size_input;
    private Granite.Widgets.ModeButton scale_button;
    private Granite.Widgets.ModeButton align_scale_button;
    private string[] text_weights = {"Light", "Light Italic", "Thin", "Thin Italic", "Regular", "Regular Italic", "SemiBold", "SemiBold Italic", "Bold", "Bold Italic", "ExtraBold", "ExtraBold Italic",};
    public string [] fonts = Utils.Font.get_fonts ();

    private Akira.Lib.Items.CanvasText _selected_item;
    private Akira.Lib.Items.CanvasText selected_item {
        get {
            return _selected_item;
        } set {
            // If the same item is already selected, or the value is still null
            // we don't do anything to prevent redraw and calculations.
            if (_selected_item == value) {
                return;
            }

            _selected_item = value;

            if (_selected_item == null) {
                return;
            }
            enable ();
        }
    }

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public TextOptionsPanel (Akira.Window window) {
        Object (
            window: window,
            orientation: Gtk.Orientation.VERTICAL
        );
    }

    construct {
        var title_cont = new Gtk.Grid ();
        title_cont.get_style_context ().add_class ("option-panel");

        label = new Gtk.Label (_("Typography"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);
        title_cont.attach (label, 0, 0, 1, 1);

        attach (title_cont, 0, 0, 1, 1);

        var panel_grid = new Gtk.Grid ();
        get_style_context ().add_class ("style-panel");
        panel_grid.row_spacing = 6;
        panel_grid.border_width = 12;
        panel_grid.column_spacing = 6;
        panel_grid.hexpand = true;
        attach (panel_grid, 0, 1, 1, 1)
        ;

        add_children (panel_grid);

        show_all ();

        bind_signals ();
    }

    private void add_children (Gtk.Grid children_grid) {
        // Font Box
        selected_font = new Gtk.ComboBoxText.with_entry ();
        selected_font.hexpand = true;
        foreach (string font in fonts) {
            selected_font.append (font, font);
        }
        selected_font.set_active (0);
        // Font Weight Box
        font_weight = new Gtk.ComboBoxText ();
        foreach (string weight in text_weights) {
            font_weight.append (weight, weight);
        }
        // Font Size InputField
        font_size_input = new Akira.Partials.InputField (Akira.Partials.InputField.Unit.PIXEL, 7, true, true);
        font_size_input.entry.hexpand = false;
        font_size_input.entry.sensitive = true;
        font_size_input.entry.width_request = 64;
        font_size_input.set_range (1, 5000);
        // Scale Button
        scale_button = new Granite.Widgets.ModeButton ();
        scale_button.halign = Gtk.Align.FILL;
        scale_button.append_text ("Auto");
        scale_button.append_text ("Fixed");
        scale_button.set_active (0);
        // Align Scale Button
        align_scale_button = new Granite.Widgets.ModeButton ();
        align_scale_button.halign = Gtk.Align.FILL;
        align_scale_button.append_icon ("format-justify-left-symbolic", Gtk.IconSize.BUTTON);
        align_scale_button.append_icon ("format-justify-center-symbolic", Gtk.IconSize.BUTTON);
        align_scale_button.append_icon ("format-justify-right-symbolic", Gtk.IconSize.BUTTON);
        align_scale_button.append_icon ("format-justify-fill-symbolic", Gtk.IconSize.BUTTON);
        align_scale_button.set_active (0);


        // Add Components to Grid
        children_grid.attach (selected_font, 0, 0, 6);
        children_grid.attach (font_weight, 0, 1, 4);
        children_grid.attach (font_size_input, 4, 1, 2);
        children_grid.attach (scale_button, 0, 2, 4);
        children_grid.attach (align_scale_button, 4, 2, 2);
    }

    private void bind_signals () {
        toggled = false;
        window.event_bus.selected_items_list_changed.connect (on_selected_items_list_changed);
        font_weight.changed.connect (()=> {
            switch (text_weights[font_weight.get_active ()]) {
                case "Light":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.LIGHT);
                    break;
                case "Light Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.LIGHT_ITALIC);
                    break;
                case "Thin":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.THIN);
                    break;
                case "Thin Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.THIN_ITALIC);
                    break;
                case "Regular":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.REGULAR);
                    break;
                case "Regular Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.REGULAR_ITALIC);
                    break;
                case "SemiBold":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.SEMIBOLD);
                    break;
                case "SemiBold Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.SEMIBOLD_ITALIC);
                    break;
                case "Bold":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.BOLD);
                    break;
                case "Bold Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.BOLD_ITALIC);
                    break;
                case "ExtraBold":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.EXTRABOLD);
                    break;
                case "ExtraBold Italic":
                    selected_item.text_font.set_text_weight (Akira.Lib.Components.Font.FontWeight.EXTRABOLD_ITALIC);
                    break;
            }
            selected_item.text_font.toggle_size_auto (!selected_item.text_font.is_size_fixed);
        });
        selected_font.changed.connect (()=> {
            if (Utils.Font.is_string_in_array (fonts[selected_font.get_entry_text_column ()], fonts)) {
                selected_item.text_font.set_font (selected_font.get_active_text ());
                font_weight.set_active (4);
                selected_item.text_font.toggle_size_auto (!selected_item.text_font.is_size_fixed);
            }
        });
        //
        var combo_box_children = selected_font.get_children ();
        combo_box_children.foreach ((box_child) => {
            if (box_child is Gtk.Entry) {
                box_child.key_press_event.connect (()=> {
                    window.event_bus.disconnect_typing_accel ();
                    return false;
                });
                box_child.focus_out_event.connect (()=> {
                    window.event_bus.connect_typing_accel ();
                    return false;
                });
            }
        });
        font_size_input.entry.changed.connect (()=> {
            selected_item.text_font.font_size = int.parse (font_size_input.entry.text);
        });
        scale_button.mode_changed.connect (()=> {
            if (scale_button.selected == 0) {
                selected_item.text_font.toggle_size_auto (true);
                return;
            }
            selected_item.text_font.toggle_size_auto (false);
        });
        align_scale_button.mode_changed.connect (()=> {
            switch (align_scale_button.selected) {
                case 0:
                    selected_item.alignment = Pango.Alignment.LEFT;
                    selected_item.wrap = Pango.WrapMode.WORD;
                    break;
                case 1:
                    selected_item.alignment = Pango.Alignment.CENTER;
                    selected_item.wrap = Pango.WrapMode.WORD;
                    break;
                case 2:
                    selected_item.alignment = Pango.Alignment.RIGHT;
                    selected_item.wrap = Pango.WrapMode.WORD;
                    break;
                case 3:
                    selected_item.alignment = Pango.Alignment.LEFT;
                    selected_item.wrap = Pango.WrapMode.CHAR;
                    break;
            }
        });
    }

    private void on_selected_items_list_changed (List<Lib.Items.CanvasItem> selected_items) {
        // Interrupt if we don't have an item selected or if more than 1 is selected
        // since we can't handle the border radius of multiple items at once.
        if (selected_items.length () == 0 || selected_items.length () > 1) {
            selected_item = null;
            toggled = false;
            return;
        }

        if (!(selected_items.nth_data (0) is Akira.Lib.Items.CanvasText)) {
            selected_item = null;
            toggled = false;
            return;
        }

        if (selected_item == null || selected_item != selected_items.nth_data (0)) {
            toggled = true;
            selected_item = (Akira.Lib.Items.CanvasText) selected_items.nth_data (0);
        }
    }

    private void on_size_change () {
        Pango.Rectangle ink_rect;
        Pango.Rectangle logical_rect;
        selected_item.get_natural_extents (out ink_rect, out logical_rect);
        int width = logical_rect.width / 1024;
        int height = logical_rect.height / 1024;
        if (!(selected_item.size.width == width && selected_item.size.height == height) && !selected_item.text_font.size_changed_from_code) {
            selected_item.text_font.is_size_fixed = true;
            scale_button.set_active (1);
        }
    }

    private void enable () {
        font_size_input.entry.value = (double)selected_item.text_font.font_size;
        selected_item.notify["width"].connect (on_size_change);
        selected_item.notify["height"].connect (on_size_change);
        switch (selected_item.text_font.font_weight) {
            case LIGHT:
                font_weight.set_active (0);
                break;
            case LIGHT_ITALIC:
                font_weight.set_active (1);
                break;
            case THIN:
                font_weight.set_active (2);
                break;
            case THIN_ITALIC:
                font_weight.set_active (3);
                break;
            case REGULAR:
                font_weight.set_active (4);
                break;
            case REGULAR_ITALIC:
                font_weight.set_active (5);
                break;
            case SEMIBOLD:
                font_weight.set_active (6);
                break;
            case SEMIBOLD_ITALIC:
                font_weight.set_active (7);
                break;
            case BOLD:
                font_weight.set_active (8);
                break;
            case BOLD_ITALIC:
                font_weight.set_active (9);
                break;
            case EXTRABOLD:
                font_weight.set_active (10);
                break;
            case EXTRABOLD_ITALIC:
                font_weight.set_active (11);
                break;
        }
        for (int i = 0; i < fonts.length; i++) {
            if (selected_item.text_font.font_name == fonts[i]) {
                selected_font.set_active (i);
            }
        }
        if (selected_item.text_font.is_size_fixed) {
            scale_button.set_active (1);
            return;
        }
        scale_button.set_active (0);
    }
}

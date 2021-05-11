/*
 * Copyright (c) 2019-2021 Alecaddd (https://alecaddd.com)
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

/*
 * Font component to keep track of the CanvasText font, which includes different attributes.
*/

public class Akira.Lib.Components.Font : Component {

    Items.CanvasText canvas_text_item;

    public string font_name { get; set; }
    public string font_parameters { get; set; }
    public bool is_italic = false;
    public bool is_size_fixed = false;
    public bool size_changed_from_code = false;
    int _font_size;
    public int font_size {
        get { return _font_size; }
        set {
            _font_size = value;
            canvas_text_item.font = to_string ();
            if (!is_size_fixed) {
                toggle_size_auto (true);
            }
        }
    }
    public FontWeight font_weight { get; set; }
    public Akira.Window window { get; set; }

    public enum FontWeight {
        LIGHT,
        LIGHT_ITALIC,
        THIN,
        THIN_ITALIC,
        REGULAR,
        REGULAR_ITALIC,
        SEMIBOLD,
        SEMIBOLD_ITALIC,
        BOLD,
        BOLD_ITALIC,
        EXTRABOLD,
        EXTRABOLD_ITALIC,
    }

    public Font (Items.CanvasItem _item, string item_font_name, int text_font_size, FontWeight? _font_weight = FontWeight.REGULAR) {
        item = _item;
        canvas_text_item = (Lib.Items.CanvasText)item;
        font_name = item_font_name;
        font_weight = _font_weight;
        font_parameters = "";
        font_size = text_font_size;
        // Since the size is auto we are making text auto
        toggle_size_auto (true);
    }

    public string to_string () {
        return font_name + " " + font_parameters + " " + font_size.to_string ();
    }

    public void set_font (string fnt_fam, int? fnt_size = font_size) {
        font_name = fnt_fam;
        fnt_size = font_size;
        canvas_text_item.font = to_string ();
    }

    public void make_italic () {
        font_parameters += " Italic";
        is_italic = true;
        item.font = to_string ();
    }

    public void remove_italic () {
        font_parameters += " Italic";
        is_italic = false;
        set_text_weight (font_weight);
    }

    public void set_text_weight (FontWeight text_weight) {
        switch (text_weight) {
            case LIGHT_ITALIC:
                font_parameters = "Light Italic";
                break;
            case LIGHT:
                font_parameters = "Light";
                break;
            case THIN_ITALIC:
                font_parameters = "Thin Italic";
                break;
            case THIN:
                font_parameters = "Thin";
                break;
            case REGULAR_ITALIC:
                font_parameters = "Regular Italic";
                break;
            case REGULAR:
            // If REGULAR no need to use the font paramaters
                font_parameters = "";
                break;
            case SEMIBOLD_ITALIC:
                font_parameters = "SemiBold Italic";
                break;
            case SEMIBOLD:
                font_parameters = "SemiBold";
                break;
            case BOLD_ITALIC:
                font_parameters = "Bold Italic";
                break;
            case BOLD:
                font_parameters = "Bold";
                break;
            case EXTRABOLD_ITALIC:
                font_parameters = "ExtraBold Italic";
                break;
            case EXTRABOLD:
                font_parameters = "ExtraBold";
                break;
        }
        if (font_parameters.contains ("Italic")) {
            is_italic = true;
        }
        font_weight = text_weight;
        item.font = to_string ();
    }

    public void toggle_size_auto (bool make_auto) {
        if (make_auto) {
            size_changed_from_code = true;
            // We are setting the width big because getting the get_natural_extents () will get affected by the wrap
            canvas_text_item.size.width = 1000000;
            // We divide the values by 1024 to convert them to pt
            Pango.Rectangle ink_rect;
            Pango.Rectangle logical_rect;
            canvas_text_item.get_natural_extents (out ink_rect, out logical_rect);
            int width = logical_rect.width / 1024;
            int height = logical_rect.height / 1024;
            canvas_text_item.size.width = width;
            canvas_text_item.size.height = height;
        }
        is_size_fixed = !make_auto;
        size_changed_from_code = false;
    }
}

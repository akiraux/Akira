/**
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

using Akira.Lib.Components;

/**
 * Generate a simple Text item.
 */
public class Akira.Lib.Items.CanvasTextView : Goo.CanvasWidget {

    public Items.CanvasArtboard? artboard { get; set; }

    public CanvasTextView (CanvasText text_item) {
        parent = text_item.parent;

        // Create the text item.
        x = text_item.coordinates.x;
        y = text_item.coordinates.y;
        width = text_item.size.width;
        height = text_item.size.height;

        var text_view = new Gtk.TextView.with_buffer(new Gtk.TextBuffer(null));
        text_view.buffer.notify["text"].connect(()=>{
            text_item.text = text_view.buffer.text;
        });
        text_view.buffer.text = text_item.text;
        text_view.is_focus = true;
        print(text_view.get_cursor_visible().to_string());
        widget = text_view;

        // Add the newly created item to the Canvas or Artboard.
        parent.add_child (this, -1);

        widget.get_style_context ().add_class ("canvas-widget");
        add_css(text_item);
        // text_item.visibility = Goo.CanvasItemVisibility.INVISIBLE;
    }

    private void add_css (CanvasText item) {
        try {
            var provider = new Gtk.CssProvider ();
            var context = widget.get_style_context ();
            var upper_font_weight = item.text_font.font_parameters.replace (" Italic", "");
            var font_weight = "";
            for (int i = 0; i <= upper_font_weight.length; i++) {
                var letter = upper_font_weight.get_char (i);
                font_weight += letter.tolower ().to_string ();
            }
            var font_style = item.text_font.is_italic ? "italic" : "normal";
            font_weight = font_weight == "" ? "normal" : font_weight;

            var css = """.canvas-widget {
                    background:none;
                    font-size:%dpt;
                    font-family:%s;
                    font-weight:%s;
                    font-style:%s;
                }""".printf (item.text_font.font_size, item.text_font.font_name, font_weight,font_style);
                // print (item.text_font.font_size.to_string () + item.text_font.font_name + font_weight + font_style);

            provider.load_from_data (css, css.length);

            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
        }
    }
}

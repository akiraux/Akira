/*
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/*
 * Widget to create a reusable button that toggles the visibility of a color
 * for the fill or border components.
*/
public class Akira.Widgets.EyeDropperButton : Gtk.Button {
    private unowned Models.ColorModel model;

    private Widgets.ColorPicker? eyedropper = null;

    public EyeDropperButton () {
        can_focus = false;
        valign = Gtk.Align.CENTER;
        tooltip_text = _("Pick color");

        get_style_context ().add_class ("color-picker-button");
        add (new Gtk.Image.from_icon_name ("color-select-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        clicked.connect (on_clicked);
    }

    public void assign (Models.ColorModel model) {
        this.model = model;
        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    private void on_model_changed () {
        sensitive = !model.hidden;
    }

    private void on_clicked () {
        if (eyedropper == null) {
            eyedropper = new ColorPicker ();
        }
        eyedropper.show_all ();

        eyedropper.picked.connect ((picked_color) => {
            model.pattern = new Lib.Components.Pattern.solid (picked_color, false);
            eyedropper.close ();
        });

        eyedropper.cancelled.connect (() => {
            eyedropper.close ();
        });
    }
}

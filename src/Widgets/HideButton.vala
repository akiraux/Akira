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
public class Akira.Widgets.HideButton : Gtk.Button {
    private unowned Models.ColorModel model;

    private bool? current_state = null;

    public HideButton () {
        valign = Gtk.Align.CENTER;
        can_focus = false;
        margin_start = 3;

        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        get_style_context ().add_class ("button-rounded");

        clicked.connect (on_clicked);
    }

    ~HideButton () {
        clicked.disconnect (on_clicked);
        model.value_changed.disconnect (on_model_changed);
    }

    public void assign (Models.ColorModel model) {
        this.model = model;
        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    private void on_model_changed () {
        if (current_state == model.hidden) {
            return;
        }

        if (model.hidden) {
            get_style_context ().add_class ("active");
            image = new Gtk.Image.from_icon_name ("layer-hidden-symbolic", Gtk.IconSize.MENU);
            tooltip_text = _("Show color");
        } else {
            get_style_context ().remove_class ("active");
            image = new Gtk.Image.from_icon_name ("layer-visible-symbolic", Gtk.IconSize.MENU);
            tooltip_text = _("Hide color");
        }

        current_state = model.hidden;
    }

    private void on_clicked () {
        model.hidden = !model.hidden;
    }
}

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
 * Widget to handle the opacity field of fills.
*/
public class Akira.Widgets.OpacityField : Gtk.Grid {
    private unowned Models.ColorModel model;
    private InputField field;

    public class SignalBlocker {
        private unowned OpacityField item;

        public SignalBlocker (OpacityField fill_item) {
            item = fill_item;
            item.block_signal += 1;
        }

        ~SignalBlocker () {
            item.block_signal -= 1;
        }
    }

    protected int block_signal = 0;

    public new bool sensitive {
        get {
            return field.entry.sensitive;
        }
        set {
            field.entry.sensitive = value;
        }
    }

    public OpacityField (Lib.ViewCanvas canvas) {
        field = new InputField (canvas, Widgets.InputField.Unit.PERCENTAGE, 5, true, true);
        field.entry.value_changed.connect (on_opacity_changed);
        add (field);
    }

    ~OpacityField () {
        field.entry.value_changed.disconnect (on_opacity_changed);
        model.value_changed.disconnect (on_model_changed);
    }

    public void assign (Models.ColorModel model) {
        sensitive = true;
        this.model = model;
        model.value_changed.connect (on_model_changed);
        on_model_changed ();
    }

    /*
     * Triggered when the value is changed by the user.
     */
    private void on_opacity_changed () {
        if (block_signal > 0) {
            return;
        }

        var new_color = model.color;
        new_color.alpha = field.entry.value / 100;
        model.color = new_color;
    }

    /*
     * Update the entry value when the model changed.
     */
    private void on_model_changed () {
        if (field.entry.value / 100 == model.color.alpha) {
            return;
        }

        var blocker = new SignalBlocker (this);
        (blocker);
        field.entry.value = Math.round (model.color.alpha * 100);
    }
}

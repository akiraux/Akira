/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Models.FillsItemModel : GLib.Object {
    public string color { get; set; }
    public double alpha { get; set; }
    public bool hidden { get; set; }
    public Akira.Utils.BlendingMode blending_mode { get; set; }
    public Akira.Models.FillsListModel list_model { get; set; }

    public FillsItemModel (string color,
                           double alpha,
                           bool hidden,
                           Akira.Utils.BlendingMode blending_mode,
                           Akira.Models.FillsListModel list_model) {
        Object (
            color: color,
            alpha: alpha,
            hidden: hidden,
            blending_mode: blending_mode,
            list_model: list_model
        );
    }

    public string to_string () {
        return "Color: %s\n Alpha: %d\n Hidden: %s\n BlendingMode: %s".printf (
            color, (int) alpha, (hidden ? "1" : "0"), blending_mode.to_string ());
    }
}

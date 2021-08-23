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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

public class Akira.Lib.Components.Borders : Component, Copyable<Borders> {
    public Border.BorderData[] data;

    public Borders () {}

    public Borders.single_color (Color color, int size) {
        data = new Border.BorderData[1];
        data[0] = Border.BorderData (0, color, size);
    }

    public Borders.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("border_data").get_elements ();
        data = new Border.BorderData[0];

        var idx = 0;
        foreach (unowned var border in arr) {
            data.resize (data.length + 1);
            data[idx] = Border.BorderData.deserialized (idx, border.get_object ());
            ++idx;
        }
    }

    protected override void serialize_details (ref Json.Object obj) {
        var array = new Json.Array ();

        foreach (unowned var d in data) {
            array.add_element (d.serialize ());
        }

        var node = new Json.Node (Json.NodeType.ARRAY);
        node.set_array (array);
        obj.set_member ("border_data", node);
    }

    public Borders copy () {
        var cln = new Borders ();
        cln.data = data;
        return cln;
    }

    // Recommended accessors

    public Gee.ArrayList<Border> borders () {
        var tmp = new Gee.ArrayList<Border> ();
        for (var i = 0; i < data.length; ++i) {
            tmp.add (new Border (data[i]));
        }
        return tmp;
    }

    public void prep_borders (uint number_to_prep) {
        data = new Border.BorderData[number_to_prep];
        for (var i = 0; i < number_to_prep; ++i) {
            data[i]._id = i;
        }
    }
}

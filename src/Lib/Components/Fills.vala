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

public class Akira.Lib.Components.Fills : Component, Copyable<Fills> {
    public Fill.FillData[] data;

    public Fills () {}

    public Fills.single_color (Color color) {
        data = new Fill.FillData[1];
        data[0] = Fill.FillData (0, color);
    }

    public Fills.deserialized (Json.Object obj) {
        var arr = obj.get_array_member ("fill_data").get_elements ();
        data = new Fill.FillData[0];
        var idx = 0;
        foreach (unowned var fill in arr) {
            data.resize (data.length + 1);
            data[idx] = Fill.FillData.deserialized (idx, fill.get_object ());
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
        obj.set_member ("fill_data", node);
    }

    public Fills copy () {
        var cln = new Fills ();
        cln.data = data;
        return cln;
    }

    // Recommended accessors

    public Gee.ArrayList<Fill> fills () {
        var tmp = new Gee.ArrayList<Fill> ();
        for (var i = 0; i < data.length; ++i) {
            tmp.add (new Fill (data[i]));
        }
        return tmp;
    }

    public void prep_fills (uint number_to_prep) {
        data = new Fill.FillData[number_to_prep];
        for (var i = 0; i < number_to_prep; ++i) {
            data[i]._id = i;
        }
    }
 }

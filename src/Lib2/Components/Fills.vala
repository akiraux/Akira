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

public class Akira.Lib2.Components.Fills {
    public Fill.FillData[] _data;

    public Fills () {}

    // Recommended accessors

    public Gee.ArrayList<Fill> fills () {
        var tmp = new Gee.ArrayList<Fill> ();
        for (var i = 0; i < _data.length; ++i) {
            tmp.add(new Fill(_data[i]));
        }
        return tmp;
    }

    public void prep_fills (uint number_to_prep) {
        _data = new Fill.FillData[number_to_prep];
        for (var i = 0; i < number_to_prep; ++i) {
            _data[i]._id = i;
        }
    }

    // Mutators

    public static Fills single_color (Color color) {
        var tmp = new Fills ();
        tmp._data = new Fill.FillData[1];
        tmp._data[0] = Fill.FillData(0, color);
        return tmp;
    }

    public Fills clone () {
        var cln = new Fills();
        cln._data = _data;
        return cln;
    }
 }

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

public class Akira.Lib2.Components.Borders {
    public Border.BorderData[] _data;

    public Borders () {}

    // Recommended accessors

    public Gee.ArrayList<Border> borders () {
        var tmp = new Gee.ArrayList<Border> ();
        for (var i = 0; i < _data.length; ++i) {
            tmp.add(new Border(_data[i]));
        }
        return tmp;
    }

    public void prep_borders (uint number_to_prep) {
        _data = new Border.BorderData[number_to_prep];
        for (var i = 0; i < number_to_prep; ++i) {
            _data[i]._id = i;
        }
    }

    // Mutators

    public static Borders single_color (Color color, int size) {
        var tmp = new Borders ();
        tmp._data = new Border.BorderData[1];
        tmp._data[0] = Border.BorderData(0, color, size);
        return tmp;
    }

    public Borders clone () {
        var cln = new Borders();
        cln._data = _data;
        return cln;
    }
}

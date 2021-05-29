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

public class Akira.Lib2.Components.Layer : Copyable<Layer> {
    private bool _selected;
    private bool _locked;

    public bool selected {
        get { return _selected; }
    }

    public bool locked {
        get { return _locked; }
    }

    public Layer (bool selected, bool locked) {
        _selected = selected;
        _locked = locked;
    }

    public Layer copy () {
        return new Layer (_selected, _locked);
    }

    public Layer with_selected (bool new_selected) {
        return new Layer (new_selected, _locked);
    }
    public Layer with_locked (bool new_locked) {
        return new Layer (_selected, new_locked);
    }
}

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

public class Akira.Lib.Components.Layer : Component, Copyable<Layer> {
    private bool _locked;

    public bool locked {
        get { return _locked; }
    }

    public Layer (bool locked) {
        _locked = locked;
    }

    public Layer.deserialized (Json.Object obj) {
        _locked = obj.get_boolean_member ("locked");
    }

    protected override void serialize_details (ref Json.Object obj) {
        obj.set_boolean_member ("locked", _locked);
    }

    public Layer copy () {
        return new Layer (_locked);
    }

    public Layer with_locked (bool new_locked) {
        return new Layer (new_locked);
    }
}

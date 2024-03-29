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

public class Akira.Lib.Components.Name : Component, Copyable<Name> {
    private string _id;
    private string _name;
    private string _filename;

    public string id {
        get { return _id; }
    }

    public string name {
        get { return _name; }
    }

    public string filename {
        get { return _filename; }
    }

    public Name (string name, string id, string? filename = null) {
        _id = id;
        _name = name;
        _filename = filename != null ? filename : name;
    }

    public Name.deserialized (Json.Object obj) {
        _id = obj.get_string_member ("id");
        _name = obj.get_string_member ("name");
        _filename = obj.get_string_member ("filename");
    }

    protected override void serialize_details (ref Json.Object obj) {
        obj.set_string_member ("id", _id);
        obj.set_string_member ("name", _name);
        obj.set_string_member ("filename", _filename);
    }

    public Name copy () {
        return new Name (_name, _id, _filename);
    }
}

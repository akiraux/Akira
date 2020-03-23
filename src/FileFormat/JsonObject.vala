/*
 * Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

public class Akira.FileFormat.JsonObject : GLib.Object {
    public Lib.Models.CanvasItem? item { get; construct; }

    private Json.Object object;
    private ObjectClass obj_class;

    public JsonObject (Lib.Models.CanvasItem? item) {
        Object (item: item);
    }

    construct {
        object = new Json.Object ();
        obj_class = (ObjectClass) item.get_type ().class_ref ();

        foreach (ParamSpec spec in obj_class.list_properties ()) {
            write_key (spec);
        }
    }

    public Json.Node get_node () {
        var node = new Json.Node.alloc ();
        node.set_object (object);

        return node;
    }

    private void write_key (ParamSpec spec) {
        var type = spec.value_type;
        var val = Value (type);

        if (type == typeof (int)) {
            item.get_property (spec.get_name (), ref val);
            object.set_int_member (spec.get_name (), val.get_int ());
            //  debug ("%s: %i", spec.get_name (), val.get_int ());
        } else if (type == typeof (uint)) {
            item.get_property (spec.get_name (), ref val);
            object.set_int_member (spec.get_name (), val.get_uint ());
            //  debug ("%s: %s", spec.get_name (), val.get_uint ().to_string ());
        } else if (type == typeof (double)) {
            item.get_property (spec.get_name (), ref val);
            object.set_double_member (spec.get_name (), val.get_double ());
            //  debug ("%s: %f", spec.get_name (), val.get_double ());
        } else if (type == typeof (string)) {
            item.get_property (spec.get_name (), ref val);
            object.set_string_member (spec.get_name (), val.get_string ());
            //  debug ("%s: %s", spec.get_name (), val.get_string ());
        } else if (type == typeof (bool)) {
            item.get_property (spec.get_name (), ref val);
            object.set_boolean_member (spec.get_name (), val.get_boolean ());
            //  debug ("%s: %s", spec.get_name (), val.get_boolean ().to_string ());
        } else if (type == typeof (int64)) {
            item.get_property (spec.get_name (), ref val);
            object.set_int_member (spec.get_name (), val.get_int64 ());
            //  debug ("%s: %s", spec.get_name (), val.get_int64 ().to_string ());
        } else {
            //  warning ("Property type %s not yet supported: %s\n", type.name (), spec.get_name ());
        }
    }
}

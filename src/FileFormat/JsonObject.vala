/*
 *  Copyright (C) 2019 Felipe Escoto <felescoto95@hotmail.com>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

public abstract class Akira.FileFormat.JsonObject : GLib.Object {

    /**
     *Triggered when a property of the object has been set, if it was not
     * prevented by an override of internal_changed
     */
    [Signal (no_recurse = true, run = "first", action = true, no_hooks = true, detailed = true)]
    public signal void changed (string changed_property);

    public Json.Object object { internal get; construct set; }
    public JsonObject? parent_object { get; construct; default = null; }

    private ObjectClass obj_class;

    public JsonObject.from_object (Json.Object object) {
        Object (object: object);
    }

    construct {
        obj_class = (ObjectClass) get_type ().class_ref ();

        var properties = obj_class.list_properties ();
        foreach (var prop in properties) {
            load_key (prop.name, object);
        }
    }

    /**
     * The internal object will not be updated via the properties if this does is not executed.
     * Useful for read-only props
     */
    public void connect_signals () {
        notify.connect (handle_notify);
    }

    private void handle_notify (Object sender, ParamSpec property) {
        notify.disconnect (handle_notify);

        save_on_object (property.name);
        call_verify (property.name);

        notify.connect (handle_notify);
    }

    private void call_verify (string key) {
        if (key == "object" || key == "parent-object") {
            return;
        }

        if (internal_changed (key)) {
            changed (key);
        }
    }

    /**
     * For reacting to internal changes. Override and return false to prevent the triggering
     * of the changed signal
     */
    protected virtual bool internal_changed (string key)    {
        return true;
    }

    /**
     * Used when a JSON Property has a different name than a GObject property.
     * This should return the name of the JSON property that you want to get from a gobject string.
     *
     * For example. GObject properties internally use "-" instead of "_"
     */
    protected virtual string key_override (string key) {
        return key;
    }

    private void load_key (string key, Json.Object source_object) {
        if (key == "object" || key == "parent-object") {
            return;
        }

        string get_key = key_override (key);

        var prop = obj_class.find_property (key);

        var type = prop.value_type;
        var val = Value (type);

        // The type was another object.
        // We need to create it before anything else
        if (type.is_a (typeof (JsonObject))) {
            Json.Object new_objects_json;
            if (source_object.has_member (get_key)) {
                new_objects_json = source_object.get_object_member (get_key);
            } else {
                new_objects_json = new Json.Object ();
            }

            if (val.get_object () == null) {
                var new_object = Object.new (
                    type, "object",
                    new_objects_json,
                    "parent-object", this
                ) as JsonObject;

                set_property (prop.name, new_object);
                new_object.connect_signals ();
            } else {
                var json_object = (JsonObject) val.get_object ();
                json_object.override_properties_from_json (object);
            }
        } else if (type.is_a (typeof (FileFormat.JsonObjectArray))) {
            if (val.get_object () == null) {
                set_property (prop.name, Object.new (type, "object", source_object, "property_name", prop.name));
            } else {
                // Set elements to existing array
            }

            return;
        }

        if (!source_object.has_member (get_key)) {
            save_on_object (get_key);
            return;
        }

        if (type == typeof (int))
            set_property (prop.name, (int) source_object.get_int_member (get_key));
        else if (type == typeof (uint))
            set_property (prop.name, (uint) source_object.get_int_member (get_key));
        else if (type == typeof (double))
            set_property (prop.name, source_object.get_double_member (get_key));
        else if (type == typeof (string))
            set_property (prop.name, source_object.get_string_member (get_key));
        else if (type == typeof (bool))
            set_property (prop.name, source_object.get_boolean_member (get_key));
        else if (type == typeof (int64))
            set_property (prop.name, source_object.get_int_member (get_key));
    }

    /*
    * Runs when you set a vala property on the object to store the value in the internal JSON class
    */
    private void save_on_object (string key) {
        if (key == "object" || key == "parent-object") {
            return;
        }

        var prop = obj_class.find_property (key);

        // Do not attempt to save a non-mapped key
        if (prop == null)
        return;

        string get_key = key_override (key);

        var type = prop.value_type;
        var val = Value (type);
        this.get_property (prop.name, ref val);

        bool member_exists = object.has_member (get_key);
        if (val.type () == prop.value_type) {
            if (type == typeof (int)) {
                if (!member_exists || val.get_int () != object.get_int_member (get_key)) {
                    object.set_int_member (get_key, val.get_int ());
                }
            } else if (type == typeof (uint)) {
                if (!member_exists || val.get_uint () != object.get_int_member (get_key)) {
                    object.set_int_member (get_key, val.get_uint ());
                }
            } else if (type == typeof (int64)) {
                if (!member_exists || val.get_int64 () != object.get_int_member (get_key)) {
                    object.set_int_member (get_key, val.get_int64 ());
                }
            } else if (type == typeof (double)) {
                if (!member_exists || val.get_double () != object.get_double_member (get_key)) {
                    object.set_double_member (get_key, val.get_double ());
                }
            } else if (type == typeof (string)) {
                if (!member_exists || val.get_string () != object.get_string_member (get_key)) {
                    object.set_string_member (get_key, val.get_string ());
                }
            } else if (type == typeof (bool)) {
                if (!member_exists || val.get_boolean () != object.get_boolean_member (get_key)) {
                    object.set_boolean_member (get_key, val.get_boolean ());
                }
            } else if (type.is_a (typeof (JsonObject))) {
                var json_object = val.get_object () as JsonObject;
                object.set_object_member (get_key, json_object.object);
            } else if (type.is_a (typeof (JsonObjectArray))) {
                error ("JsonObject arrays should not be directly set");
            } else {
                warning ("Property type %s not yet supported: %s\n", type.name (), get_key);
            }
        }

        if (object.has_member (get_key) && object.get_null_member (get_key)) {
            object.remove_member (get_key);
        }
    }

    /**
     * Get's a string representation of this object. Useful for serialization
     */
    public string to_string (bool prettyfied) {
        var node = new Json.Node.alloc ();
        node.set_object (object);

        return Json.to_string (node, prettyfied);
    }

    /**
     * Got a new Json Object and want to update it's properties. Do it from here!
     */
    public void override_properties_from_json (Json.Object new_object) {
        notify.disconnect (handle_notify);

        this.object = new_object;

        var properties = obj_class.list_properties ();
        foreach (var prop in properties) {
            var prop_name = prop.name;
            if (prop_name == "object" || prop_name == "parent-object") {
                continue;
            }

            string get_key = key_override (prop_name);
            if (!new_object.has_member (get_key)) {
                continue;
            }

            var type = prop.value_type;
            var original_value = Value (type);

            if (ParamFlags.READABLE in prop.flags) {
                this.get_property (prop_name.down (), ref original_value);
            }

            bool change_prop = false;

            if (type == typeof (int)) {
                change_prop = (original_value.get_int () != new_object.get_int_member (get_key));
            } else if (type == typeof (uint)) {
                change_prop = (original_value.get_uint () != new_object.get_int_member (get_key));
            } else if (type == typeof (int64)) {
                change_prop = (original_value.get_int64 () != new_object.get_int_member (get_key));
            } else if (type == typeof (double)) {
                change_prop = (original_value.get_double () != new_object.get_double_member (get_key));
            } else if (type == typeof (string)) {
                change_prop = (original_value.get_string () != new_object.get_string_member (get_key));
            } else if (type == typeof (bool)) {
                change_prop = (original_value.get_boolean () != new_object.get_boolean_member (get_key));
            } else if (type.is_a (typeof (JsonObject))) {
                var object = new_object.get_object_member (get_key);

                var json_object = (JsonObject) original_value.get_object ();
                json_object.override_properties_from_json (object);
            } else if (type.is_a (typeof (JsonObjectArray))) {
                var json_object = (JsonObjectArray) original_value.get_object ();
                json_object.override_properties_from_json (object);
            } else {
                warning ("Property type %s not yet supported: %s\n", type.name (), get_key);
            }

            if (change_prop) {
                load_key (prop.name, new_object);
                changed (prop.name);
            }
        }

        notify.connect (handle_notify);
    }
}

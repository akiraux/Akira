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

    [Signal (no_recurse = true, run = "first", action = true, no_hooks = true, detailed = true)]
    public signal void changed (string changed_property);

    public Json.Object object { get; construct; }
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
     * For reacting to internal changes.
     *
     * Return false to prevent the triggering of the changed signal
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

        if (!source_object.has_member (get_key)) {
            return;
        }

        var prop = obj_class.find_property (key);

        var type = prop.value_type;
        var val = Value (type);

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
        else if (type.is_a (typeof (JsonObject))) {
            var object = source_object.get_object_member (get_key);
            if (val.get_object () == null) {
                set_property (prop.name, Object.new (type, "object", source_object, "parent-object", this));
            } else {
                var json_object = (JsonObject) val.get_object ();
                json_object.override_properties_from_json (object);
            }
        } else if (type.is_a (typeof (Akira.FileFormat.JsonObjectArray))) {
            if (val.get_object () == null) {
                set_property (prop.name, Object.new (type, "object", source_object, "property_name", prop.name));
            } else {
                // Set elements to existing array
            }
        } else if (type == typeof (string[])) {
            var list = new Gee.LinkedList<string> ();
            source_object.get_array_member (get_key).get_elements ().foreach ((node) => {
                list.add (node.get_string ());
            });
            set_property (prop.name, list.to_array ());
        } else {
            warning ("Unsupported type '%s' in object\n", type.name ());
        }
    }

    protected string get_string_property (string key) {
        var prop = obj_class.find_property (key);

        var type = prop.value_type;
        var val = Value (type);
        this.get_property (prop.name.down (), ref val);

        if (val.type () == prop.value_type) {
            if (type == typeof (int))
                return ((int) val).to_string ();
            else if (type == typeof (uint))
                return ((uint) val).to_string ();
            else if (type == typeof (double))
                return ((double) val).to_string ();
            else if (type == typeof (string))
                return ((string) val).to_string ();
            else if (type == typeof (bool))
                return ((bool) val).to_string ();
            else if (type == typeof (int64))
                return ((int64) val).to_string ();
        }

        assert_not_reached ();
    }

    /*
    * Runs when you set a vala property on the object to store the value in the internal JSON class
    */
    private void save_on_object (string key) {
        if (key == "object" || key == "parent-object") {
            return;
        }

        string get_key = key_override (key);

        var prop = obj_class.find_property (key);

        // Do not attempt to save a non-mapped key
        if (prop == null)
            return;

        var type = prop.value_type;
        var val = Value (type);
        this.get_property (prop.name, ref val);

        if (val.type () == prop.value_type) {
            if (type == typeof (int)) {
                if (val.get_int () != object.get_int_member (key)) {
                    object.set_int_member (get_key, val.get_int ());
                }
            } else if (type == typeof (uint)) {
                if (val.get_uint () != object.get_int_member (key)) {
                    object.set_int_member (get_key, val.get_uint ());
                }
            } else if (type == typeof (int64)) {
                if (val.get_int64 () != object.get_int_member (key)) {
                    object.set_int_member (get_key, val.get_int64 ());
                }
            } else if (type == typeof (double)) {
                if (val.get_double () != object.get_double_member (key)) {
                    object.set_double_member (key, val.get_double ());
                }
            } else if (type == typeof (string)) {
                if (val.get_string () != object.get_string_member (key)) {
                    object.set_string_member (key, val.get_string ());
                }
            } else if (type == typeof (string[])) {
                //  string[] strings = null;
                //  this.get (key, &strings);
                //  if (strings != schema.get_strv (key)) {
                //      schema.set_strv (key, strings);
                //  }
            } else if (type == typeof (bool)) {
                if (val.get_boolean () != object.get_boolean_member (key)) {
                    object.set_boolean_member (key, val.get_boolean ());
                }
            }
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

        var properties = obj_class.list_properties ();
        foreach (var prop in properties) {
            var prop_name = prop.name;
            if (prop_name == "object" || prop_name == "parent-object") {
                continue;
            }

            string get_key = key_override (prop_name);
            if (!new_object.has_member (get_key)) {
                return;
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
            } else if (type == typeof (string[])) {
                //  string[] strings = null;
                //  this.get (key, &strings);
                //  if (strings != schema.get_strv (key)) {
                //      schema.set_strv (key, strings);
                //  }
            } else if (type == typeof (bool)) {
                change_prop = (original_value.get_boolean () != new_object.get_boolean_member (get_key));
            } else if (type.is_a (typeof (JsonObject))) {
                var object = new_object.get_object_member (get_key);

                var json_object = (JsonObject) original_value.get_object ();
                json_object.override_properties_from_json (object);
            }

            if (change_prop) {
                load_key (prop.name, new_object);
                changed (prop.name);
            }
        }

        notify.connect (handle_notify);
    }
}

public abstract class Akira.FileFormat.JsonObjectArray : Object {
    public unowned Json.Object object { get; construct; }
    public string property_name { get; construct; }

    public JsonObjectArray (Json.Object object, string property_name) {
        Object (object: object, property_name: property_name);
    }

    construct {
        load_array ();
    }

    /**
     * Can be overriten to add more than one type of item into the array
     */
    protected virtual void load_array () {
        object.get_array_member (property_name).get_elements ().foreach ((node) => {
            add_to_list ((FileFormat.JsonObject) Object.new (get_type_of_array (),
                "object", node.get_object (),
                "parent-object", null));
        });
    }

    public abstract void add_to_list (FileFormat.JsonObject json_object);
    public abstract Type get_type_of_array ();
}
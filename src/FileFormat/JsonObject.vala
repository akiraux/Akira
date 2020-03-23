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
    public Goo.CanvasItem item { get; construct; }

    private Json.Object object;
    private ObjectClass obj_class;

    public JsonObject (Goo.CanvasItem item) {
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

        if (type == typeof (int)) {
            object.set_int_member (spec.get_name (), spec.get_default_value ().get_int ());
        } else if (type == typeof (uint)) {
            object.set_int_member (spec.get_name (), spec.get_default_value ().get_uint ());
        } else if (type == typeof (double)) {
            object.set_double_member (spec.get_name (), spec.get_default_value ().get_double ());
        } else if (type == typeof (string)) {
            object.set_string_member (spec.get_name (), spec.get_default_value ().get_string ());
        } else if (type == typeof (bool)) {
            object.set_boolean_member (spec.get_name (), spec.get_default_value ().get_boolean ());
        } else if (type == typeof (int64)) {
            object.set_int_member (spec.get_name (), spec.get_default_value ().get_int64 ());
        } else {
            warning ("Property type %s not yet supported: %s\n", type.name (), spec.get_name ());
        }
    }

    //  construct {
    //      obj_class = (ObjectClass) get_type ().class_ref ();

    //      var properties = obj_class.list_properties ();
    //      foreach (var prop in properties) {
    //          load_key (prop.name, object);
    //      }
    //  }

    //  /**
    //   * The internal object will not be updated via the properties if this does is not executed.
    //   * Useful for read-only props
    //   */
    //  public void connect_signals () {
    //      notify.connect (handle_notify);
    //  }

    //  private void handle_notify (Object sender, ParamSpec property) {
    //      notify.disconnect (handle_notify);

    //      save_on_object (property.name);
    //      call_verify (property.name);

    //      notify.connect (handle_notify);
    //  }

    //  private void call_verify (string key) {
    //      if (key == "object" || key == "parent-object") {
    //          return;
    //      }

    //      if (internal_changed (key)) {
    //          changed (key);
    //      }
    //  }

    //  /**
    //   * For reacting to internal changes. Override and return false to prevent the triggering
    //   * of the changed signal
    //   */
    //  protected virtual bool internal_changed (string key) {
    //      return true;
    //  }

    //  /**
    //   * Used when a JSON Property has a different name than a GObject property.
    //   * This should return the name of the JSON property that you want to get from a gobject string.
    //   *
    //   * For example. GObject properties internally use "-" instead of "_"
    //   */
    //  protected virtual string key_override (string key) {
    //      return key;
    //  }

    //  private void load_key (string key, Json.Object source_object) {
    //      if (key == "object" || key == "parent-object") {
    //          return;
    //      }

    //      string get_key = key_override (key);

    //      var prop = obj_class.find_property (key);

    //      var type = prop.value_type;
    //      var val = Value (type);

    //      // The type was another object.
    //      // We need to create it before anything else
    //      if (type.is_a (typeof (JsonObject))) {
    //          Json.Object new_objects_json;
    //          if (source_object.has_member (get_key)) {
    //              new_objects_json = source_object.get_object_member (get_key);
    //          } else {
    //              new_objects_json = new Json.Object ();
    //          }

    //          if (val.get_object () == null) {
    //              var new_object = Object.new (
    //                  type, "object",
    //                  new_objects_json,
    //                  "parent-object", this
    //              ) as JsonObject;

    //              set_property (prop.name, new_object);
    //              new_object.connect_signals ();
    //          } else {
    //              var json_object = (JsonObject) val.get_object ();
    //              json_object.override_properties_from_json (object);
    //          }
    //      }

    //      if (!source_object.has_member (get_key)) {
    //          save_on_object (get_key);
    //          return;
    //      }

    //      if (type == typeof (int))
    //          set_property (prop.name, (int) source_object.get_int_member (get_key));
    //      else if (type == typeof (uint))
    //          set_property (prop.name, (uint) source_object.get_int_member (get_key));
    //      else if (type == typeof (double))
    //          set_property (prop.name, source_object.get_double_member (get_key));
    //      else if (type == typeof (string))
    //          set_property (prop.name, source_object.get_string_member (get_key));
    //      else if (type == typeof (bool))
    //          set_property (prop.name, source_object.get_boolean_member (get_key));
    //      else if (type == typeof (int64))
    //          set_property (prop.name, source_object.get_int_member (get_key));
    //  }

    //  /*
    //  * Runs when you set a vala property on the object to store the value in the internal JSON class
    //  */
    //  private void save_on_object (string key) {
    //      if (key == "object" || key == "parent-object") {
    //          return;
    //      }

    //      var prop = obj_class.find_property (key);

    //      // Do not attempt to save a non-mapped key
    //      if (prop == null) {
    //          return;
    //      }

    //      string get_key = key_override (key);

    //      var type = prop.value_type;
    //      var val = Value (type);
    //      this.get_property (prop.name, ref val);

    //      bool member_exists = object.has_member (get_key);
    //      if (val.type () == prop.value_type) {
    //          if (type == typeof (int)) {
    //              if (!member_exists || val.get_int () != object.get_int_member (get_key)) {
    //                  object.set_int_member (get_key, val.get_int ());
    //              }
    //          } else if (type == typeof (uint)) {
    //              if (!member_exists || val.get_uint () != object.get_int_member (get_key)) {
    //                  object.set_int_member (get_key, val.get_uint ());
    //              }
    //          } else if (type == typeof (int64)) {
    //              if (!member_exists || val.get_int64 () != object.get_int_member (get_key)) {
    //                  object.set_int_member (get_key, val.get_int64 ());
    //              }
    //          } else if (type == typeof (double)) {
    //              if (!member_exists || val.get_double () != object.get_double_member (get_key)) {
    //                  object.set_double_member (get_key, val.get_double ());
    //              }
    //          } else if (type == typeof (string)) {
    //              if (!member_exists || val.get_string () != object.get_string_member (get_key)) {
    //                  object.set_string_member (get_key, val.get_string ());
    //              }
    //          } else if (type == typeof (bool)) {
    //              if (!member_exists || val.get_boolean () != object.get_boolean_member (get_key)) {
    //                  object.set_boolean_member (get_key, val.get_boolean ());
    //              }
    //          } else if (type.is_a (typeof (JsonObject))) {
    //              var json_object = val.get_object () as JsonObject;
    //              object.set_object_member (get_key, json_object.object);
    //          } else {
    //              warning ("Property type %s not yet supported: %s\n", type.name (), get_key);
    //          }
    //      }

    //      if (object.has_member (get_key) && object.get_null_member (get_key)) {
    //          object.remove_member (get_key);
    //      }
    //  }

    //  /**
    //   * Gets a string representation of this object. Useful for serialization
    //   */
    //  public string to_string (bool prettyfied) {
    //      var node = new Json.Node.alloc ();
    //      node.set_object (object);

    //      return Json.to_string (node, prettyfied);
    //  }

    //  /**
    //   * Got a new Json Object and want to update it's properties. Do it from here!
    //   */
    //  public void override_properties_from_json (Json.Object new_object) {
    //      notify.disconnect (handle_notify);

    //      this.object = new_object;

    //      var properties = obj_class.list_properties ();
    //      foreach (var prop in properties) {
    //          var prop_name = prop.name;
    //          if (prop_name == "object" || prop_name == "parent-object") {
    //              continue;
    //          }

    //          string get_key = key_override (prop_name);
    //          if (!new_object.has_member (get_key)) {
    //              continue;
    //          }

    //          var type = prop.value_type;
    //          var original_value = Value (type);

    //          if (ParamFlags.READABLE in prop.flags) {
    //              this.get_property (prop_name.down (), ref original_value);
    //          }

    //          bool change_prop = false;

    //          if (type == typeof (int)) {
    //              change_prop = (original_value.get_int () != new_object.get_int_member (get_key));
    //          } else if (type == typeof (uint)) {
    //              change_prop = (original_value.get_uint () != new_object.get_int_member (get_key));
    //          } else if (type == typeof (int64)) {
    //              change_prop = (original_value.get_int64 () != new_object.get_int_member (get_key));
    //          } else if (type == typeof (double)) {
    //              change_prop = (original_value.get_double () != new_object.get_double_member (get_key));
    //          } else if (type == typeof (string)) {
    //              change_prop = (original_value.get_string () != new_object.get_string_member (get_key));
    //          } else if (type == typeof (bool)) {
    //              change_prop = (original_value.get_boolean () != new_object.get_boolean_member (get_key));
    //          } else if (type.is_a (typeof (JsonObject))) {
    //              var object = new_object.get_object_member (get_key);

    //              var json_object = (JsonObject) original_value.get_object ();
    //              json_object.override_properties_from_json (object);
    //          } else {
    //              warning ("Property type %s not yet supported: %s\n", type.name (), get_key);
    //          }

    //          if (change_prop) {
    //              load_key (prop.name, new_object);
    //              changed (prop.name);
    //          }
    //      }

    //      notify.connect (handle_notify);
    //  }
}

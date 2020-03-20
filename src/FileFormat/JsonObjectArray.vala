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

public abstract class Akira.FileFormat.JsonObjectArray : Object {
    public unowned Json.Object object { get; construct set; }

    public string property_name { get; construct; }

    public Gee.ArrayList<JsonObject> elements;
    private Json.Array array;

    /**
     * This class acts as an extension of a JsonObject class.
     * Both should share the same "Object" property
     *
     * Your JsonObject implementation should have it's own list of items
     */
    protected JsonObjectArray (Json.Object object, string property_name) {
        Object (object: object, property_name: property_name);
    }

    construct {
        elements = new Gee.ArrayList<JsonObject> ();
        load_array ();
    }

    /**
     * Used for overriding all the properties from this.
     * This is a destructive action and will remove all previous
     * objects from this array.
     */
    public void override_properties_from_json (Json.Object new_object) {
        elements = new Gee.ArrayList<JsonObject> ();
        object = new_object;

        load_array ();
    }

    /**
     * Can be overwriten to add more than one type of item into the array
     */
    protected virtual void load_array () {
        if (!object.has_member (property_name)) {
            object.set_array_member (property_name, new Json.Array ());
        }

        array = object.get_array_member (property_name);

        array.get_elements ().foreach ((node) => {
            var json = node.get_object ();

            var element = Object.new (get_type_of_array (json),
            "object", json,
            "parent-object", null) as FileFormat.JsonObject;

            elements.add (element);
            element.connect_signals ();
        });
    }

    public abstract Type get_type_of_array (Json.Object object);

    public void add (FileFormat.JsonObject json_object) {
        if (!elements.contains (json_object)) {
            elements.add (json_object);
            array.add_object_element (json_object.object);
        }
    }

    public void remove (FileFormat.JsonObject json_object) {
        if (elements.contains (json_object)) {
            var index = elements.index_of (json_object);
            elements.remove (json_object);

            array.remove_element (index);
        }
    }
}

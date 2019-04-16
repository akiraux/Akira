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
    public JsonObjectArray (Json.Object object, string property_name) {
        Object (object: object, property_name: property_name);
    }

    construct {
        elements = new Gee.ArrayList<JsonObject>();
        load_array ();
    }

    /**
     * Used for overriting all the properties from this.
     * This is a destructive action and will remove all previous
     * objects from this array.
     */
    public void override_properties_from_json (Json.Object new_object) {
        elements = new Gee.ArrayList<JsonObject>();
        object = new_object;

        load_array ();
    }

    /**
     * Can be overriten to add more than one type of item into the array
     */
    protected virtual void load_array () {
        if (!object.has_member (property_name)) {
            object.set_array_member (property_name, new Json.Array ());
        }

        array = object.get_array_member (property_name);

        array.get_elements ().foreach ((node) => {
            var json = node.get_object ();

            var element =  Object.new (get_type_of_array (json),
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
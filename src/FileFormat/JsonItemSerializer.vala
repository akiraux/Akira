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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>
 * Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
 */

/**
 * Converts an item into a JSON Object, converting all the child attributes to string.
 */
public class Akira.FileFormat.JsonItemSerializer {

    /*
     * Serialize an item and return its corresponding Json.Node.
     */
    public static void serialize_node (Akira.Lib.Items.ModelNode node, ref Json.Builder builder) {
        builder.begin_object ();

        // serialize type
        {
            builder.set_member_name ("type");
            builder.add_string_value (node.instance.type.name_id);
        }

        // serialize components
        node.instance.components.serialize (ref builder);

        // serialize children
        if (node.instance.children != null && node.instance.children.length != 0) {
            serialize_children (node, ref builder);
        }

        builder.end_object ();
    }

    /*
     * Serialize all children of a node recursively.
     */
    public static void serialize_children (Akira.Lib.Items.ModelNode node, ref Json.Builder builder) {
        builder.set_member_name ("children");

        {
            builder.begin_array ();

            foreach (unowned var child in node.children.data) {
                serialize_node (child, ref builder);
            }

            builder.end_array ();
        }
    }
}

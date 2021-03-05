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
public class Akira.FileFormat.JsonObject : GLib.Object {
    public weak Lib.Items.CanvasItem? item;

    private Json.Object object;
    private ObjectClass obj_class;

    public JsonObject (Lib.Items.CanvasItem? _item) {
        item = _item;

        object = new Json.Object ();
        obj_class = (ObjectClass) item.get_type ().class_ref ();

        // Set a string of the type so we're not tied to the namespace and location.
        if (item is Lib.Items.CanvasArtboard) {
            object.set_string_member ("type", "artboard");
        }

        if (item is Lib.Items.CanvasRect) {
            object.set_string_member ("type", "rectangle");
        }

        if (item is Lib.Items.CanvasEllipse) {
            object.set_string_member ("type", "ellipse");
        }

        if (item is Lib.Items.CanvasImage) {
            object.set_string_member ("type", "image");
            object.set_string_member ("image_id", ((Lib.Items.CanvasImage) item).manager.filename);
        }

        if (item is Lib.Items.CanvasText) {
            object.set_string_member ("type", "text");
        }

        // Save the artboard ID if the item belongs to one.
        if (item.artboard != null) {
            object.set_string_member ("artboard", item.artboard.name.id);
        }

        write_matrix ();
        write_components ();
    }

    public Json.Node get_node () {
        var node = new Json.Node.alloc ();
        node.set_object (object);

        return node;
    }

    private void write_matrix () {
        var identity = Cairo.Matrix.identity ();
        item.get_transform (out identity);

        var matrix = new Json.Object ();
        matrix.set_double_member ("xx", identity.xx);
        matrix.set_double_member ("yx", identity.yx);
        matrix.set_double_member ("xy", identity.xy);
        matrix.set_double_member ("yy", identity.yy);
        matrix.set_double_member ("x0", identity.x0);
        matrix.set_double_member ("y0", identity.y0);

        object.set_object_member ("matrix", matrix);
    }

    /**
     * Write all the Components used by the item.
     */
    private void write_components () {
        // Interrupt if this is not a CanvasItem.
        if (!(item is Lib.Items.CanvasItem)) {
            return;
        }

        // Create the components object.
        var components = new Json.Object ();

        if (item.name != null) {
            var name = new Json.Object ();
            name.set_string_member ("name", item.name.name);
            name.set_string_member ("id", item.name.id);
            name.set_string_member ("icon", item.name.icon);

            components.set_object_member ("Name", name);
        }

        if (item.transform != null) {
            var transform = new Json.Object ();
            transform.set_double_member ("x", item.transform.x);
            transform.set_double_member ("y", item.transform.y);

            components.set_object_member ("Transform", transform);
        }

        if (item.opacity != null) {
            var opacity = new Json.Object ();
            opacity.set_double_member ("opacity", item.opacity.opacity);

            components.set_object_member ("Opacity", opacity);
        }

        if (item.rotation != null) {
            var rotation = new Json.Object ();
            rotation.set_double_member ("rotation", item.rotation.rotation);

            components.set_object_member ("Rotation", rotation);
        }

        if (item.size != null) {
            var size = new Json.Object ();
            size.set_boolean_member ("locked", item.size.locked);
            size.set_double_member ("ratio", item.size.ratio);
            size.set_double_member ("width", item.size.width);
            size.set_double_member ("height", item.size.height);

            components.set_object_member ("Size", size);
        }

        if (item.flipped != null) {
            var flipped = new Json.Object ();
            flipped.set_boolean_member ("horizontal", item.flipped.horizontal);
            flipped.set_boolean_member ("vertical", item.flipped.vertical);

            components.set_object_member ("Flipped", flipped);
        }

        if (item.border_radius != null) {
            var border_radius = new Json.Object ();
            border_radius.set_double_member ("x", item.border_radius.x);
            border_radius.set_double_member ("y", item.border_radius.y);
            border_radius.set_boolean_member ("uniform", item.border_radius.uniform);
            border_radius.set_boolean_member ("autoscale", item.border_radius.autoscale);

            components.set_object_member ("BorderRadius", border_radius);
        }

        if (item.layer != null) {
            var layer = new Json.Object ();
            layer.set_boolean_member ("locked", item.layer.locked);

            components.set_object_member ("Layer", layer);
        }

        if (item.fills != null) {
            var fills = new Json.Object ();

            foreach (Lib.Components.Fill fill in item.fills.fills) {
                var obj = new Json.Object ();
                obj.set_int_member ("id", fill.id);
                obj.set_string_member ("color", fill.color.to_string ());
                obj.set_int_member ("alpha", fill.alpha);
                obj.set_boolean_member ("hidden", fill.hidden);

                fills.set_object_member ("Fill-" + fill.id.to_string (), obj);
            }

            components.set_object_member ("Fills", fills);
        }

        if (item.borders != null) {
            var borders = new Json.Object ();

            foreach (Lib.Components.Border border in item.borders.borders) {
                var obj = new Json.Object ();
                obj.set_int_member ("id", border.id);
                obj.set_string_member ("color", border.color.to_string ());
                obj.set_int_member ("size", border.size);
                obj.set_int_member ("alpha", border.alpha);
                obj.set_boolean_member ("hidden", border.hidden);

                borders.set_object_member ("Border-" + border.id.to_string (), obj);
            }

            components.set_object_member ("Borders", borders);
        }

        // Save all the components in the main object.
        object.set_object_member ("Components", components);
    }
}

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

public struct Akira.Lib.Components.CompiledComponents {
    public CompiledFill? compiled_fill;
    public CompiledBorder? compiled_border;
    public CompiledGeometry? compiled_geometry;
    public CompiledName? compiled_name;

    public bool is_empty { get {
        return compiled_fill == null
            && compiled_border == null
            && compiled_geometry == null
            && compiled_name == null;
    }}

    public Lib.Components.Component.RegisteredTypes dirty_components;

    public CompiledComponents () {
        compiled_fill = null;
        compiled_border = null;
        compiled_geometry = null;
        compiled_name = null;
        dirty_components = Lib.Components.Component.RegisteredTypes ();
    }

    /*
     * Return true if new fill color was generated.
     */
    public bool maybe_compile_fill (Lib.Items.ModelType type, Components? components, Lib.Items.ModelNode? node) {
        if (compiled_fill != null) {
            return false;
        }

        compiled_fill = type.compile_fill (components, node);

        dirty_components.mark_dirty (Component.Type.COMPILED_FILL, true);
        return true;
    }

    /*
     * Return true if new border color was generated.
     */
    public bool maybe_compile_border (Lib.Items.ModelType type, Components? components, Lib.Items.ModelNode? node) {
        if (compiled_border != null) {
            return false;
        }

        compiled_border = type.compile_border (components, node);
        dirty_components.mark_dirty (Component.Type.COMPILED_BORDER, true);
        return true;
    }

    /*
     * Return true if new geometry was generated.
     */
    public bool maybe_compile_geometry (Lib.Items.ModelType type, Components? components, Lib.Items.ModelNode? node) {
        if (compiled_geometry != null) {
            return false;
        }

        compiled_geometry = type.compile_geometry (components, node);
        dirty_components.mark_dirty (Component.Type.COMPILED_GEOMETRY, true);
        return true;
    }

    public bool maybe_compile_name (Lib.Items.ModelType type, Components? components, Lib.Items.ModelNode? node) {
        if (compiled_name != null) {
            return false;
        }

        compiled_name = type.compile_name (components, node);
        dirty_components.mark_dirty (Component.Type.COMPILED_NAME, true);
        return true;
    }
}

public struct Akira.Lib.Components.Components {
    public Borders? borders;
    public BorderRadius? border_radius;
    public Fills? fills;
    public Flipped? flipped;
    public Layer? layer;
    public Name? name;
    public Opacity? opacity;

    public Coordinates? center;
    public Size? size;
    public Path? path;
    public Transform? transform;

    public Layout? layout;

    public Components () {
        borders = null;
        border_radius = null;
        fills = null;
        flipped = null;
        layer = null;
        name = null;
        opacity = null;
        center = null;
        size = null;
        path = null;
        transform = null;
        layout = null;
    }

    public static Name default_name () {
        return new Name ("item", "-1");
    }

    public static Opacity default_opacity () {
        return new Opacity (100.0);
    }

    public static Transform default_transform () {
        return new Transform.from_rotation (0.0);
    }

    public static Flipped default_flipped () {
        return new Flipped (false, false);
    }

    public static BorderRadius default_border_radius () {
        return new BorderRadius (0, 0, false, false);
    }

    public static Layer default_layer () {
        return new Layer (false, false);
    }

    public void serialize (ref Json.Builder builder) {
        builder.set_member_name ("components");

        {
            builder.begin_array ();

            if (borders != null) {
                builder.add_value (borders.serialize_component ("borders"));
            }
            if (border_radius != null) {
                builder.add_value (border_radius.serialize_component ("border_radius"));
            }
            if (fills != null) {
                builder.add_value (fills.serialize_component ("fills"));
            }
            if (flipped != null) {
                builder.add_value (flipped.serialize_component ("flipped"));
            }
            if (layer != null) {
                builder.add_value (layer.serialize_component ("layer"));
            }
            if (name != null) {
                builder.add_value (name.serialize_component ("name"));
            }
            if (center != null) {
                builder.add_value (center.serialize_component ("center"));
            }
            if (size != null) {
                builder.add_value (size.serialize_component ("size"));
            }
            if (path != null) {
                builder.add_value (path.serialize_component ("path"));
            }
            if (transform != null) {
                builder.add_value (transform.serialize_component ("transform"));
            }
            if (layout != null) {
                builder.add_value (layout.serialize_component ("layout"));
            }

            builder.end_array ();
        }
    }

    public static Components deserialize (Json.Node? components) {
        var new_components = Components ();

        if (components == null) {
            return new_components;
        }

        foreach (unowned var comp_node in components.get_array ().get_elements ()) {
            unowned var comp_obj = comp_node.get_object ();
            assert (comp_obj != null);
            var cname = comp_obj.get_string_member ("cname");

            // Here we could probably use delegates in the future.
            if (cname == "borders") {
                new_components.borders = new Lib.Components.Borders.deserialized (comp_obj);
            } else if (cname == "border_radius") {
                new_components.border_radius = new Lib.Components.BorderRadius.deserialized (comp_obj);
            } else if (cname == "fills") {
                new_components.fills = new Lib.Components.Fills.deserialized (comp_obj);
            } else if (cname == "flipped") {
                new_components.flipped = new Lib.Components.Flipped.deserialized (comp_obj);
            } else if (cname == "layer") {
                new_components.layer = new Lib.Components.Layer.deserialized (comp_obj);
            } else if (cname == "name") {
                new_components.name = new Lib.Components.Name.deserialized (comp_obj);
            } else if (cname == "center") {
                new_components.center = new Lib.Components.Coordinates.deserialized (comp_obj);
            } else if (cname == "size") {
                new_components.size = new Lib.Components.Size.deserialized (comp_obj);
            } else if (cname == "path") {
                new_components.path = new Lib.Components.Path.deserialized (comp_obj);
            } else if (cname == "transform") {
                new_components.transform = new Lib.Components.Transform.deserialized (comp_obj);
            } else if (cname == "layout") {
                new_components.layout = new Lib.Components.Layout.deserialized (comp_obj);
            }
        }

        return new_components;
    }
}

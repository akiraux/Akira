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

public struct Akira.Lib2.Components.CompiledComponents {
    public CompiledFill? compiled_fill;
    public CompiledBorder? compiled_border;
    public CompiledGeometry? compiled_geometry;

    public bool is_empty { get {
        return compiled_fill == null && compiled_border == null && compiled_geometry == null;
    }}

    public Lib2.Components.Component.RegisteredTypes dirty_components;

    public CompiledComponents () {
        compiled_fill = null;
        compiled_border = null;
        compiled_geometry = null;
        dirty_components = Lib2.Components.Component.RegisteredTypes ();
    }

    /*
     * Return true if new fill color was generated.
     */
    public bool maybe_compile_fill (Lib2.Items.ModelType type, Components? components, Lib2.Items.ModelNode? node) {
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
    public bool maybe_compile_border (Lib2.Items.ModelType type, Components? components, Lib2.Items.ModelNode? node) {
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
    public bool maybe_compile_geometry (Lib2.Items.ModelType type, Components? components, Lib2.Items.ModelNode? node) {
        if (compiled_geometry != null) {
            return false;
        }

        compiled_geometry = type.compile_geometry (components, node);
        dirty_components.mark_dirty (Component.Type.COMPILED_GEOMETRY, true);
        return true;
    }
}

public struct Akira.Lib2.Components.Components {
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
}

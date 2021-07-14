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

[Compact]
public class Akira.Lib2.Components.CompiledComponents {
    public CompiledFill? compiled_fill = null;
    public CompiledBorder? compiled_border = null;
    public CompiledGeometry? compiled_geometry = null;

    public Lib2.Components.Component.RegisteredTypes dirty_components;

    public CompiledComponents () {
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

[Compact]
public class Akira.Lib2.Components.Components {
    public Borders? borders = null;
    public BorderRadius? border_radius = null;
    public Fills? fills = null;
    public Flipped? flipped = null;
    public Layer? layer = null;
    public Name? name = null;
    public Opacity? opacity = null;

    public Coordinates? center = null;
    public Size? size = null;
    public Rotation? rotation = null;
    public Skew? skew = null;

    public Layout? layout = null;
    
    public Components copy () {
        var cln = new Components ();
        cln.borders = borders;
        cln.border_radius = border_radius;
        cln.fills = fills;
        cln.flipped = flipped;
        cln.layer = layer;
        cln.name = name;
        cln.opacity = opacity;

        cln.center = center;
        cln.size = size;
        cln.rotation = rotation;
        cln.skew = skew;

        return cln;
    }

    public static Opacity default_opacity () {
        return new Opacity (100.0);
    }

    public static Rotation default_rotation () {
        return new Rotation (0.0);
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
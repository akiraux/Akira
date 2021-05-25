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

public class Akira.Lib2.Components.Components : Object, Copyable<Components>{
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

    public CompiledFill? compiled_fill = null;
    public CompiledBorder? compiled_border = null;
    public CompiledGeometry? compiled_geometry = null;

    public Lib2.Components.Component.RegisteredTypes dirty_components;

    construct {
        dirty_components = Lib2.Components.Component.RegisteredTypes ();
    }

    public override Components copy () {
        var cln = new Components ();
        cln.borders = borders.copy ();
        cln.border_radius = border_radius.copy ();
        cln.fills = fills.copy ();
        cln.flipped = flipped.copy ();
        cln.layer = layer.copy ();
        cln.name = name.copy ();
        cln.opacity = opacity.copy ();

        cln.center = center.copy ();
        cln.size = size.copy ();
        cln.rotation = rotation.copy ();

        return cln;
    }

    /*
     * Return true if new fill color was generated.
     */
    public bool maybe_compile_fill () {
        if (compiled_fill != null) {
            return false;
        }

        compiled_fill = CompiledFill.compile (fills, opacity);
        dirty_components.mark_dirty (Component.Type.COMPILED_FILL, true);
        return true;
    }

    /*
     * Return true if new border color was generated.
     */
    public bool maybe_compile_border () {
        if (compiled_border != null) {
            return false;
        }
        compiled_border = CompiledBorder.compile (borders, opacity);
        dirty_components.mark_dirty (Component.Type.COMPILED_BORDER, true);
        return true;
    }

    /*
     * Return true if new geometry was generated.
     */
    public bool maybe_compile_geometry () {
        if (compiled_geometry != null) {
            return false;
        }

        compiled_geometry = CompiledGeometry.compile (
            center,
            size,
            rotation,
            borders,
            flipped
        );

        dirty_components.mark_dirty (Component.Type.COMPILED_GEOMETRY, true);

        return true;
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

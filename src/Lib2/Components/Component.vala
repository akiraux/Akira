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


/*
 * For now this is used as a namespace to hold some introspection.
 */
public class Akira.Lib2.Components.Component {
    /*
     * Type of component.
     * For now this is only used for marking components dirty. It is technically
     * not necessary to have all components have anenum Type. Only the ones
     * that need respective View updates.
     */
    public enum Type {
        COMPILED_BORDER,
        COMPILED_FILL,
        COMPILED_GEOMETRY
    }

    public struct RegisteredType {
        public Type type;
        public bool dirty;

        public RegisteredType (Type t) {
            type = t;
            dirty = false;
        }
    }

    public struct RegisteredTypes {
        RegisteredType[] types;

        public RegisteredTypes () {
            types = new RegisteredType[3];
            types[0] = RegisteredType (Type.COMPILED_BORDER);
            types[1] = RegisteredType (Type.COMPILED_FILL);
            types[2] = RegisteredType (Type.COMPILED_GEOMETRY);
        }

        public void mark_dirty (Type type, bool new_state) {
            for (var i = 0; i < types.length; ++i) {
                if (types[i].type == type) {
                    types[i].dirty = new_state;
                }
            }
        }
    }
}

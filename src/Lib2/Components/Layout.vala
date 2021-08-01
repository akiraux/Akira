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
  * Defines how children will behave while in affine transforms.
  * For now the options are quite simple, in the future more data
  * and context could be added for more complex layouts.
  */
public class Akira.Lib2.Components.Layout : Copyable<Layout> {
    public struct LayoutData {
        public bool can_rotate;
        public bool dilated_resize;
        public bool clips_children;
    }

    // main data for boxed Fill
    private LayoutData _data;

    public Layout (LayoutData data) {
        _data = data;
    }

    public Layout copy () {
        return new Layout (_data);
    }

    // Recommended accessors
    public bool can_rotate { get { return _data.can_rotate; } }
    public bool dilated_resize { get { return _data.dilated_resize; } }
    public bool clips_children { get { return _data.clips_children; } }
}

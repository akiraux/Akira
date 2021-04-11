/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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


public interface Akira.Lib.Modes.InteractionMode : Object {
    public enum ModeType {
        UNDEFINED = 0,
        RESIZE,
        ITEM_INSERT
    }

    public abstract void mode_begin ();
    public abstract void mode_end ();
    public abstract ModeType mode_type ();
    public abstract Gdk.CursorType? cursor_type ();

    public abstract bool key_press_event (Gdk.EventKey event);
    public abstract bool key_release_event (Gdk.EventKey event);
    public abstract bool button_press_event (Gdk.EventButton event);
    public abstract bool button_release_event (Gdk.EventButton event);
    public abstract bool motion_notify_event (Gdk.EventMotion event);

}

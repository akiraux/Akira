/**
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
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
 * InteractionMode is an abstract definition. It abstracts a canvas interaction mode that can absorb mouse and key
 * events, as well as having a well defined beginning and end. How these things are defined is up to a higher
 * class such as the ModeManager.
 *
 * In general only one InteractionMode will be active at a time. There are some exceptions where a mode may
 * be masked by another, but this should be handled with a Manager with strong invariant management.
 *
 * To create a new mode:
 * 1. Add a new ModeType
 * 2. Create a new class that inherits from Object and InteractionMode
 * 3. Implement all abstract methods, and return the correct mode_type
 * 4. Create the new mode with the right trigger in Canvas, and ModeManager will automatically handle it
 *    based on the abstract methods below. Sometimes the same event that creates the mode should be passed
 *    to the mode_manager after the creation of the mode in order to guarantee correct behavior.
 * 5. For now, modes should take mode_manager on construction in order to be able to stop themselves. In
 *    the future this should be built into the api in a more abstract way.
 */
public abstract class Akira.Lib2.Modes.AbstractInteractionMode : Object {
    /*
     * Mode type that is used for introspection.
     */
    public enum ModeType {
        RESIZE,
        ITEM_INSERT,
        EXPORT,
        PAN
    }

    public signal void request_deregistration (ModeType type);

    /*
     * Override to define ModeType associated to mode.
     */
    public abstract ModeType mode_type ();

    /*
     * Override to add startup behavior to the mode.
     */
    public virtual void mode_begin () {}

    /*
     * Override to add shutdown behavior to mode.
     */
    public virtual void mode_end () {}

    /*
     * Override to define cursor associated to mode.
     */
    public virtual Gdk.CursorType? cursor_type () {
        return Gdk.CursorType.ARROW;
    }

    /*
     * Override to define key press event. Return true to absorb.
     */
    public virtual bool key_press_event (Gdk.EventKey event) {
        return false;
    }

    /*
     * Override to define key release event. Return true to absorb.
     */
    public virtual bool key_release_event (Gdk.EventKey event) {
        return false;
    }

    /*
     * Override to define button press event. Return true to absorb.
     */
    public virtual bool button_press_event (Gdk.EventButton event) {
        return false;
    }

    /*
     * Override to define button release event. Return true to absorb.
     */
    public virtual bool button_release_event (Gdk.EventButton event) {
        return false;
    }

    /*
     * Override to define mouse motion event. Return true to absorb.
     */
    public virtual bool motion_notify_event (Gdk.EventMotion event) {
        return false;
    }

    /*
     * Optionally override to provide some extra context that may be used
     * further up to know how to update other managers based on this mode.
     *
     * This context should not be relied upon for vital operations or anything
     * that requires a specific order of operations. It is generally meant for
     * more cosmetic features.
     */
    public virtual Object? extra_context () {
        return null;
    }
}

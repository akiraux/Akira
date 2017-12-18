/*
* Copyright (c) 2011-2017 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/
public class Akira.Shortcuts : Object {
    public bool handled;

    public bool handle (Gdk.EventKey e) {
        handled = false;

        if((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
            switch (e.keyval) {
                case Gdk.Key.n:
                    handled = true;
                    break;
                case Gdk.Key.q:
                    window.destroy ();
                    handled = true;
                    break;
                case Gdk.Key.comma:
                    //  open_preference ();
                    handled = true;
                    break;
                case Gdk.Key.period:
                    headerbar.toggle ();
                    statusbar.toggle ();
                    left_sidebar.toggle ();
                    right_sidebar.toggle ();
                    handled = true;
                    break;
                default:
                    break;
            }
        }

        return handled;
    }
}
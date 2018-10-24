/*
* Copyright (c) 2018 Felipe Escoto (https://github.com/Philip-Scott)
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
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: Alessandro Castellani <castellani.ale@gmail.com>
*/

public class Akira.Lib.Item : Goo.CanvasItemSimple, Goo.CanvasItem {
    //  construct {

    //  }
    public bool enter_notify_event (Goo.CanvasItem target, Gdk.EventCrossing event) {
        if (target is Goo.CanvasItem) {
            debug ("enter");
        }

        return false;
    }
}
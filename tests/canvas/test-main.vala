/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

class Main : GLib.Object {
    public static int main (string[] args) {
        var exit_status = 0;

        Gtk.init (ref args);
        Test.init (ref args);

        var tests = new Akira.TestRunner ();
        tests.add (new Akira.FillsItemTest ());
        tests.add (new Akira.Lib2ModelTests ());

        GLib.Idle.add (() => {
            exit_status = tests.run ();
            Gtk.main_quit ();

            return false;
        });

        Gtk.main ();

        return exit_status;
    }
}

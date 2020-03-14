/*
* Copyright (c) 2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.FileFormat.FileManager : Object {
    public weak Akira.Window window { get; construct; }

    // Keep track of edited status.
    public bool edited { get; set; default = false; }

    // Construct
    public FileManager (Akira.Window window) {
       Object(
          window: window
       );
    }

    construct {
        // Listen for events.
        window.event_bus.file_edited.connect (on_file_edited);
    }

    private void on_file_edited () {
        edited = true;
    }

    // Save file.
    // Check if we already have a file open to save or save a new one.

    //  Save as.

    //  Open.
}

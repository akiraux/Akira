/*
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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.StateManagers.PositionManager : Object {
    public weak Akira.Window window { get; construct; }

    private double x;

    public PositionManager (Akira.Window window) {
        Object (
            window: window
        );
    }

    private void init_position (double init_x) {
        x = init_x;
    }

    private void update_position (string origin) {
        // If the change request comes from a shape, update the value in the
        // Transform Panel.
        if (origin == "shape") {

            return;
        }

        // Otherwise, update the value for the selected shape.
    }
}
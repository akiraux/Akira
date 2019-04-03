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
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public enum Akira.Utils.BlendingMode {
    NORMAL,
    MULTIPLY,
    OVERLAY,
    SOFT_LIGHT,
    HARD_LIGHT,
    LIGHTEN,
    DARKEN,
    SCREEN,
    DIFFERENCE,
    LUMINOSITY,
    HUE;

    public static BlendingMode[] all () {
        return {
            NORMAL,
            MULTIPLY,
            OVERLAY,
            SOFT_LIGHT,
            HARD_LIGHT,
            LIGHTEN,
            DARKEN,
            SCREEN,
            DIFFERENCE,
            LUMINOSITY,
            HUE
        };
    }

    public string get_name () {
        var blending_mode_tokens = this
            .to_string ()
            .split("_");

        // Get everything but BLENDING_MODE
        blending_mode_tokens = blending_mode_tokens[4:blending_mode_tokens.length];

        var formatted_blending_mode = "";

        foreach (var elem in blending_mode_tokens) {
            elem = elem[0].toupper ().to_string() +
                elem[1:elem.length].down();

            formatted_blending_mode += elem;
        }

        return formatted_blending_mode;
    }
}

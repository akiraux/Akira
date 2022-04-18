
/**
 * Copyright (c) 2022 Alecaddd (https://alecaddd.com)
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

/*
 * This class creates a widget that allows user to create new stop points,
 * select existing stop points and assign them colors.
 *
 * When a different PatternType is selected from PatternChooser, this widget 
 * will redraw using the stop colors of that pattern.
 *
 * In order to visualize the pattern, the background of this widget will be colored
 * with a linear gradient. 
 *
 * It is disabled for SOLID pattern type.
 */
public class Akira.Widgets.GradientEditor : Gtk.DrawingArea {
    // This signal will be triggered when pattern is editor using this editor.
    // The PatternChooser will handle this signal.
    public signal void pattern_editor (Lib.Components.Pattern pattern);

    construct {
        
    }
}

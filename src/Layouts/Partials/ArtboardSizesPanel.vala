/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

public class Akira.Layouts.Partials.ArtboardSizesPanel : Gtk.Grid {
    // list to store all size categories
    private Gee.ArrayList<Gtk.Expander> categories;
    // these are the names of default cattegories
    // TODO: move these to the gschema
    private string[] category_names = {"Desktop", "Tablet", "Phone"};

    public ArtboardSizesPanel(Akira.Window window) {
        create_categories();
    }

    private void create_categories() {
        categories = new Gee.ArrayList<Gtk.Expander>();

        for(int i = 0; i < category_names.length; ++i) {
          Gtk.Expander exp = new Gtk.Expander(category_names[i]);
          attach(exp, 0, i, 1, 1);
        }
    }
}

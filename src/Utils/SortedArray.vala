/**
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
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
 */

 /*
  * This data structure will be used for storing the positions of guidelines.
  * Storing all elements in a sorted array will make it easier to check if a guideline
  * exists at the given position, to get the nearest neighbourest neightbours.
  * Since this data structure does not allow storing duplicate values,
  * placing a guideline over another will automatically delete it.
  *
  */
 public class Akira.Utils.SortedArray : Object {
    // Array to store all elements.
    public Gee.TreeSet<double?> elements;

    public int length {
        get {
            return elements.size;
        }
    }

    // Represent the upper and lower bound that all guidelines must stay in
    // if they don't want to be deleted. Represent the extents of artboard.
    // Any guideline outside this limit will be deleted.
    private double lower_bound;
    private double upper_bound;

    public SortedArray (double lower_bound, double upper_bound) {
        this.lower_bound = lower_bound;
        this.upper_bound = upper_bound;

        elements = new Gee.TreeSet<double?> (are_equal);
    }

    /*
     * Inserts the given elements in the set such that the resultant array remains sorted.
     */
    public void insert (double item) {
        if ((item > upper_bound) || (item < lower_bound)) {
            return;
        }

        elements.add (item);
    }

    public void remove_at (int index) {
        double item = elements.to_array ()[index];

        remove_item (item);
    }

    public void remove_item (double item) {
        elements.remove (item);
    }

    /*
     * Checks if element exists in the array.
     * Returns true if it exists and stores the position in index.
     * Returns false if element does not exist.
     */
    public bool contains (double item, out int index) {
        if (!elements.contains (item)) {
            index = -1;
            return false;
        }

        index = elements.head_set (item).size;
        return true;
    }

    public SortedArray clone () {
        var cln = new SortedArray (lower_bound, upper_bound);

        foreach (var item in elements) {
            cln.insert (item);
        }

        return cln;
    }

    public void get_distance_to_neighbours (double item, out double neigh_1, out double neigh_2) {
        if (are_equal (elements.first (), item) <= 0) {
            neigh_1 = 0;
        } else {
            neigh_1 = elements.lower (item);
        }

        if (are_equal (elements.last (), item) <= 0) {
            neigh_2 = 0;
        } else {
            neigh_2 = elements.higher (item);
        }
    }

    public void set_bounds (double lower_bound, double upper_bound) {
        this.lower_bound = lower_bound;
        this.upper_bound = upper_bound;
    }

    public void translate_all (double delta) {
        var new_elements = new Gee.TreeSet<double?> (are_equal);

        foreach (var item in elements) {
            new_elements.add (item - delta);
        }

        elements = new_elements;
    }

    public double at (int index) {
        return elements.to_array ()[index];
    }

    private int are_equal (double? a, double? b) {
        int thresh = 1;

        if (b - a > thresh) {
            return -1;
        } else if (a - b > thresh) {
            return 1;
        }

        return 0;
    }
 }

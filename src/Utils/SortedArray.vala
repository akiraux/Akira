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
    public double[] elements;
    public int length {
        get {
            return elements.length;
        }
    }

    public SortedArray () {
        elements = new double[0];
    }

    /*
     * Inserts the given elements in the such that the resultant array remains sorted.
     */
    public void insert (double item) {
        var new_elements = new double[elements.length + 1];
        int idx = 0;

        for (idx = 0; idx < elements.length; ++idx) {
            // If this element already exists, no need to insert it.
            if (are_equal (elements[idx], item)) {
                return;
            } else if (elements[idx] > item) {
                // If elements after current position are greater, then the new element must be inserted first.
                break;
            }

            new_elements[idx] = elements[idx];
        }

        new_elements[idx] = item;
        ++idx;

        // Copy the remaining elements.
        for (; idx < elements.length + 1; ++idx) {
            new_elements[idx] = elements[idx - 1];
        }

        elements = new_elements;
    }

    public void remove_at (int index) {
        if (index > elements.length - 1) {
            return;
        }

        var new_elements = new double[elements.length - 1];

        // Copy all elementss upto the given index.
        for (int idx = 0; idx < index; ++idx) {
            new_elements[idx] = elements[idx];
        }

        // Copy all elements after the given index.
        for (int idx = index + 1; idx < elements.length; ++idx) {
            new_elements[idx - 1] = elements[idx];
        }

        elements = new_elements;
    }

    public void remove_item (double item) {
        int index = 0;

        if (contains (item, out index)) {
            remove_at (index);
        }
    }

    /*
     * Checks if element exists in the array.
     * Returns true if it exists and stores the position in index.
     * Returns false if element does not exist.
     */
    public bool contains (double item, out int index) {
        index = inner_binary_search (0, elements.length - 1, item);

        if (index == -1) {
            return false;
        }

        return true;
    }

    public SortedArray clone () {
        var cln = new SortedArray ();
        cln.elements = new double[elements.length];

        for (int i = 0; i < elements.length; ++i) {
            cln.elements[i] = elements[i];
        }

        return cln;
    }

    /*
     * Utility function for binary search.
     */
    private int inner_binary_search (int start, int end, double key) {
        if (end >= start) {
            int mid = (start + end) / 2;
    
            if (are_equal (elements[mid], key)) {
                return mid;
            } else if (elements[mid] < key) {
                return inner_binary_search (mid + 1, end, key);
            } else {
                return inner_binary_search (start, mid - 1, key);
            }
        }

        return -1;
    }

    /*
     * Checks if two floating point numbers are equal.
     */
    private bool are_equal (double a, double b) {
        int thresh = 1;

        if ((a - b).abs () < thresh) {
            return true;
        }

        return false;
    }
 }

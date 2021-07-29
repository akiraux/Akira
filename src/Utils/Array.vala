
/**
 * Copyright (c) 2021 Alecaddd (http://alecaddd.com)
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
 * Authored by: Martin "mbfraga" Fraga <mbfraga@gmail.com>
 */

/**
 * Implements array methods that are useful. Some pertain to raw arrays and some to GLib.Array
 */
public class Akira.Utils.Array : Object {
    public static bool insert_at_iarray (ref int[] a, int pos, int value) {
        if (pos >= a.length || pos < 0) {
            assert(false);
            return false;
        }

        a.resize (a.length + 1);
        a.move (pos, pos + 1, a.length - pos - 1);
        a[pos] = value;
        return true;
    }

    public static bool append_to_iarray (ref int[] a, int value) {
        a.resize (a.length + 1);
        a[a.length - 1] = value;
        return true;
    }

    public static bool swap_within_iarray (ref int[] a, int pos, int newpos) {
        if (pos >= a.length || newpos >= a.length || pos < 0 || newpos < 0) {
            assert(false);
            return false;
        }

        var tmp = a[pos];
        a[pos] = a[newpos];
        a[newpos] = tmp;
        return true;
    }
    public static bool remove_from_iarray (ref int[] a, int pos, int length) {
        if (pos >= a.length || pos + length > a.length || pos < 0 || length < 0) {
            assert(false);
            return false;
        }

        a.move (pos + length, pos, a.length - pos - length);
        a.resize (a.length - length);
        return true;
    }


    public static void rotate_iarray (ref int[] arr, int first, int middle, int end) {
        if (first < 0 || end > arr.length) {
            assert (first >= 0);
            assert (end < arr.length);
            return;
        }
    
        assert (middle >= first);
        assert (end >= middle);
    
        var next = middle;
    
        while (first != next) {
            swap (ref arr, first ++, next++);
            if (next == end) {
                next = middle;
            } else if (first == middle) {
                middle = next;
            }
        }
    }

    public static void rotate_garray<T> (ref GLib.Array<T> arr, int first, int middle, int end) {
        if (first < 0 || end > arr.length) {
            assert (first >= 0);
            assert (end < arr.length);
            return;
        }
    
        assert (middle >= first);
        assert (end >= middle);
    
        if (first == middle || middle == end) {
            return;
        }
    
        var next = middle;
    
        while (first != next) {
            swap_garray (ref arr, first++, next++);
            if (next == end) {
                next = middle;
            } else if (first == middle) {
                middle = next;
            }
        }
    }

    public static void rotate_weak_garray<T> (ref GLib.Array<unowned T> arr, int first, int middle, int end) {
        if (first < 0 || end > arr.length) {
            assert (first >= 0);
            assert (end < arr.length);
            return;
        }
    
        assert (middle >= first);
        assert (end >= middle);
    
        if (first == middle || middle == end) {
            return;
        }
    
        var next = middle;
    
        while (first != next) {
            swap_weak_garray (ref arr, first++, next++);
            if (next == end) {
                next = middle;
            } else if (first == middle) {
                middle = next;
            }
        }
    }

    private static void swap (ref int[] arr, int a, int b) {
        var tmp = arr[a];
        arr[a] = arr[b];
        arr[b] = tmp;
    }
    
    public static void swap_garray<T> (ref GLib.Array<T> arr, int a, int b) {
        var tmp = arr.index(a);
        arr.data[a] = arr.index(b);
        arr.data[b] = tmp;
    }

    public static void swap_weak_garray<T> (ref GLib.Array<weak T> arr, int a, int b) {
        var tmp = arr.index(a);
        arr.data[a] = arr.index(b);
        arr.data[b] = tmp;
    }
}
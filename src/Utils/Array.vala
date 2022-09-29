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
    /*
     * Insert value in an int array. Return true on success.
     */
    public static bool insert_at_iarray (ref int[] a, int pos, int value) {
        if (pos > a.length || pos < 0) {
            assert (false);
            return false;
        }

        if (pos == a.length) {
            return append_to_iarray (ref a, value);
        }

        a.resize (a.length + 1);
        a.move (pos, pos + 1, a.length - pos - 1);
        a[pos] = value;
        return true;
    }

    /*
     * Appends value at the end of an int array. Return true on success.
     */
    public static bool append_to_iarray (ref int[] a, int value) {
        a.resize (a.length + 1);
        a[a.length - 1] = value;
        return true;
    }

    /*
     * Removes 'length' number of values at 'pos' from int array.
     */
    public static bool remove_from_iarray (ref int[] a, int pos, int length) {
        if (pos >= a.length || pos + length > a.length || pos < 0 || length < 0) {
            assert (false);
            return false;
        }

        a.move (pos + length, pos, a.length - pos - length);
        a.resize (a.length - length);
        return true;
    }

    /*
     * Rotates an int array.

     * Ranges first->middle and middle->end must be valid index ranges within a
     * middle will become the first int in the span.
     */
    public static bool rotate_iarray (ref int[] arr, int first, int middle, int end) {
        if (first < 0 || end > arr.length) {
            assert (first >= 0);
            assert (end < arr.length);
            return false;
        }

        if (first == middle || middle == end) {
            // no-op
            return true;
        }

        var next = middle;

        while (first != next) {
            swap_iarray (ref arr, first ++, next++);
            if (next == end) {
                next = middle;
            } else if (first == middle) {
                middle = next;
            }
        }
        return true;
    }

    /*
     * Gets minimum and maximum value in an int array.
     */
    public static void min_max_in_iarray (int[] positions, ref int min, ref int max) {
        foreach (var pos in positions) {
            if (pos < min) {
                min = pos;
            }
            if (pos > max) {
                max = pos;
            }
        }

        if (min == 0) {
            min = max;
        }
    }

    /*
     * Gets minimum and maximum value in an double array.
     */
    public static void min_max_in_darray (double[] positions, out double min, out double max) {
        min = double.MAX;
        max = double.MIN;

        foreach (var pos in positions) {
            if (pos < min) {
                min = pos;
            }
            if (pos > max) {
                max = pos;
            }
        }

        if (min == double.MAX) {
            min = 0;
        }

        if (max == double.MIN) {
            max = 0;
        }
    }

    /*
     * Rotates a GLib.Array.
     */
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

    /*
     * Rotates a GLib.Array with unowned values.
     */
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

    /*
     * Swaps 'a' and 'b' indices from an int array.
     */
    public static void swap_iarray (ref int[] arr, int a, int b) {
        var tmp = arr[a];
        arr[a] = arr[b];
        arr[b] = tmp;
    }

    /*
     * Swaps 'a' and 'b' indices from a double array.
     */
    public static void swap_darray (ref double[] arr, int a, int b) {
        var tmp = arr[a];
        arr[a] = arr[b];
        arr[b] = tmp;
    }

    /*
     * Swaps 'a' and 'b' indices from a GLib.Array.
     */
    public static void swap_garray<T> (ref GLib.Array<T> arr, int a, int b) {
        var tmp = arr.index (a);
        arr.data[a] = arr.index (b);
        arr.data[b] = tmp;
    }

    /*
     * Swaps 'a' and 'b' indices from a GLib.Array of unowned objects.
     */
    public static void swap_weak_garray<T> (ref GLib.Array<weak T> arr, int a, int b) {
        var tmp = arr.index (a);
        arr.data[a] = arr.index (b);
        arr.data[b] = tmp;
    }

    public static int compare_arrays (int[] a, int[] b) {
        int len_a = a.length;
        int len_b = b.length;

        var res = Posix.memcmp (a, b, (size_t)int.min (len_a, len_b) * sizeof (int));

        if (res == 0 && len_a != len_b) {
            return len_a < len_b ? -1 : 1;
        }

        return res;
    }
}

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
* Authored by: Martin (mbfraga) Fraga <mbfraga@gmail.com>
*/

using Akira.Utils;

public class Akira.ArrayTests : Akira.TestSuite {
    public ArrayTests () {
        this.add_test("iarray_insert", this.iarray_insert);
        this.add_test("iarray_append", this.iarray_append);
        this.add_test("iarray_remove", this.iarray_remove);
        this.add_test("iarray_rotate", this.iarray_rotate);
    }

    public override void setup () {}

    public override void teardown () {}

    public void print_iarray (int[] a) {
        print("array: ");
        foreach (var v in a) {
            print ("%i ", v);
        }
        print("\n");
    }

    public bool compare_iarrays (int[] a, int[] b) {
        if (a.length != b.length) {
            return false;
        }

        for (var i = 0; i < a.length; ++i) {
            if (a[i] != b[i]) {
                return false;
            }
        }

        return true;
    }

    public void iarray_insert () {
        var test_case = new int[] {1, 2, 3, 4};

        // Asserts? not sure how to handle these
        // assert(Utils.Array.insert_at_iarray (ref test_case, -1, 5) == false);
        // assert(Utils.Array.insert_at_iarray (ref test_case, 4, 5) == false);
        // compare_iarrays (test_case, {1, 2, 3, 4});

        assert(Utils.Array.insert_at_iarray (ref test_case, 0, 5) == true);
        compare_iarrays (test_case, {5, 1, 2, 3, 4});

        assert(Utils.Array.insert_at_iarray (ref test_case, 2, 5) == true);
        compare_iarrays (test_case, {5, 1, 5, 2, 3, 4});

        assert(Utils.Array.insert_at_iarray (ref test_case, 5, 5) == true);
        compare_iarrays (test_case, {5, 1, 5, 2, 3, 5, 4});
    }

    public void iarray_append () {
        var test_case = new int[] {};

        compare_iarrays (test_case, {});

        assert(Utils.Array.append_to_iarray (ref test_case, 5) == true);
        compare_iarrays (test_case, {5});

        assert(Utils.Array.append_to_iarray (ref test_case, 7) == true);
        compare_iarrays (test_case, {5, 7});
    }

    public void iarray_remove () {
        var test_case = new int[] {1, 2, 3, 4, 5};

        assert(Utils.Array.remove_from_iarray (ref test_case, 0, 1) == true);
        compare_iarrays (test_case, {2, 3, 4, 5});

        assert(Utils.Array.remove_from_iarray (ref test_case, 2, 1) == true);
        compare_iarrays (test_case, {2, 3, 5});

        assert(Utils.Array.remove_from_iarray (ref test_case, 2, 1) == true);
        compare_iarrays (test_case, {2, 3});

        assert(Utils.Array.remove_from_iarray (ref test_case, 0, 2) == true);
        compare_iarrays (test_case, {2, 3});

        test_case = new int[] {1, 2, 3, 4, 5};
        assert(Utils.Array.remove_from_iarray (ref test_case, 0, 5) == true);
        compare_iarrays (test_case, {});
    }

    public void iarray_rotate () {
        var test_case = new int[] {1, 2, 3, 4, 5};

        // test no-ops
        assert(Utils.Array.rotate_iarray (ref test_case, 0, 0, 2) == true);
        assert(Utils.Array.rotate_iarray (ref test_case, 3, 3, 5) == true);
        assert(Utils.Array.rotate_iarray (ref test_case, 0, 3, 3) == true);
        assert(Utils.Array.rotate_iarray (ref test_case, 0, 5, 5) == true);

        compare_iarrays (test_case, {1, 2, 3, 4, 5});

        assert(Utils.Array.rotate_iarray (ref test_case, 0, 1, 2) == true);
        compare_iarrays (test_case, {3, 1, 2, 4, 5});

        assert(Utils.Array.rotate_iarray (ref test_case, 0, 1, 2) == true);
        compare_iarrays (test_case, {2, 3, 1, 4, 5});

        test_case = new int[] {1, 2, 3, 4, 5};
        assert(Utils.Array.rotate_iarray (ref test_case, 1, 4, 5) == true);
        compare_iarrays (test_case, {1, 5, 2, 3, 4});

        test_case = new int[] {1, 2, 3, 4, 5};
        assert(Utils.Array.rotate_iarray (ref test_case, 0, 1, 5) == true);
        compare_iarrays (test_case, {2, 3, 4, 5, 1});
    }

}


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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

using GLib;

namespace Akira {
    public delegate void TestCaseFunc ();

    public GLib.SettingsSchemaSource schema_source;

    private class TestSuiteAdaptor {
        public string name;

        private Akira.TestCaseFunc func;
        private Akira.TestSuite test_suite;

        public TestSuiteAdaptor (string name, owned Akira.TestCaseFunc test_case_func,
                                 Akira.TestSuite test_suite) {
            this.name = name;
            this.func = (owned) test_case_func;
            this.test_suite = test_suite;
        }

        public void setup (void* fixture) {
            this.test_suite.setup ();
        }

        public void run (void* fixture) {
            this.func ();
        }

        public void teardown (void* fixture) {
            this.test_suite.teardown ();
        }

        public GLib.TestCase get_g_test_case () {
            return new GLib.TestCase (this.name,
                                      this.setup,
                                      this.run,
                                      this.teardown);
        }
    }

    public abstract class TestSuite : GLib.Object
    {
        private GLib.TestSuite g_test_suite;
        private TestSuiteAdaptor[] adaptors = new TestSuiteAdaptor[0];

        public TestSuite () {
            var name = this.get_name ();
            this.g_test_suite = new GLib.TestSuite (name);
        }

        public string get_name () {
            return this.get_type ().name ();
        }

        public GLib.TestSuite get_g_test_suite () {
            return this.g_test_suite;
        }

        public void add_test (string name, owned Akira.TestCaseFunc func) {
            var adaptor = new TestSuiteAdaptor (name, (owned) func, this);
            this.adaptors += adaptor;

            this.g_test_suite.add (adaptor.get_g_test_case ());
        }

        public virtual void setup () {
        }

        public virtual void teardown () {
        }
    }

    public class TestRunner : GLib.Object {
        private GLib.TestSuite root_suite;
        private GLib.File tmp_dir;
        private const string SCHEMA_FILE_NAME = "com.github.akiraux.akira.gschema.xml";

        public TestRunner (GLib.TestSuite? root_suite = null) {
            if (root_suite == null) {
                this.root_suite = GLib.TestSuite.get_root ();
            } else {
                this.root_suite = root_suite;
            }
        }

        public void add (Akira.TestSuite test_suite) {
            this.root_suite.add_suite (test_suite.get_g_test_suite ());
        }

        private void setup_settings () {
            Environment.set_variable ("GSETTINGS_BACKEND", "memory", true);
            Environment.set_variable ("GSETTINGS_SCHEMA_DIR", this.tmp_dir.get_path (), true);

            /* prepare temporary settings */
            var target_schema_path = this.tmp_dir.get_path ();

            try {
                var top_builddir = TestRunner.get_top_builddir ();

                var source_schema_file = GLib.File.new_for_path (
                    Path.build_filename (top_builddir, "data", SCHEMA_FILE_NAME));

                var target_schema_file = GLib.File.new_for_path (
                    Path.build_filename (target_schema_path, SCHEMA_FILE_NAME));

                source_schema_file.copy (target_schema_file,
                                         GLib.FileCopyFlags.OVERWRITE);
            }
            catch (GLib.Error error) {
                GLib.error ("Error copying schema file: %s", error.message);
            }

            var compile_schemas_result = 0;
            try {
                GLib.Process.spawn_command_line_sync (
                            "glib-compile-schemas %s".printf (target_schema_path),
                            null,
                            null,
                            out compile_schemas_result);
            }
            catch (GLib.SpawnError error) {
                GLib.error (error.message);
            }

            if (compile_schemas_result != 0) {
                GLib.error ("Could not compile schemas '%s'.", target_schema_path);
            }
        }

        public virtual void global_setup () {
            Environment.set_variable ("LANGUAGE", "C", true);

            try {
                this.tmp_dir = GLib.File.new_for_path (
                        GLib.DirUtils.make_tmp ("gnome-Akira-test-XXXXXX"));
            } catch (GLib.Error error) {
                GLib.error ("Error creating temporary directory for test files: %s".printf (error.message));
            }

            this.setup_settings ();
        }

        public virtual void global_teardown () {
            if (this.tmp_dir != null) {
                var tmp_dir_path = this.tmp_dir.get_path ();
                var delete_tmp_result = 0;

                try {
                    GLib.Process.spawn_command_line_sync (
                                            "rm -rf %s".printf (tmp_dir_path),
                                            null,
                                            null,
                                            out delete_tmp_result);
                } catch (GLib.SpawnError error) {
                    GLib.warning (error.message);
                }

                if (delete_tmp_result != 0) {
                    GLib.warning ("Could not delete temporary directory '%s'",
                                  tmp_dir_path);
                }
            }
        }

        public int run () {
            /* TODO: spawn a child process to tun tests, if it fails than we
                     will be able to exit cleanly */

            this.global_setup ();
            var exit_status = GLib.Test.run ();
            this.global_teardown ();

            return exit_status;
        }

        private static string get_top_builddir () {
            var builddir = Environment.get_variable ("top_builddir");

            if (builddir == null)
            {
                var dir = GLib.File.new_for_path (Environment.get_current_dir ());

                while (dir != null) {
                    var schema_path = GLib.Path.build_filename (dir.get_path (),
                                                                "data",
                                                                SCHEMA_FILE_NAME);

                    if (GLib.FileUtils.test (schema_path, GLib.FileTest.IS_REGULAR)) {
                        builddir = dir.get_path ();
                        break;
                    }

                    dir = dir.get_parent ();
                }
            }

            if (builddir == null) {
                /* fallback to parent dir, test should be ran from 'tests' dir */
                builddir = "..";
            }

            return builddir;
        }
    }
}


public static int main (string[] args) {
    var exit_status = 0;

    Gtk.init (ref args);
    Test.init (ref args);

    var tests = new Akira.TestRunner ();
    tests.add (new Akira.FillsItemTest ());

    GLib.Idle.add (() => {
        exit_status = tests.run ();
        Gtk.main_quit ();

        return false;
    });

    Gtk.main ();

    return exit_status;
}

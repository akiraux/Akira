# Define environment variables to run tests.
test_env = [
    'G_TEST_SRCDIR=@0@'.format(meson.current_source_dir()),
    'G_TEST_BUILDDIR=@0@'.format(meson.current_build_dir()),
    'GSETTINGS_BACKEND=memory',
    'GSETTINGS_SCHEMA_DIR=@0@/data/schemas'.format(meson.build_root()),
]

# Set necessary C flags.
test_cflags = [
  '-I@0@/../src'.format(meson.current_source_dir()),
  '-I@0@/../src'.format(meson.current_build_dir()),
  '-DTEST_DATA_DIR="@0@/data/schemas"'.format(meson.current_source_dir()),
]

# Canvas Tests ---------------------------------------- #
canvas_tests = executable (
    'canvas_tests',
    'tests-model.vala',

    'canvas/test-fills-item.vala',
    'canvas/test-lib2-model.vala',
    'canvas/test-main.vala',
    c_args: test_cflags,
    dependencies: [akira_dep]
)

test ('canvas_tests', canvas_tests, env: test_env)

# Settings Tests ---------------------------------------- #

# File Format Tests ---------------------------------------- #

# test_env = [
#     'G_TEST_SRCDIR=@0@'.format(meson.current_source_dir()),
#     'G_TEST_BUILDDIR=@0@'.format(meson.current_build_dir()),
#     'GSETTINGS_BACKEND=memory',
#     'GSETTINGS_SCHEMA_DIR=@0@/data/schemas'.format(meson.build_root()),
# ]

test_env = environment()
test_env.set('GSETTINGS_SCHEMA_DIR', join_paths(meson.build_root(), 'data', 'schemas'))
# test_env.set('GSETTINGS_SCHEMA_DIR', join_paths(akira_datadir, 'glib-2.0', 'schemas'))

test_cflags = [
  '-I@0@/../src'.format(meson.current_source_dir()),
  '-I@0@/../src'.format(meson.current_build_dir()),
  '-DTEST_DATA_DIR="@0@/data/schemas"'.format(meson.current_source_dir()),
]

test = executable (
    'akira_tests',
    'tests.vala',
    'test-fills-item.vala',
    c_args: test_cflags,
    dependencies: [akira_dep]
)

test ('akiratest', test, env: test_env)

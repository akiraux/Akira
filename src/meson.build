gnome = import('gnome')

configure_file(
    input: 'config.rs.in',
    output: 'config.rs',
    configuration: conf
)


# Copy the config.rs output to the source directory.
run_command(
  'cp',
  join_paths(meson.project_build_root(), 'src', 'config.rs'),
  join_paths(meson.project_source_root(), 'src', 'config.rs'),
  check: true
)

cargo_bin  = find_program('cargo')
cargo_opt  = [ '--manifest-path', meson.project_source_root() / 'Cargo.toml' ]
cargo_opt += [ '--target-dir', meson.project_build_root()  / 'src' ]
if get_option('offline')
  cargo_opt += [ '--offline' ]
  cargo_env  = [ 'CARGO_HOME=' + meson.project_source_root()  / 'cargo' ]
else
  cargo_env  = [ 'CARGO_HOME=' + meson.project_build_root()  / 'cargo-home' ]
endif

if get_option('buildtype') == 'release'
  cargo_opt += [ '--release' ]
  rust_target = 'release'
else
  rust_target = 'debug'
endif

cargo_build = custom_target(
    'cargo-build',
    build_by_default: true,
    build_always_stale: true,
    output: exec_name,
    console: true,
    install: true,
    install_dir: get_option('bindir'),
    command: [
        'env', cargo_env,
        cargo_bin, 'build',
        cargo_opt, '&&', 'cp', 'src' / rust_target / exec_name, '@OUTPUT@',
    ]
)

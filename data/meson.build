desktop_file = i18n.merge_file(
    input: configure_file(
        input: 'launcher.desktop.in.in',
        output: 'launcher.desktop.in',
        configuration: conf
    ),
    output: meson.project_name() + '.desktop',
    type: 'desktop',
    po_dir: '../po/extra',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
    test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

appstream_file = i18n.merge_file(
    input: configure_file(
        input: 'metadata.appdata.xml.in.in',
        output: 'metadata.appdata.xml.in',
        configuration: conf,
    ),
    output: meson.project_name() + '.appdata.xml',
    po_dir: '../po/extra',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

appstream_util = find_program('appstreamcli', required: false)
if appstream_util.found()
    test('Validate appstream file', appstream_util, args: ['validate', appstream_file])
endif

install_data(
    configure_file(
        input: 'settings.gschema.xml.in',
        output: 'settings.gschema.xml',
        configuration: conf
    ),
    install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas'),
    rename: meson.project_name() + '.gschema.xml',
)

compile_schemas = find_program('glib-compile-schemas', required: false)
if compile_schemas.found()
    test('Validate schema file',
        compile_schemas,
        args: ['--strict', '--dry-run', meson.current_source_dir()])
endif

subdir('icons')

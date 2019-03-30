icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + 'x' + i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons/hicolor', i + 'x' + i, 'apps')
    )
    install_data(
        join_paths('icons', i + 'x' + i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons/hicolor', i + 'x' + i + '@2', 'apps')
    )
    install_data(
        join_paths('icons', i + 'x' + i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons/hicolor', i + 'x' + i, 'mimetypes')
    )
endforeach

install_data(
    'icons/128x128/' + meson.project_name() + '.svg',
    install_dir: join_paths(get_option('datadir'), 'icons/hicolor/scalable/apps')
)

xdg_files_conf = configuration_data()
xdg_files_conf.set('APP_ID', application_id)

desktop_file = i18n.merge_file(
    input: configure_file(
        input: meson.project_name() + '.desktop.in.in',
        output: '@BASENAME@',
        configuration: xdg_files_conf
    ),
    output: application_id + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

appdata_file = i18n.merge_file(
    input: configure_file(
        input: meson.project_name() + '.appdata.xml.in.in',
        output: '@BASENAME@',
        configuration: xdg_files_conf
    ),
    output: application_id + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
if appstream_util.found()
  test(
    'validate-appdata', appstream_util,
    args: [
      'validate-relax', '--nonet', appdata_file.full_path()
    ]
  )
endif

install_data(
    meson.project_name() + '.mime.xml',
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages')
)
subdir('schemas')

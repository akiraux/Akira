icon_sizes = ['16', '24', '32', '48', '64', '128']
icons_dir = join_paths(akira_datadir, 'icons', 'hicolor')
foreach size : icon_sizes
    install_data(
        join_paths('icons', size + 'x' + size, meson.project_name() + '.svg'),
        install_dir: join_paths(icons_dir, size + 'x' + size, 'apps'),
        rename: application_id + '.svg'
    )
    install_data(
        join_paths('icons', size + 'x' + size, meson.project_name() + '.svg'),
        install_dir: join_paths(icons_dir, size + 'x' + size + '@2', 'apps'),
        rename: application_id + '@2.svg'
    )
    install_data(
        join_paths('icons', size + 'x' + size, meson.project_name() + '.svg'),
        install_dir: join_paths(icons_dir, size + 'x' + size, 'mimetypes'),
        rename: application_id + '.svg'
    )
endforeach

install_data(
    'icons/128x128/' + meson.project_name() + '.svg',
    rename: application_id + '.svg',
    install_dir: join_paths(icons_dir, 'scalable', 'apps')
)

desktop_file_conf = configuration_data()
desktop_file_conf.set('ICON_NAME', application_id)
desktop_file_conf.set('EXECUTABLE', application_id)

desktop_file = i18n.merge_file(
    input: configure_file(
        input: meson.project_name() + '.desktop.in.in',
        output: '@BASENAME@',
        configuration: desktop_file_conf
    ),
    output: application_id + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(akira_datadir, 'applications')
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

appdata_file_conf = configuration_data()
appdata_file_conf.set('APP_ID', application_id)
appdata_file_conf.set('GETTEXT_PACKAGE', application_id)

appdata_file = i18n.merge_file(
    input: configure_file(
        input: meson.project_name() + '.appdata.xml.in.in',
        output: '@BASENAME@',
        configuration: appdata_file_conf
    ),
    output: application_id + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po'),
    install: true,
    install_dir: join_paths(akira_datadir, 'metainfo')
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
    install_dir: join_paths(akira_datadir, 'mime', 'packages')
)
subdir('schemas')

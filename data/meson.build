assets_dir = join_paths(akira_datadir, 'pixmaps', application_id)
install_data('assets/akira-banner.jpg', install_dir: assets_dir)

icon_sizes = ['16', '24', '32', '48', '64', '128']
icons_dir = join_paths(akira_datadir, 'icons', 'hicolor')
foreach size : icon_sizes
  install_data(
    join_paths('icons', size + 'x' + size, application_id + '.svg'),
    install_dir: join_paths(icons_dir, size + 'x' + size, 'apps'),
  )
  install_data(
    join_paths('icons', size + 'x' + size, application_id + '.svg'),
    install_dir: join_paths(icons_dir, size + 'x' + size + '@2', 'apps'),
  )
  install_data(
    join_paths('icons', size + 'x' + size, application_id + '.svg'),
    install_dir: join_paths(icons_dir, size + 'x' + size, 'mimetypes'),
  )
endforeach

install_data(
  'icons/128x128/' + meson.project_name() + '.svg',
  rename: application_id + '.svg',
  install_dir: join_paths(icons_dir, 'scalable', 'apps'),
)

desktop_file_conf = configuration_data()
desktop_file_conf.set('ICON_NAME', application_id)
desktop_file_conf.set('EXECUTABLE', application_id)

desktop_file = i18n.merge_file(
  input: configure_file(
    input: meson.project_name() + '.desktop.in.in',
    output: '@BASENAME@',
    configuration: desktop_file_conf,
  ),
  output: application_id + '.desktop',
  po_dir: join_paths(meson.project_source_root(), 'po'),
  type: 'desktop',
  install: true,
  install_dir: join_paths(akira_datadir, 'applications'),
)

appdata_file_conf = configuration_data()
appdata_file_conf.set('APP_ID', application_id)
appdata_file_conf.set('GETTEXT_PACKAGE', application_id)

appdata_file = i18n.merge_file(
  input: configure_file(
    input: meson.project_name() + '.appdata.xml.in.in',
    output: '@BASENAME@',
    configuration: appdata_file_conf,
  ),
  output: application_id + '.appdata.xml',
  po_dir: join_paths(meson.project_source_root(), 'po'),
  install: true,
  install_dir: join_paths(akira_datadir, 'metainfo'),
)

install_data(
  meson.project_name() + '.mime.xml',
  install_dir: join_paths(akira_datadir, 'mime', 'packages'),
)
subdir('schemas')

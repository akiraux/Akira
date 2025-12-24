install_data(
  'assets/akira-banner.jpg',
  install_dir: akira_datadir / 'pixmaps' / application_id,
)

icon_sizes = ['16', '24', '32', '48', '64', '128']
icons_dir = akira_datadir / 'icons' / 'hicolor'
foreach size : icon_sizes
  install_data(
    'icons' / '@0@x@0@'.format(size) / '@0@.svg'.format(application_id),
    install_dir: icons_dir / '@0@x@0@'.format(size) / 'apps',
  )
  install_data(
    'icons' / '@0@x@0@'.format(size) / '@0@.svg'.format(application_id),
    install_dir: icons_dir / '@0@x@0@'.format(size) + '@2' / 'apps',
  )
  install_data(
    'icons' / '@0@x@0@'.format(size) / '@0@.svg'.format(application_id),
    install_dir: icons_dir / '@0@x@0@'.format(size) / 'mimetypes',
  )
endforeach

install_data(
  'icons' / '128x128' / '@0@.svg'.format(application_id),
  rename: '@0@.svg'.format(application_id),
  install_dir: icons_dir / 'scalable' / 'apps',
)

desktop_file_conf = configuration_data()
desktop_file_conf.set('ICON_NAME', application_id)
desktop_file_conf.set('EXECUTABLE', application_id)

desktop_file = i18n.merge_file(
  input: configure_file(
    input: '@0@.desktop.in.in'.format(meson.project_name()),
    output: '@0@.desktop.in'.format(application_id),
    configuration: desktop_file_conf,
  ),
  output: '@0@.desktop'.format(application_id),
  po_dir: meson.project_source_root() / 'po',
  type: 'desktop',
  install: true,
  install_dir: akira_datadir / 'applications',
)

appdata_file_conf = configuration_data()
appdata_file_conf.set('APP_ID', application_id)
appdata_file_conf.set('GETTEXT_PACKAGE', application_id)

appdata_file = i18n.merge_file(
  input: configure_file(
    input: '@0@.appdata.xml.in.in'.format(meson.project_name()),
    output: '@0@.appdata.xml.in'.format(application_id),
    configuration: appdata_file_conf,
  ),
  output: '@0@.appdata.xml'.format(application_id),
  po_dir: meson.project_source_root() / 'po',
  install: true,
  install_dir: akira_datadir / 'metainfo',
)

install_data(
  '@0@.mime.xml'.format(meson.project_name()),
  install_dir: akira_datadir / 'mime' / 'packages',
)
subdir('schemas')

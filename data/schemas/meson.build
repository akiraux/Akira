schemas_conf = configuration_data()
schemas_conf.set('SCHEMA_ID', application_id)
schemas_conf.set('SCHEMA_PATH', schema_path)
schemas_conf.set('GETTEXT_PACKAGE', gettext_package)

configure_file(
  input: '@0@.gschema.xml.in'.format(meson.project_name()),
  output: '@0@.gschema.xml'.format(application_id),
  configuration: schemas_conf,
  install_dir: akira_datadir / 'glib-2.0' / 'schemas',
)

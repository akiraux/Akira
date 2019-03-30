schemas_conf = configuration_data()
schemas_conf.set('SCHEMA_ID', application_id)
schemas_conf.set('SCHEMA_PATH', schema_path)
schemas_conf.set('GETTEXT_PACKAGE', gettext_package)

configure_file(
    input: meson.project_name() + '.gschema.xml.in',
    output: application_id + '.gschema.xml',
    configuration: schemas_conf,
    install_dir: join_paths(get_option('datadir'), 'glib-2.0/schemas')
)

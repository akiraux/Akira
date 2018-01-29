conf_data = configuration_data()
conf_data.set('DATADIR', get_option('datadir'))
conf_data.set('PKGDATADIR', get_option('datadir') + '/' + meson.project_name())
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('RELEASE_NAME', 'Akira')
conf_data.set('VERSION', '0.0.1')
conf_data.set('VERSION_INFO', 'The Linux Design Tool')
conf_data.set('INSTALL_PREFIX', '')
configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

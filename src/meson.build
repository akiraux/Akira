conf_data = configuration_data()
conf_data.set('PROJECT_NAME', meson.project_name())
conf_data.set('EXEC_NAME', meson.project_name())
conf_data.set('DATADIR', get_option('datadir'))
conf_data.set('PKGDATADIR', get_option('datadir') + '/' + meson.project_name())
conf_data.set('GETTEXT_PACKAGE', meson.project_name())
conf_data.set('RELEASE_NAME', 'Akira')
conf_data.set('VERSION', '0.0.1')
conf_data.set('VERSION_INFO', 'The Linux Design Tool')
conf_data.set('PREFIX', get_option('prefix'))

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'Main.vala',
    'Application.vala',
    'Window.vala',

    'FileFormat/AkiraFile.vala',
    'FileFormat/JsonObject.vala',
    'FileFormat/JsonObjectArray.vala',
    'FileFormat/ZipArchiveHandler.vala',
    'FileFormat/Objects/Version.vala',

    'Services/Settings.vala',
    'Services/ActionManager.vala',

    'Utils/Dialogs.vala',

    'Layouts/HeaderBar.vala',
    'Layouts/LeftSideBar.vala',
    'Layouts/MainCanvas.vala',
    'Layouts/MainWindow.vala',
    'Layouts/RightSideBar.vala',
    'Layouts/StatusBar.vala',
    'Layouts/Partials/LayersPanel.vala',
    'Layouts/Partials/PagesPanel.vala',
    'Layouts/Partials/Artboard.vala',
    'Layouts/Partials/Layer.vala',

    'Partials/HeaderBarButton.vala',
    'Partials/MenuButton.vala',
    'Partials/ZoomButton.vala',

    'Widgets/SettingsDialog.vala',

    'Lib/Canvas.vala',
    'Lib/Item.vala',

    'Lib/Selection/Nob.vala',

    asresources,
    config_header,
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite', version: '>= 5.2.0'),
        dependency('gee-0.8'),
        dependency('libxml-2.0'),
        dependency('libarchive'),
        dependency('json-glib-1.0'),
        dependency('cairo', version: '>=1.14'),
        dependency('goocanvas-2.0'),
        m_dep
    ],
    install: true
)

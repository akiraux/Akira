conf_data = configuration_data()
conf_data.set('PROJECT_NAME', meson.project_name())
conf_data.set('PREFIX', akira_prefix)
conf_data.set('DATADIR', akira_datadir)
conf_data.set('PKGDATADIR',akira_pkgdatadir)
conf_data.set('GETTEXT_PACKAGE', gettext_package)
conf_data.set('VERSION', '0.0.1')
conf_data.set('PROFILE', profile)
conf_data.set('APP_ID', application_id)

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    application_id,
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
    'Services/EventBus.vala',

    'Utils/Dialogs.vala',
    'Utils/BlendingMode.vala',

    'Layouts/HeaderBar.vala',
    'Layouts/LeftSideBar.vala',
    'Layouts/MainCanvas.vala',
    'Layouts/MainWindow.vala',
    'Layouts/RightSideBar.vala',
    'Layouts/Partials/LayersPanel.vala',
    'Layouts/Partials/PagesPanel.vala',
    'Layouts/Partials/Artboard.vala',
    'Layouts/Partials/Layer.vala',
    'Layouts/Partials/FillsBoxPanel.vala',
    'Layouts/Partials/FillItem.vala',
    'Layouts/Partials/BlendingModeItem.vala',
    'Layouts/Partials/TransformPanel.vala',
    'Layouts/Partials/StylePanel.vala',
    'Layouts/Partials/AlignItemsPanel.vala',

    'Partials/HeaderBarButton.vala',
    'Partials/MenuButton.vala',
    'Partials/ZoomButton.vala',
    'Partials/ButtonImage.vala',
    'Partials/AlignBoxButton.vala',
    'Partials/InputField.vala',
    'Partials/LinkedInput.vala',
    'Partials/PanelSeparator.vala',
    'Partials/PopoverButton.vala',

    'Models/FillsItemModel.vala',
    'Models/FillsListModel.vala',

    'Widgets/SettingsDialog.vala',

    'Lib/Canvas.vala',
    #'Lib/Models/Item.vala',
    #'Lib/Models/Rectangle.vala',
    #'Lib/Models/Ellipse.vala',
    'Lib/Managers/SelectedBoundManager.vala',
    #'Lib/Managers/AffineTransformManager.vala',
    'Lib/Managers/ItemsManager.vala',
    'Lib/Managers/NobManager.vala',

    'Lib/Models/CanvasItem.vala',
    'Lib/Models/CanvasRect.vala',
    'Lib/Models/CanvasEllipse.vala',
    'Lib/Models/CanvasText.vala',

    'Lib/Selection/Nob.vala',

    asresources,
    config_header,
    dependencies: [
        gtk_dependency,
        granite_dependency,
        gee_dependency,
        libxml_dependency,
        cairo_dependency,
        goocanvas_dependency,
        libarchive_dependency,
        json_glib_dependency,
        m_dep
    ],
    install: true
)

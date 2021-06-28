conf_data = configuration_data()
conf_data.set('PROJECT_NAME', meson.project_name())
conf_data.set('PREFIX', akira_prefix)
conf_data.set('DATADIR', akira_datadir)
conf_data.set('PKGDATADIR',akira_pkgdatadir)
conf_data.set('GETTEXT_PACKAGE', gettext_package)
conf_data.set('VERSION', '0.0.14')
conf_data.set('PROFILE', profile)
conf_data.set('APP_ID', application_id)

config_header = configure_file(
    input: 'config.vala.in',
    output: 'config.vala',
    configuration: conf_data
)

sources = files(
    'Application.vala',
    'Window.vala',

    'FileFormat/AkiraFile.vala',
    'FileFormat/FileManager.vala',
    'FileFormat/JsonSerializer.vala',
    'FileFormat/JsonItemSerializer.vala',
    'FileFormat/JsonDeserializer.vala',
    'FileFormat/ZipArchiveHandler.vala',

    'Services/Settings.vala',
    'Services/ActionManager.vala',
    'Services/EventBus.vala',

    'Utils/Dialogs.vala',
    'Utils/BlendingMode.vala',
    'Utils/AffineTransform.vala',
    'Utils/Color.vala',
    'Utils/Image.vala',
    'Utils/ColorPicker.vala',
    'Utils/Snapping.vala',

    'Layouts/HeaderBar.vala',
    'Layouts/LeftSideBar.vala',
    'Layouts/MainCanvas.vala',
    'Layouts/MainWindow.vala',
    'Layouts/RightSideBar.vala',
    'Layouts/Partials/LayersPanel.vala',
    'Layouts/Partials/PagesPanel.vala',
    'Layouts/Partials/Artboard.vala',
    'Layouts/Partials/Layer.vala',
    'Layouts/Partials/BordersPanel.vala',
    'Layouts/Partials/BorderItem.vala',
    'Layouts/Partials/FillsPanel.vala',
    'Layouts/Partials/FillItem.vala',
    'Layouts/Partials/BlendingModeItem.vala',
    'Layouts/Partials/TransformPanel.vala',
    'Layouts/Partials/BorderRadiusPanel.vala',
    'Layouts/Partials/AlignItemsPanel.vala',

    'Widgets/AddColorButton.vala',
    'Widgets/AlignBoxButton.vala',
    'Widgets/ButtonImage.vala',
    'Widgets/ColorField.vala',
    'Widgets/ColorRow.vala',
    'Widgets/ExportWidget.vala',
    'Widgets/HeaderBarButton.vala',
    'Widgets/InputField.vala',
    'Widgets/LinkedInput.vala',
    'Widgets/MenuButton.vala',
    'Widgets/PanelSeparator.vala',
    'Widgets/RoundedColorButton.vala',
    'Widgets/ZoomButton.vala',

    'Models/ColorModel.vala',
    'Models/ExportModel.vala',
    'Models/ListModel.vala',

    'Dialogs/ShortcutsDialog.vala',
    'Dialogs/SettingsDialog.vala',
    'Dialogs/ExportDialog.vala',
    'Dialogs/ReleaseDialog.vala',

    'Lib/Canvas.vala',

    'Lib/Components/Border.vala',
    'Lib/Components/Borders.vala',
    'Lib/Components/BorderRadius.vala',
    'Lib/Components/Component.vala',
    'Lib/Components/Coordinates.vala',
    'Lib/Components/Fill.vala',
    'Lib/Components/Fills.vala',
    'Lib/Components/Flipped.vala',
    'Lib/Components/Layer.vala',
    'Lib/Components/Name.vala',
    'Lib/Components/Opacity.vala',
    'Lib/Components/Rotation.vala',
    'Lib/Components/Size.vala',

    'Lib/Items/CanvasArtboard.vala',
    'Lib/Items/CanvasEllipse.vala',
    'Lib/Items/CanvasImage.vala',
    'Lib/Items/CanvasItem.vala',
    'Lib/Items/CanvasRect.vala',
    'Lib/Items/CanvasText.vala',

    'Lib/Managers/ExportManager.vala',
    'Lib/Managers/GridManager.vala',
    'Lib/Managers/HoverManager.vala',
    'Lib/Managers/ImageManager.vala',
    'Lib/Managers/ItemsManager.vala',
    'Lib/Managers/ModeManager.vala',
    'Lib/Managers/NobManager.vala',
    'Lib/Managers/SelectedBoundManager.vala',
    'Lib/Managers/SnapManager.vala',

    'Lib/Selection/Nob.vala',

    'Middlewares/CoordinatesMiddleware.vala',
    'Middlewares/SizeMiddleware.vala',

    'Lib/Modes/InteractionMode.vala',
    'Lib/Modes/TransformMode.vala',
    'Lib/Modes/ItemInsertMode.vala',
    'Lib/Modes/ExportMode.vala',
    'Lib/Modes/PanMode.vala',
)

deps = [
    gtk_dependency,
    granite_dependency,
    gee_dependency,
    libxml_dependency,
    cairo_dependency,
    goocanvas_dependency,
    libarchive_dependency,
    json_glib_dependency,
    libportal_dependency,
    m_dep
]

akira_library = library(
    'akira-library-1.0',
    sources,
    asresources,
    config_header,
    dependencies: deps
)

akira_dep = declare_dependency(
    dependencies: deps,
    link_with: akira_library,
    include_directories: include_directories('.')
)

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    application_id,
    'Main.vala',
    asresources,
    dependencies: deps + [akira_dep],
    install: true
)

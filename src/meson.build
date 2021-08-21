conf_data = configuration_data()
conf_data.set('PROJECT_NAME', meson.project_name())
conf_data.set('PREFIX', akira_prefix)
conf_data.set('DATADIR', akira_datadir)
conf_data.set('PKGDATADIR',akira_pkgdatadir)
conf_data.set('GETTEXT_PACKAGE', gettext_package)
conf_data.set('VERSION', '0.0.15')
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

    'Utils/Array.vala',
    'Utils/Dialogs.vala',
    'Utils/BlendingMode.vala',
    'Utils/AffineTransform.vala',
    'Utils/Color.vala',
    'Utils/Image.vala',
    'Utils/ColorPicker.vala',
    'Utils/ModelUtil.vala',
    'Utils/Nobs.vala',
    #'Utils/Snapping.vala',
    'Utils/Snapping2.vala',
    'Utils/SVGUtil.vala',
    'Utils/GeometryMath.vala',

    'Layouts/HeaderBar.vala',
    'Layouts/MainViewCanvas.vala',
    'Layouts/MainWindow.vala',

    'Layouts/Sidebars/LayersSidebar.vala',
    'Layouts/Sidebars/Partials/LayersPanel.vala',
    'Layouts/Sidebars/Partials/LayerElement.vala',

    'Widgets/AddColorButton.vala',
    'Widgets/AlignBoxButton.vala',
    'Widgets/ButtonImage.vala',
    'Widgets/ColorField.vala',
    #'Widgets/ColorRow.vala',
    #'Widgets/ExportWidget.vala',
    'Widgets/HeaderBarButton.vala',
    'Widgets/InputField.vala',
    'Widgets/LinkedInput.vala',
    'Widgets/MenuButton.vala',
    'Widgets/PanelSeparator.vala',
    'Widgets/RoundedColorButton.vala',
    'Widgets/ZoomButton.vala',

    'ViewLayers/BaseCanvas.vala',
    'ViewLayers/ViewLayer.vala',
    'ViewLayers/ViewLayerSnaps.vala',
    'ViewLayers/ViewLayerNobs.vala',
    'ViewLayers/ViewLayerHover.vala',
    'ViewLayers/ViewLayerGrid.vala',

    #'Models/ColorModel.vala',
    #'Models/ExportModel.vala',
    #'Models/ListModel.vala',

    'Dialogs/ShortcutsDialog.vala',
    'Dialogs/SettingsDialog.vala',
    #'Dialogs/ExportDialog.vala',
    'Dialogs/ReleaseDialog.vala',

    'Drawables/Drawable.vala',
    'Drawables/DrawableArtboard.vala',
    'Drawables/DrawableEllipse.vala',
    'Drawables/DrawablePath.vala',
    'Drawables/DrawableRect.vala',

    'Lib2/Components/Border.vala',
    'Lib2/Components/Borders.vala',
    'Lib2/Components/BorderRadius.vala',
    'Lib2/Components/Color.vala',
    'Lib2/Components/CompiledBorder.vala',
    'Lib2/Components/CompiledFill.vala',
    'Lib2/Components/CompiledGeometry.vala',
    'Lib2/Components/Component.vala',
    'Lib2/Components/Components.vala',
    'Lib2/Components/Coordinates.vala',
    'Lib2/Components/Fill.vala',
    'Lib2/Components/Fills.vala',
    'Lib2/Components/Flipped.vala',
    'Lib2/Components/Layer.vala',
    'Lib2/Components/Layout.vala',
    'Lib2/Components/Name.vala',
    'Lib2/Components/Opacity.vala',
    'Lib2/Components/Path.vala',
    'Lib2/Components/Size.vala',
    'Lib2/Components/Transform.vala',

    'Lib2/Items/Model.vala',
    'Lib2/Items/ModelInstance.vala',
    'Lib2/Items/ModelNode.vala',
    'Lib2/Items/ItemSelection.vala',
    'Lib2/Items/ModelType.vala',
    'Lib2/Items/ModelTypeArtboard.vala',
    'Lib2/Items/ModelTypeEllipse.vala',
    'Lib2/Items/ModelTypeGroup.vala',
    'Lib2/Items/ModelTypeRect.vala',
    'Lib2/Items/ModelTypePath.vala',

    'Lib2/Managers/CopyManager.vala',
    'Lib2/Managers/ItemsManager.vala',
    'Lib2/Managers/ModeManager.vala',
    'Lib2/Managers/NobManager.vala',
    'Lib2/Managers/HoverManager.vala',
    'Lib2/Managers/SelectionManager.vala',
    'Lib2/Managers/SnapManager.vala',

    'Lib2/Modes/AbstractInteractionMode.vala',
    'Lib2/Modes/TransformMode.vala',
    'Lib2/Modes/ItemInsertMode.vala',
    'Lib2/Modes/ExportMode.vala',
    'Lib2/Modes/PanMode.vala',

    'Lib2/ViewCanvas.vala',

    'Geometry/Point.vala',
    'Geometry/Rectangle.vala',
    'Geometry/Quad.vala',

)

deps = [
    gtk_dependency,
    granite_dependency,
    gee_dependency,
    libxml_dependency,
    cairo_dependency,
    libarchive_dependency,
    json_glib_dependency,
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

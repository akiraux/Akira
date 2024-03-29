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
    'Utils/ItemAlignment.vala',
    'Utils/ModelUtil.vala',
    'Utils/Nobs.vala',
    'Utils/Snapping.vala',
    'Utils/SVGUtil.vala',
    'Utils/GeometryMath.vala',
    'Utils/Bezier.vala',
    'Utils/Delegates.vala',

    'Layouts/HeaderBar.vala',
    'Layouts/MainViewCanvas.vala',
    'Layouts/MainWindow.vala',

    'Layouts/Alignment/AlignmentPanel.vala',

    'Layouts/BordersList/BorderItemModel.vala',
    'Layouts/BordersList/BorderListBox.vala',
    'Layouts/BordersList/BorderListItem.vala',
    'Layouts/BordersList/BorderListStore.vala',
    'Layouts/BordersList/BordersPanel.vala',

    'Layouts/FillsList/FillItemModel.vala',
    'Layouts/FillsList/FillListBox.vala',
    'Layouts/FillsList/FillListItem.vala',
    'Layouts/FillsList/FillsPanel.vala',
    'Layouts/FillsList/FillListStore.vala',

    'Layouts/LayersList/LayerItemModel.vala',
    'Layouts/LayersList/LayerListBox.vala',
    'Layouts/LayersList/LayerListItem.vala',
    'Layouts/LayersList/LayerListStore.vala',

    'Layouts/Sidebars/LayersSidebar.vala',
    'Layouts/Sidebars/OptionsSidebar.vala',

    'Layouts/Transforms/TransformPanel.vala',

    'Widgets/AddColorButton.vala',
    'Widgets/ButtonImage.vala',
    'Widgets/ColorButton.vala',
    'Widgets/ColorChooser.vala',
    'Widgets/ColorField.vala',
    'Widgets/ColorPicker.vala',
    'Widgets/ExportWidget.vala',
    'Widgets/EyeDropperButton.vala',
    'Widgets/HeaderBarButton.vala',
    'Widgets/HideButton.vala',
    'Widgets/InputField.vala',
    'Widgets/LinkedInput.vala',
    'Widgets/MenuButton.vala',
    'Widgets/OpacityField.vala',
    'Widgets/RoundedColorButton.vala',
    'Widgets/ZoomButton.vala',

    'Widgets/VirtualizingListBox/VirtualizingListBox.vala',
    'Widgets/VirtualizingListBox/VirtualizingListBoxModel.vala',
    'Widgets/VirtualizingListBox/VirtualizingListBoxRow.vala',
    'Widgets/VirtualizingListBox/VirtualizingSimpleListBox.vala',

    'ViewLayers/BaseCanvas.vala',
    'ViewLayers/ViewLayer.vala',
    'ViewLayers/ViewLayerSnaps.vala',
    'ViewLayers/ViewLayerNobs.vala',
    'ViewLayers/ViewLayerHover.vala',
    'ViewLayers/ViewLayerExportArea.vala',
    'ViewLayers/ViewLayerGrid.vala',
    'ViewLayers/ViewLayerPath.vala',
    'ViewLayers/ViewLayerMultiSelect.vala',

    'Models/ColorModel.vala',
    'Models/ExportModel.vala',
    #'Models/ListModel.vala',
    'Models/PathEditModel.vala',

    'Dialogs/ShortcutsDialog.vala',
    'Dialogs/SettingsDialog.vala',
    'Dialogs/ExportDialog.vala',
    'Dialogs/ReleaseDialog.vala',

    'Drawables/Drawable.vala',
    'Drawables/DrawableArtboard.vala',
    'Drawables/DrawableEllipse.vala',
    'Drawables/DrawableGroup.vala',
    'Drawables/DrawablePath.vala',
    'Drawables/DrawableRect.vala',
    'Drawables/DrawableText.vala',

    'Lib/Components/Borders.vala',
    'Lib/Components/BorderRadius.vala',
    'Lib/Components/Color.vala',
    'Lib/Components/CompiledBorder.vala',
    'Lib/Components/CompiledFill.vala',
    'Lib/Components/CompiledGeometry.vala',
    'Lib/Components/CompiledName.vala',
    'Lib/Components/Component.vala',
    'Lib/Components/Components.vala',
    'Lib/Components/Coordinates.vala',
    'Lib/Components/Fills.vala',
    'Lib/Components/Flipped.vala',
    'Lib/Components/Layer.vala',
    'Lib/Components/Layout.vala',
    'Lib/Components/Name.vala',
    'Lib/Components/Opacity.vala',
    'Lib/Components/Path.vala',
    'Lib/Components/Size.vala',
    'Lib/Components/Text.vala',
    'Lib/Components/Transform.vala',

    'Lib/Items/Model.vala',
    'Lib/Items/ModelInstance.vala',
    'Lib/Items/ModelNode.vala',
    'Lib/Items/ItemSelection.vala',
    'Lib/Items/ModelType.vala',
    'Lib/Items/ModelTypeArtboard.vala',
    'Lib/Items/ModelTypeEllipse.vala',
    'Lib/Items/ModelTypeGroup.vala',
    'Lib/Items/ModelTypeRect.vala',
    'Lib/Items/ModelTypePath.vala',
    'Lib/Items/ModelTypeText.vala',

    'Lib/Managers/CopyManager.vala',
    'Lib/Managers/ExportManager.vala',
    'Lib/Managers/HistoryManager.vala',
    'Lib/Managers/ItemsManager.vala',
    'Lib/Managers/ModeManager.vala',
    'Lib/Managers/NobManager.vala',
    'Lib/Managers/HoverManager.vala',
    'Lib/Managers/SelectionManager.vala',
    'Lib/Managers/SnapManager.vala',

    'Lib/Modes/AbstractInteractionMode.vala',
    'Lib/Modes/TransformMode.vala',
    'Lib/Modes/ItemInsertMode.vala',
    'Lib/Modes/ExportMode.vala',
    'Lib/Modes/PanMode.vala',
    'Lib/Modes/PathEditMode.vala',
    'Lib/Modes/MultiSelectMode.vala',

    'Lib/ViewCanvas.vala',

    'Geometry/Point.vala',
    'Geometry/Rectangle.vala',
    'Geometry/TransformedRectangle.vala',
    'Geometry/Quad.vala',
    'Geometry/PathSegment.vala'

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

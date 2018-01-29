# project name and programming language
project('com.github.alecaddd.akira', 'vala', 'c')

# Include the translations module
i18n = import('i18n')

# Include the gnome module
gnome = import('gnome')
asresources = gnome.compile_resources(
    'as-resources', 'data/assets.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

subdir('src')
# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src/Main.vala',
    'src/Application.vala',
    'src/Window.vala',
    'src/config.vala',
    'src/Services/Settings.vala',
    'src/Services/Shortcuts.vala',
    'src/Utils/Dialogs.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/LeftSideBar.vala',
    'src/Widgets/MainCanvas.vala',
    'src/Widgets/MainWindow.vala',
    'src/Widgets/RightSideBar.vala',
    'src/Widgets/StatusBar.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('gee-0.8'),
        dependency('libxml-2.0'),
        dependency('gtksourceview-3.0'),
    ],
    install: true
)

meson.add_install_script('meson/post_install.py')
subdir('data')
subdir('po')
subdir('schemas')

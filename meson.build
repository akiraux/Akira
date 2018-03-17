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
meson.add_install_script('meson/post_install.py')
subdir('data')
subdir('po')
subdir('schemas')

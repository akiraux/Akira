# project name and programming language
project('com.github.akiraux.akira', 'vala', 'c')


akira_prefix = get_option('prefix')
akira_datadir = join_paths(akira_prefix, get_option('datadir'))
akira_pkgdatadir = join_paths(akira_datadir, meson.project_name())

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'src', 'vapi')],
    language: 'vala'
)
# Include the translations module
i18n = import('i18n')
# Dependencies
gtk_dependency = dependency('gtk+-3.0')
granite_dependency = dependency('granite', version: '>= 5.2.0')
gee_dependency = dependency('gee-0.8')
libxml_dependency = dependency('libxml-2.0')
cairo_dependency = dependency('cairo', version: '>=1.14')
goocanvas_dependency = dependency('goocanvas-2.0')

# Optional dependencies
desktop_file_validate = find_program('desktop-file-validate', required: false)
appstream_util = find_program('appstream-util', required: false)


# Include the gnome module
gnome = import('gnome')
asresources = gnome.compile_resources(
    'as-resources', 'data/assets.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: true)

vala_lint = find_program('io.elementary.vala-lint', required : false)
if vala_lint.found()
    test (
        'Vala lint',
        vala_lint,
        args: ['-d', join_paths(meson.source_root(), 'src')]
    )
endif

# Set up the profile 
profile = get_option('profile')
if profile == 'development'
    application_id = meson.project_name() + 'Devel'
    schema_path = '/com/github/akiraux/akiraDevel/'
else
    application_id = meson.project_name()
    schema_path = '/com/github/akiraux/akira/'
endif
gettext_package = application_id

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (gettext_package), language:'c')

subdir('src')
subdir('data')
subdir('po')

meson.add_install_script('build-aux/meson/post_install.py')

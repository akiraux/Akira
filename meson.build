# project name and programming language
project(
  'com.github.akiraux.akira',
  'vala',
  'c',
  version: '0.0.15',
  meson_version: '>= 0.59.0',
)

akira_prefix = get_option('prefix')
akira_datadir = akira_prefix / get_option('datadir')
akira_pkgdatadir = akira_datadir / meson.project_name()
install_tests = get_option('install-tests')

# Include the translations module
i18n = import('i18n')
# Dependencies
gtk_dependency = dependency('gtk+-3.0')
granite_dependency = dependency('granite', version: '>= 6.0.0')
gee_dependency = dependency('gee-0.8')
libxml_dependency = dependency('libxml-2.0')
cairo_dependency = dependency('cairo', version: '>=1.14')
libarchive_dependency = dependency('libarchive')
json_glib_dependency = dependency('json-glib-1.0')

# Include the gnome module
gnome = import('gnome')
asresources = gnome.compile_resources(
  'as-resources',
  'data/assets.gresource.xml',
  source_dir: 'data',
  c_name: 'as',
)

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: true)

vala_lint = find_program('io.elementary.vala-lint', required: false)
if vala_lint.found()
  test(
    'Vala lint',
    vala_lint,
    args: ['-d', join_paths(meson.project_source_root(), 'src')],
  )
endif

# Set up the profile
profile = get_option('profile')
if profile == 'development'
  application_id = '@0@.Devel'.format(meson.project_name())
  schema_path = '/com/github/akiraux/akiraDevel/'
else
  application_id = meson.project_name()
  schema_path = '/com/github/akiraux/akira/'
endif
gettext_package = application_id

# Set our translation domain
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(gettext_package), language: 'c')
add_global_arguments(['-DG_LOG_DOMAIN="Akira"'], language: 'c')

subdir('src')
subdir('data')
subdir('po')

if install_tests
  subdir('tests')
endif

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)

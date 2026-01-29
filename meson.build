project('com.github.phase1geo.annotator', ['vala', 'c'],
    version : '2.0.1',
    license: 'GPL-2.0-or-later',
    meson_version: '>= 0.61.0',
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

gnome = import('gnome')
i18n = import('i18n')

po_dir = join_paths(meson.project_source_root(), 'po')

gresource = gnome.compile_resources(
    'annotator-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
)

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

sources = files()

subdir('data')
subdir('po')
subdir('src')

# Add the math library
cc = meson.get_compiler('c')
math_dep = cc.find_library('m', required: false)

add_project_arguments([
        '--vapidir=' + join_paths(meson.current_source_dir(), 'vapi'),
        '--disable-warnings'
    ],
    language: 'vala',
)

add_project_arguments(['-w'], language: 'c')

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('gee-0.8'),
    dependency('granite-7'),
    dependency('gtk4'),
    dependency('libxml-2.0'),
    dependency('pangocairo'),
    dependency('libarchive'),
    dependency('libwebp'),
    math_dep
]

e = executable('com.github.phase1geo.annotator',
    sources,
    config_file,
    gresource,
    dependencies: dependencies,
    vala_args: [
        join_paths(meson.project_source_root(), 'vapi', 'libwebp.vapi')
    ],
    install : true
)

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true,
)

# If our version of Meson supports it, update the mime database
#if meson.version().version_compare('>=0.64.0')
#  gnome.post_install(
#    update_mime_database: true,
#  )
#endif

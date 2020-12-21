project('com.github.phase1geo.annotator', ['vala', 'c'],
    version : '1.0.0',
    license: 'GPL-3.0'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

gnome = import('gnome')
i18n = import('i18n')

gresource = gnome.compile_resources(
    'annotator-resources', 'data/' + meson.project_name() + '.gresource.xml',
    source_dir: 'data',
)

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h',
]

sources = files()

subdir('data')
subdir('po')
subdir('src')

# If the GTK version is higher than 3.22, add a define to indicate that
gtk_dep = dependency('gtk+-3.0')
if gtk_dep.version().version_compare('>=3.22.0')
  add_project_arguments(['--define=GTK322'], language: 'vala')
endif

add_project_arguments([
        '--vapidir', join_paths(meson.current_source_dir(), 'vapi'),
        '--disable-warnings'
    ],
    language: 'vala',
)

dependencies = [
    dependency('gobject-2.0'),
    dependency('glib-2.0'),
    dependency('gee-0.8'),
    dependency('granite'),
    dependency('gtk+-3.0'),
    dependency('libxml-2.0')
]

e = executable('com.github.phase1geo.annotator',
    sources,
    gresource,
    c_args: c_args,
    dependencies: dependencies,
    vala_args: [],
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')

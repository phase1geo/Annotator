install_data(
    join_paths('images', 'icons', 'scalable', meson.project_name() + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data(
    join_paths('images', 'icons', 'scalable', 'application-' + meson.project_name() + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'mimetypes')
)

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: po_dir / 'extra',
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: po_dir / 'extra',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    meson.project_name() + '.xml',
    install_dir: join_paths(get_option('datadir'), 'mime', 'packages')
)

icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('images', 'icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )

    set_variable(
        '_system_icon_path',
        join_paths('/', get_option('prefix'), get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2')
    )

    if run_command(
        'test', '-d', get_variable('_system_icon_path'),
        check: false
    ).returncode() == 0 and run_command(
        'test', '-L', get_variable('_system_icon_path'),
        check: false
    ).returncode() != 0
        install_symlink(
            join_paths(meson.project_name() + '.svg'),
            install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
            pointing_to: join_paths('..', '..', i + 'x' + i, 'apps', meson.project_name() + '.svg')
        )
    endif
endforeach

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

application_id = meson.project_name()

# Install our icons in all the required sizes
icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        'hicolor' / i + 'x' + i / application_id + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'apps',
        rename: application_id + '.svg'
    )
    install_data(
        'hicolor' / i + 'x' + i / application_id + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i + '@2' / 'apps',
        rename: application_id + '.svg'
    )
    install_data(
        'hicolor' / i + 'x' + i / application_id + '.svg',
        install_dir: get_option('datadir') / 'icons' / 'hicolor' / i + 'x' + i / 'mimetypes',
        rename: application_id + '.svg'
    )
endforeach

install_data(
    'hicolor/128x128/' + meson.project_name() + '.svg',
    install_dir: get_option('datadir') / 'icons' / 'hicolor' / 'scalable' / 'apps',
    rename: application_id + '.svg'
)

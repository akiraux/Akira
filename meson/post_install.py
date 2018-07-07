#!/usr/bin/env python3

import os
import subprocess

install_prefix = os.environ['MESON_INSTALL_PREFIX']
schemadir = os.path.join(install_prefix, 'share/glib-2.0/schemas')

if not os.environ.get('DESTDIR'):
	print('Compiling gsettings schemas...')
	subprocess.call(['glib-compile-schemas', schemadir])
	
	print('Updating icon cache...')
	icon_cache_dir = os.path.join(install_prefix, 'share/icons/hicolor')
	subprocess.call(['gtk-update-icon-cache', '-qtf', icon_cache_dir])

	print('Updating desktop database...')
	desktop_database_dir = os.path.join(install_prefix, 'share/applications')
	subprocess.call(['update-desktop-database', '-q', desktop_database_dir])

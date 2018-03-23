#!/usr/bin/env python3

import os
import subprocess

install_prefix = os.environ['MESON_INSTALL_PREFIX']
schemadir = os.path.join(install_prefix, 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
	print('Compiling gsettings schemas...')
	subprocess.call(['glib-compile-schemas', schemadir])
	print('Renaming icons...')
	for size in ['16x16', '24x24', '32x32', '64x64', '128x128']:
		src = os.path.join(install_prefix, 'share', 'icons', 'hicolor', size, 'mimetypes', 'com.github.alecaddd.akira.svg')
		dst = os.path.join(install_prefix, 'share', 'icons', 'hicolor', size, 'mimetypes', 'application-x-akira.svg')
		os.rename(src, dst)

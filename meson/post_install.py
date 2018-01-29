#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
	print('Compiling gsettings schemas...')
	subprocess.call(['glib-compile-schemas', schemadir])
	print('Renaming icons...')
	os.rename('/usr/share/icons/hicolor/16x16/mimetypes/com.github.alecadd.akira.svg', '/usr/share/icons/hicolor/16x16/mimetypes/application-x-akira.svg')
	os.rename('/usr/share/icons/hicolor/24x24/mimetypes/com.github.alecadd.akira.svg', '/usr/share/icons/hicolor/24x24/mimetypes/application-x-akira.svg')
	os.rename('/usr/share/icons/hicolor/32x32/mimetypes/com.github.alecadd.akira.svg', '/usr/share/icons/hicolor/32x32/mimetypes/application-x-akira.svg')
	os.rename('/usr/share/icons/hicolor/64x64/mimetypes/com.github.alecadd.akira.svg', '/usr/share/icons/hicolor/64x64/mimetypes/application-x-akira.svg')
	os.rename('/usr/share/icons/hicolor/128x128/mimetypes/com.github.alecadd.akira.svg', '/usr/share/icons/hicolor/128x128/mimetypes/application-x-akira.svg')

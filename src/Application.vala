/*
* Copyright (c) 2011-2017 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

namespace Akira {
    public Akira.Services.Settings settings;
}

public class Akira.Application : Granite.Application {
    construct {
        flags |= ApplicationFlags.HANDLES_OPEN;
        build_data_dir = Constants.DATADIR;
        build_pkg_data_dir = Constants.PKGDATADIR;
        build_release_name = Constants.RELEASE_NAME;
        build_version = Constants.VERSION;
        build_version_info = Constants.VERSION_INFO;

        settings = new Akira.Services.Settings ();

        program_name = "Akira";
        exec_name = "com.github.alecaddd.akira";
        app_launcher = "com.github.alecaddd.akira.desktop";
        application_id = "com.github.alecaddd.akira";
    }

    public void new_window () {
        new Akira.Window (this).present ();
    }

    protected override void activate () {
        var window = new Akira.Window (this);
        this.add_window (window);
    }
}
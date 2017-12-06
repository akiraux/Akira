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
    public class HeaderBar : Gtk.Box {
        private static HeaderBar? instance = null;
        public Gtk.HeaderBar headerbar;
        public Gtk.Box toolbar;
        public bool toggled { get; set; default = true; }

        private HeaderBar () {
            orientation = Gtk.Orientation.VERTICAL;

            build_headerbar ();
            build_toolbar ();
        }

        public static HeaderBar get_instance () {
            if (instance == null) {
                instance = new HeaderBar ();
            }

            return instance;
        }

        public void build_headerbar () {
            headerbar = new Gtk.HeaderBar ();

            headerbar.set_title (APP_NAME);
            headerbar.set_show_close_button (true);

            pack_start (headerbar, true, true, 0);

            //  headerbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            //  headerbar.get_style_context ().add_class ("headerbar");
        }

        private void build_toolbar () {
            toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            toolbar.margin_start = 20;
            toolbar.margin_end = 20;
            toolbar.margin_top = 10;
            toolbar.margin_bottom = 20;

            var icon_mode = new Granite.Widgets.ModeButton ();
            icon_mode.append_icon ("view-grid-symbolic", Gtk.IconSize.BUTTON);
            icon_mode.append_icon ("view-list-symbolic", Gtk.IconSize.BUTTON);
            icon_mode.append_icon ("view-column-symbolic", Gtk.IconSize.BUTTON);
            
            toolbar.add (icon_mode);

            pack_start (toolbar, true, true, 0);
        }

        public void toggle () {
            visible = !toggled;
            no_show_all = !toggled;
            
            toggled = !toggled;
        }
    }
}
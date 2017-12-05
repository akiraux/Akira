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
    public class HeaderBar : Gtk.HeaderBar {
        private static HeaderBar? instance = null;
        public bool toggled { get; set; default = true; }

        private HeaderBar () {
            set_title (APP_NAME);
            set_show_close_button (true);

            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            get_style_context ().add_class ("headerbar");

            build_ui ();
        }

        public static HeaderBar get_instance () {
            if (instance == null) {
                instance = new HeaderBar ();
            }

            return instance;
        }

        private void build_ui () {
            
        }

        public void toggle () {
            visible = !toggled;
            no_show_all = !toggled;
            
            toggled = !toggled;
        }
    }
}
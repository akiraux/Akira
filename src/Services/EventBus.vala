/*
 * Copyright (c) 2018 Alecaddd (http://alecaddd.com)
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
 * Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
 */
public class Akira.Services.EventBus : Object {
    public signal void update_icons_style ();
    public signal void align_items (string align_action);

    public EventBus () {
        Object ();
    }

    public void emit (string signal_id, string param = "") {
        switch (signal_id) {
            case "update-icons-style":
                update_icons_style ();
                break;
            case "align-items":
                align_items (param);
                break;
        }
    }
}

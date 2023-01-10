/*
* Copyright (c) 2020-2022 Alecaddd (https://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Alessandro "alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Akira.Models.ExportModel : GLib.Object {
    private unowned Akira.Lib.ViewCanvas _view_canvas;
    private Lib.Items.ModelInstance? _cached_instance = null;

    private Gdk.Pixbuf _pixbuf;
    public Gdk.Pixbuf pixbuf {
        get { return _pixbuf; }
    }

    private int id {
        get {
            return _cached_instance.id;
        }
    }

    private string name {
        get {
            return _cached_instance.components.name.name;
        }
    }

    // When exporting an arbitrary area, we don't have a model instance to update
    // so let's use a temporary string for this model.
    private string _area_filename = _("Selected area");
    public string filename {
        owned get {
            if (_cached_instance != null) {
                return _cached_instance.components.name.filename;
            }

            return _area_filename;
        }
        set {
            if (_cached_instance == null) {
                _area_filename = value;
                return;
            }

            if (_cached_instance.components.name.filename == value) {
                return;
            }

            unowned var im = _view_canvas.items_manager;
            var node = im.item_model.node_from_id (_cached_instance.id);
            assert (node != null);

            node.instance.components.name = new Lib.Components.Name (name, id.to_string (), value);
            im.item_model.alert_node_changed (node, Lib.Components.Component.Type.COMPILED_NAME);
            im.compile_model ();
        }
    }

    public ExportModel (Lib.ViewCanvas view_canvas, Lib.Items.ModelNode? node, Gdk.Pixbuf pixbuf) {
        _view_canvas = view_canvas;
        _pixbuf = pixbuf;
        if (node != null) {
            _cached_instance = node.instance;
        }
    }

    public void toggle_export_button (bool sensitive) {
        _view_canvas.window.event_bus.toggle_export_button (sensitive);
    }
}

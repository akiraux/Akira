






public class Akira.Lib.Managers.UndoManager : Object {

    private GLib.Queue<string> undos;
    private GLib.Queue<string> redos;

    public UndoManager () {
        undos = new GLib.Queue<string>();
        redos = new GLib.Queue<string>();
    }


    public void add_undo(Akira.Lib.Canvas canvas) {
        redos.clear ();
        inner_add_undo(Akira.FileFormat.JsonContent.serialize_canvas(canvas));
        debug("%d %d", (int)undos.get_length(), (int)redos.get_length());
    }

    public void apply_undo(Akira.Lib.Canvas canvas) {
        if (undos.get_length () == 0)  {
            debug("undo empty");
            return;
        }

        var old_undo = undos.pop_head();
        inner_add_redo(old_undo);

        try {
            var parser = new Json.Parser ();
            parser.load_from_data (old_undo);
            var obj = parser.get_root ().get_object ();

            clear_canvas(canvas);
            Akira.FileFormat.JsonLoader.inner_load_content(canvas, obj);

        } catch (Error e) {
            debug("failed to read undo");
            return;
        }

        debug("%d %d", (int)undos.get_length(), (int)redos.get_length());
    }

    private void inner_add_undo(string undo_to_add) {
      undos.push_head(undo_to_add);
    }

    private void inner_add_redo(string redo_to_add) {
      redos.push_head(redo_to_add);
    }

    public void apply_redo(Akira.Lib.Canvas canvas) {
        if (redos.get_length () == 0)  {
            debug("redo empty");
            return;
        }

        var old_redo = redos.pop_head();
        inner_add_undo(old_redo);


        try {
            var parser = new Json.Parser ();
            parser.load_from_data (old_redo);
            var obj = parser.get_root ().get_object ();

            clear_canvas(canvas);
            Akira.FileFormat.JsonLoader.inner_load_content(canvas, obj);

        } catch (Error e) {
            debug("failed to read redo");
            return;
        }

        debug("%d %d", (int)undos.get_length(), (int)redos.get_length());

    }

    private void clear_canvas(Akira.Lib.Canvas canvas) {
        var item_manager = canvas.window.items_manager;

        var to_delete = new GLib.Queue<Akira.Lib.Items.CanvasItem>();

        foreach (var item in item_manager.free_items) {
            to_delete.push_head(item);
        }

        foreach (var item in item_manager.artboards) {
            to_delete.push_head(item);
        }

        foreach (var item in item_manager.images) {
            to_delete.push_head(item);
        }

        while (to_delete.get_length () != 0) {
            canvas.window.event_bus.request_delete_item (to_delete.pop_head());
        }
    }

}

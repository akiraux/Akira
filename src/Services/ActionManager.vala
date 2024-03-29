/*
* Copyright (c) 2019-2020 Alecaddd (https://alecaddd.com)
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
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
* Authored by: Ivan "isneezy" Vilanculo <vilanculoivan@gmail.com>
*/

public class Akira.Services.ActionManager : Object {
    public weak Akira.Application app { get; construct; }
    public weak Akira.Window window { get; construct; }

    private const int PREVIEW_SIZE = 300;
    private const int PREVIEW_PADDING = 3;

    private Gtk.FileChooserNative dialog;
    private Gtk.Image preview_image;

    public SimpleActionGroup actions { get; construct; }

    public const string ACTION_PREFIX = "win.";
    public const string ACTION_NEW_WINDOW = "action_new_window";
    public const string ACTION_OPEN = "action_open";
    public const string ACTION_SAVE = "action_save";
    public const string ACTION_SAVE_AS = "action_save_as";
    public const string ACTION_LOAD_FIRST = "action_load_first";
    public const string ACTION_LOAD_SECOND = "action_load_second";
    public const string ACTION_LOAD_THIRD = "action_load_third";
    public const string ACTION_TOGGLE_PIXEL_GRID = "action-show-pixel-grid";
    public const string ACTION_PRESENTATION = "action_presentation";
    public const string ACTION_PREFERENCES = "action_preferences";
    public const string ACTION_EXPORT_SELECTION = "action_export_selection";
    public const string ACTION_EXPORT_ARTBOARDS = "action_export_artboards";
    public const string ACTION_EXPORT_GRAB = "action_export_grab";
    public const string ACTION_QUIT = "action_quit";
    public const string ACTION_ZOOM_IN = "action_zoom_in";
    public const string ACTION_ZOOM_IN_2 = "action_zoom_in_2";
    public const string ACTION_ZOOM_OUT = "action_zoom_out";
    public const string ACTION_ZOOM_RESET = "action_zoom_reset";
    public const string ACTION_MOVE_UP = "action_move_up";
    public const string ACTION_MOVE_DOWN = "action_move_down";
    public const string ACTION_MOVE_TOP = "action_move_top";
    public const string ACTION_MOVE_BOTTOM = "action_move_bottom";
    public const string ACTION_ARTBOARD_TOOL = "action_artboard_tool";
    public const string ACTION_RECT_TOOL = "action_rect_tool";
    public const string ACTION_ELLIPSE_TOOL = "action_ellipse_tool";
    public const string ACTION_TEXT_TOOL = "action_text_tool";
    public const string ACTION_IMAGE_TOOL = "action_image_tool";
    public const string ACTION_PATH_TOOL = "action_path_tool";
    public const string ACTION_DELETE = "action_delete";
    public const string ACTION_FLIP_H = "action_flip_h";
    public const string ACTION_FLIP_V = "action_flip_v";
    public const string ACTION_ESCAPE = "action_escape";
    public const string ACTION_SHORTCUTS = "action_shortcuts";
    public const string ACTION_PICK_COLOR = "action_pick_color";
    public const string ACTION_DUPLICATE = "action_duplicate";
    public const string ACTION_COPY = "action_copy";
    public const string ACTION_PASTE = "action_paste";
    public const string ACTION_ALIGN_LEFT = "action_align_left";
    public const string ACTION_ALIGN_RIGHT = "action_align_right";
    public const string ACTION_ALIGN_TOP = "action_align_top";
    public const string ACTION_ALIGN_BOTTOM = "action_align_bottom";
    public const string ACTION_ALIGN_VCENTER = "action_align_vcenter";
    public const string ACTION_ALIGN_HCENTER = "action_align_hcenter";
    public const string ACTION_UNDO = "action_undo";
    public const string ACTION_REDO = "action_redo";

    public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();
    public static Gee.MultiMap<string, string> typing_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_NEW_WINDOW, action_new_window },
        { ACTION_OPEN, action_open },
        { ACTION_SAVE, action_save },
        { ACTION_SAVE_AS, action_save_as },
        { ACTION_LOAD_FIRST, action_load_first },
        { ACTION_LOAD_SECOND, action_load_second },
        { ACTION_LOAD_THIRD, action_load_third },
        { ACTION_TOGGLE_PIXEL_GRID, action_toggle_pixel_grid },
        { ACTION_PRESENTATION, action_presentation },
        { ACTION_PREFERENCES, action_preferences },
        { ACTION_EXPORT_SELECTION, action_export_selection },
        { ACTION_EXPORT_ARTBOARDS, action_export_artboards },
        { ACTION_EXPORT_GRAB, action_export_grab },
        { ACTION_QUIT, action_quit },
        { ACTION_ZOOM_IN, action_zoom_in },
        { ACTION_ZOOM_IN_2, action_zoom_in_2 },
        { ACTION_ZOOM_OUT, action_zoom_out },
        { ACTION_MOVE_UP, action_move_up },
        { ACTION_MOVE_DOWN, action_move_down },
        { ACTION_MOVE_TOP, action_move_top },
        { ACTION_MOVE_BOTTOM, action_move_bottom },
        { ACTION_ZOOM_RESET, action_zoom_reset },
        { ACTION_ARTBOARD_TOOL, action_artboard_tool },
        { ACTION_RECT_TOOL, action_rect_tool },
        { ACTION_ELLIPSE_TOOL, action_ellipse_tool },
        { ACTION_TEXT_TOOL, action_text_tool },
        { ACTION_IMAGE_TOOL, action_image_tool },
        { ACTION_PATH_TOOL, action_path_tool },
        { ACTION_DELETE, action_delete },
        { ACTION_FLIP_H, action_flip_h },
        { ACTION_FLIP_V, action_flip_v },
        { ACTION_ESCAPE, action_escape },
        { ACTION_SHORTCUTS, action_shortcuts },
        { ACTION_PICK_COLOR, action_pick_color },
        { ACTION_DUPLICATE, action_duplicate },
        { ACTION_COPY, action_copy },
        { ACTION_PASTE, action_paste },
        { ACTION_ALIGN_LEFT, action_align_left },
        { ACTION_ALIGN_RIGHT, action_align_right },
        { ACTION_ALIGN_TOP, action_align_top },
        { ACTION_ALIGN_BOTTOM, action_align_bottom },
        { ACTION_ALIGN_VCENTER, action_align_vcenter },
        { ACTION_ALIGN_HCENTER, action_align_hcenter },
        { ACTION_UNDO, action_undo },
        { ACTION_REDO, action_redo },
    };

    public ActionManager (Akira.Application akira_app, Akira.Window window) {
        Object (
            app: akira_app,
            window: window
        );
    }

    static construct {
        action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
        action_accelerators.set (ACTION_OPEN, "<Control>o");
        action_accelerators.set (ACTION_SAVE, "<Control>s");
        action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
        action_accelerators.set (ACTION_LOAD_FIRST, "<Control><Alt>1");
        action_accelerators.set (ACTION_LOAD_SECOND, "<Control><Alt>2");
        action_accelerators.set (ACTION_LOAD_THIRD, "<Control><Alt>3");
        action_accelerators.set (ACTION_PRESENTATION, "<Control>period");
        action_accelerators.set (ACTION_PREFERENCES, "<Control>comma");
        action_accelerators.set (ACTION_EXPORT_SELECTION, "<Control><Alt>e");
        action_accelerators.set (ACTION_EXPORT_ARTBOARDS, "<Control><Alt>a");
        action_accelerators.set (ACTION_EXPORT_GRAB, "<Control><Alt>g");
        action_accelerators.set (ACTION_QUIT, "<Control>q");
        action_accelerators.set (ACTION_ZOOM_IN_2, "<Control>equal");
        action_accelerators.set (ACTION_ZOOM_IN, "<Control>plus");
        action_accelerators.set (ACTION_ZOOM_OUT, "<Control>minus");
        action_accelerators.set (ACTION_ZOOM_RESET, "<Control>0");
        action_accelerators.set (ACTION_MOVE_UP, "<Control>Up");
        action_accelerators.set (ACTION_MOVE_DOWN, "<Control>Down");
        action_accelerators.set (ACTION_MOVE_TOP, "<Control><Shift>Up");
        action_accelerators.set (ACTION_MOVE_BOTTOM, "<Control><Shift>Down");
        action_accelerators.set (ACTION_FLIP_H, "<Control>bracketleft");
        action_accelerators.set (ACTION_FLIP_V, "<Control>bracketright");
        action_accelerators.set (ACTION_SHORTCUTS, "F1");
        action_accelerators.set (ACTION_PICK_COLOR, "<Alt>c");
        action_accelerators.set (ACTION_DUPLICATE, "<Control>d");
        action_accelerators.set (ACTION_COPY, "<Control>c");
        action_accelerators.set (ACTION_PASTE, "<Control>v");
        action_accelerators.set (ACTION_ESCAPE, "Escape");

        typing_accelerators.set (ACTION_ARTBOARD_TOOL, "a");
        typing_accelerators.set (ACTION_RECT_TOOL, "r");
        typing_accelerators.set (ACTION_ELLIPSE_TOOL, "e");
        typing_accelerators.set (ACTION_TEXT_TOOL, "t");
        typing_accelerators.set (ACTION_IMAGE_TOOL, "i");
        typing_accelerators.set (ACTION_PATH_TOOL, "v");
        typing_accelerators.set (ACTION_DELETE, "Delete");
        typing_accelerators.set (ACTION_DELETE, "BackSpace");
        typing_accelerators.set (ACTION_TOGGLE_PIXEL_GRID, "<Shift>Tab");

        typing_accelerators.set (ACTION_ALIGN_LEFT, "<Alt>1");
        typing_accelerators.set (ACTION_ALIGN_HCENTER, "<Alt>2");
        typing_accelerators.set (ACTION_ALIGN_RIGHT, "<Alt>3");
        typing_accelerators.set (ACTION_ALIGN_TOP, "<Alt>4");
        typing_accelerators.set (ACTION_ALIGN_VCENTER, "<Alt>5");
        typing_accelerators.set (ACTION_ALIGN_BOTTOM, "<Alt>6");

        typing_accelerators.set (ACTION_UNDO, "<Control>z");
        typing_accelerators.set (ACTION_REDO, "<Control><Shift>z");
    }

    construct {
        actions = new SimpleActionGroup ();
        actions.add_action_entries (ACTION_ENTRIES, this);
        window.insert_action_group ("win", actions);

        var iter = action_accelerators.map_iterator ();
        while (iter.next ()) {
            app.set_accels_for_action (ACTION_PREFIX + iter.get_key (), { iter.get_value () });
        }

        enable_typing_accels ();

        window.event_bus.disconnect_typing_accel.connect (disable_typing_accels);
        window.event_bus.connect_typing_accel.connect (enable_typing_accels);
    }

    // Temporarily disable all the accelerators that might interfere with input fields.
    private void disable_typing_accels () {
        var iter = typing_accelerators.map_iterator ();
        while (iter.next ()) {
            app.set_accels_for_action (ACTION_PREFIX + iter.get_key (), {});
        }
    }

    // Enable all the accelerators that might interfere with input fields.
    private void enable_typing_accels () {
        var iter = typing_accelerators.map_iterator ();
        while (iter.next ()) {
            app.set_accels_for_action (ACTION_PREFIX + iter.get_key (), { iter.get_value () });
        }
    }

    private void action_quit () {
        window.before_destroy ();
    }

    private void action_presentation () {
        window.event_bus.toggle_presentation_mode ();
    }

    private void action_new_window () {
        app.new_window ();
    }

    private void action_open () {
        window.file_manager.open_file ();
    }

    private void action_save () {
        window.file_manager.save_file ();
    }

    private void action_save_as () {
        window.file_manager.save_file_as ();
    }

    public void action_load_first () {
        if (settings.recently_opened.length == 0 || settings.recently_opened[0] == null) {
            window.event_bus.canvas_notification (_("No recently opened file available!"));
            return;
        }

        var file = File.new_for_path (settings.recently_opened[0]);
        if (!file.query_exists ()) {
            window.event_bus.canvas_notification (
                _("Unable to open file at '%s'").printf (settings.recently_opened[0])
            );
            return;
        }

        File[] files = {};
        files += file;
        window.app.open (files, "");
    }

    private void action_load_second () {
        if (settings.recently_opened.length < 1 || settings.recently_opened[1] == null) {
            window.event_bus.canvas_notification (_("No second most recently opened file available!"));
            return;
        }

        var file = File.new_for_path (settings.recently_opened[1]);
        if (!file.query_exists ()) {
            window.event_bus.canvas_notification (
                _("Unable to open file at '%s'").printf (settings.recently_opened[1])
            );
            return;
        }

        File[] files = {};
        files += file;
        window.app.open (files, "");
    }

    private void action_load_third () {
        if (settings.recently_opened.length < 2 || settings.recently_opened[2] == null) {
            window.event_bus.canvas_notification (_("No third most recently opened file available!"));
            return;
        }

        var file = File.new_for_path (settings.recently_opened[2]);
        if (!file.query_exists ()) {
            window.event_bus.canvas_notification (
                _("Unable to open file at '%s'").printf (settings.recently_opened[2])
            );
            return;
        }

        File[] files = {};
        files += file;
        window.app.open (files, "");
    }

    private void action_toggle_pixel_grid () {
        window.event_bus.toggle_pixel_grid ();
    }

    private void action_preferences () {
        var settings_dialog = new Akira.Dialogs.SettingsDialog (window);
        settings_dialog.show_all ();
        settings_dialog.present ();
        settings_dialog.close.connect (() => {
            window.event_bus.set_focus_on_canvas ();
        });
    }

    private void action_export_selection () {
        unowned Akira.Lib.ViewCanvas canvas = window.main_window.main_view_canvas.canvas;
        canvas.export_selection.begin ();
    }

    private void action_export_artboards () {
        // Check if at least an artboard is present.
        window.main_window.main_view_canvas.trigger_notification (_("Export of Artboards currently unavailable…sorry 😑️"));
        // TODO: Trigger artboards pixbuf generation.
    }

    private void action_export_grab () {
        unowned Akira.Lib.ViewCanvas canvas = window.main_window.main_view_canvas.canvas;
        var new_mode = new Lib.Modes.ExportMode (canvas);
        canvas.mode_manager.register_mode (new_mode);
    }

    private void action_zoom_in () {
        window.event_bus.adjust_zoom (0.1, false, null);
    }

    private void action_zoom_in_2 () {
        action_zoom_in ();
    }

    private void action_zoom_out () {
        window.event_bus.adjust_zoom (-0.1, false, null);
    }

    private void action_zoom_reset () {
        window.event_bus.adjust_zoom (1, true, null);
    }

    private void action_move_up () {
        window.event_bus.change_z_selected (true, false);
    }

    private void action_move_down () {
        window.event_bus.change_z_selected (false, false);
    }

    private void action_move_top () {
        window.event_bus.change_z_selected (true, true);
    }

    private void action_move_bottom () {
        window.event_bus.change_z_selected (false, true);
    }

    private void action_artboard_tool () {
        window.event_bus.insert_item ("artboard");
    }

    private void action_rect_tool () {
        window.event_bus.insert_item ("rectangle");
    }

    // Delete the currently selected items.
    private void action_delete () {
        window.event_bus.delete_selected_items ();
    }

    private void action_flip_h () {
        window.event_bus.flip_item ();
    }

    private void action_flip_v () {
        window.event_bus.flip_item (true);
    }

    private void action_ellipse_tool () {
        window.event_bus.insert_item ("ellipse");
    }

    private void action_text_tool () {
        window.event_bus.insert_item ("text");
    }

    private void action_image_tool () {
        dialog = new Gtk.FileChooserNative (
            _("Choose image file"), window, Gtk.FileChooserAction.OPEN, _("Select"), _("Close"));

        preview_image = new Gtk.Image ();
        dialog.preview_widget = preview_image;
        dialog.update_preview.connect (on_update_preview);

        dialog.select_multiple = true;

        dialog.response.connect ((response_id) => on_choose_image_response (dialog, response_id));
        dialog.show ();
    }

    private void action_path_tool () {
        window.event_bus.insert_item ("path");
    }

    private void on_update_preview () {
        string? filename = dialog.get_preview_filename ();
        if (filename == null) {
            dialog.set_preview_widget_active (false);
            return;
        }

        // Read the image format data first.
        int width = 0;
        int height = 0;
        Gdk.PixbufFormat? format = Gdk.Pixbuf.get_file_info (filename, out width, out height);

        if (format == null) {
            dialog.set_preview_widget_active (false);
            return;
        }

        // If the image is too big, resize it.
        Gdk.Pixbuf pixbuf;
        try {
            pixbuf = new Gdk.Pixbuf.from_file_at_scale (filename, PREVIEW_SIZE, PREVIEW_SIZE, true);
        } catch (Error e) {
            dialog.set_preview_widget_active (false);
            return;
        }

        if (pixbuf == null) {
            dialog.set_preview_widget_active (false);
            return;
        }

        pixbuf = pixbuf.apply_embedded_orientation ();

        // Distribute the extra space around the image.
        int extra_space = PREVIEW_SIZE - pixbuf.width;
        int smaller_half = extra_space / 2;
        int larger_half = extra_space - smaller_half;

        // Pad the image manually and avoids rounding errors.
        preview_image.set_margin_start (PREVIEW_PADDING + smaller_half);
        preview_image.set_margin_end (PREVIEW_PADDING + larger_half);

        // Show the preview.
        preview_image.set_from_pixbuf (pixbuf);
        dialog.set_preview_widget_active (true);
    }

    private void on_choose_image_response (Gtk.FileChooserNative dialog, int response_id) {
        // switch (response_id) {
        //     case Gtk.ResponseType.ACCEPT:
        //     case Gtk.ResponseType.OK:
        //         SList<File> files = dialog.get_files ();
        //         files.@foreach ((file) => {
        //             if (!Akira.Utils.Image.is_valid_image (file)) {
        //                 window.event_bus.canvas_notification (
        //                     _("Error! .%s files are not supported!"
        //                 ).printf (Akira.Utils.Image.get_extension (file)));
        //                 return;
        //             }

        //             var manager = new Akira.Lib.Managers.ImageManager (file, files.index (file));
        //             window.items_manager.insert_image (manager);
        //         });
        //         break;
        // }
        dialog.destroy ();
    }

    private void action_escape () {
        window.event_bus.request_escape ();
        // If the layout is hidden, allow users to easily get out of presentation mode
        // when they press Escape.
        if (!window.headerbar.toggled) {
            action_presentation ();
        }
    }

    private void action_shortcuts () {
        var dialog = new Akira.Dialogs.ShortcutsDialog (window);
        dialog.show_all ();
        dialog.present ();
    }

    private void action_pick_color () {
        // weak Akira.Lib.Canvas canvas = window.main_window.main_canvas.canvas;

        // // Interrupt if no item is selected.
        // if (canvas.selected_bound_manager.selected_items.length () == 0) {
        //     return;
        // }

        // bool is_holding_shift = false;
        // var color_picker = new Akira.Widgets.ColorPicker ();
        // color_picker.show_all ();

        // color_picker.key_pressed.connect (e => {
        //     is_holding_shift = e.keyval == Gdk.Key.Shift_L;
        // });

        // color_picker.key_released.connect (e => {
        //     is_holding_shift = e.keyval == Gdk.Key.Shift_L;
        // });

        // color_picker.cancelled.connect (() => {
        //     color_picker.close ();
        // });

        // color_picker.picked.connect (color => {
        //     foreach (var item in canvas.selected_bound_manager.selected_items) {
        //         // Ignore the item if it doesn't have a fills or border component
        //         // based on the shift key pressed by the user.
        //         if ((item.fills == null && !is_holding_shift) || (item.borders == null && is_holding_shift)) {
        //             continue;
        //         }

        //         if (is_holding_shift) {
        //             item.borders.update_color_from_action (color);
        //             continue;
        //         }

        //         item.fills.update_color_from_action (color);
        //     }

        //     color_picker.close ();

        //     // Force a UI reload of the fills and borders panel since some items
        //     // had their properties changed.
        //     canvas.window.event_bus.selected_items_list_changed (canvas.selected_bound_manager.selected_items);
        // });
    }

    private void action_duplicate () {
        window.event_bus.request_duplicate ();
    }

    private void action_copy () {
        window.event_bus.request_copy ();
    }

    private void action_paste () {
        window.event_bus.request_paste ();
    }

    private void action_align_left () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.LEFT);
    }

    private void action_align_right () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.RIGHT);
    }

    private void action_align_top () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.TOP);
    }

    private void action_align_bottom () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.BOTTOM);
    }

    private void action_align_vcenter () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.VCENTER);
    }

    private void action_align_hcenter () {
        window.event_bus.selection_align (Utils.ItemAlignment.AlignmentDirection.HCENTER);
    }

    private void action_undo () {
        window.event_bus.undo ();
    }

    private void action_redo () {
        window.event_bus.redo ();
    }

    public static void action_from_group (string action_name, ActionGroup? action_group) {
        action_group.activate_action (action_name, null);
    }
}

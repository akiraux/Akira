/*
 * Copyright (c) 2021 Alecaddd (https://alecaddd.com)
 *
 * This file is part of Akira.
 *
 * Akira is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Akira is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Akira. If not, see <https://www.gnu.org/licenses/>.
 *
 * Authored by: Ashish Shevale <shevaleashish@gmail.com>
*/

public class Akira.Layouts.Partials.ArtboardSizesPanel : Gtk.Grid {
    private unowned Akira.Window window;

    private Gtk.Button add_category_btn;
    private Gtk.ListBox size_list_container;
    private GLib.ListStore list;
    // json object read from settings
    private string sizes_json;

    public bool toggled {
        get {
            return visible;
        } set {
            visible = value;
            no_show_all = !value;
        }
    }

    public ArtboardSizesPanel (Akira.Window window) {
        this.window = window;

        var title_cont = new Gtk.Grid ();
        title_cont.orientation = Gtk.Orientation.HORIZONTAL;
        title_cont.hexpand = true;
        title_cont.get_style_context ().add_class ("option-panel");

        var label = new Gtk.Label (_("Artboard Sizes"));
        label.halign = Gtk.Align.FILL;
        label.xalign = 0;
        label.hexpand = true;
        label.set_ellipsize (Pango.EllipsizeMode.END);

        add_category_btn = new Gtk.Button ();
        add_category_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        add_category_btn.can_focus = false;
        add_category_btn.valign = Gtk.Align.CENTER;
        add_category_btn.halign = Gtk.Align.CENTER;
        add_category_btn.set_tooltip_text (_("Create new size category"));
        add_category_btn.add (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR));

        size_list_container = new Gtk.ListBox ();
        size_list_container.margin_top = 5;
        size_list_container.margin_bottom = 15;
        size_list_container.margin_start = 10;
        size_list_container.margin_end = 5;
        size_list_container.selection_mode = Gtk.SelectionMode.NONE;
        size_list_container.get_style_context ().add_class ("fills-list");

        title_cont.attach (label, 0, 0, 1, 1);
        title_cont.attach (add_category_btn, 1, 0, 1, 1);

        list = new GLib.ListStore (Type.OBJECT);

        size_list_container.bind_model (list, item => {
            return create_category_expander ( (SizeCategoryItem) item );
        });

        attach (title_cont, 0, 0, 1, 1);
        attach (size_list_container, 0, 1, 1, 1);
        show_all ();

        add_category_btn.clicked.connect (handle_add_category);

        window.event_bus.insert_item.connect ( (item_type) => {
            reload_list ( (item_type == "artboard") );
        });

        window.event_bus.request_escape.connect ( () => {
            list.remove_all ();
            toggled = false;
        });

        toggled = false;
    }

    private void parse_json (string json_string) {

        Json.Parser parser = new Json.Parser ();
        try {
          parser.load_from_data (sizes_json);
        } catch (Error e) {
          print ("Unable to parse data: %s\n", e.message);
          return;
        }

        Json.Node node = parser.get_root ();
        Json.Reader reader = new Json.Reader (node);

        // the one and only key inside the json object is 'categories'
        bool tmp = reader.read_member ("categories");
        assert (tmp == true);
        assert (reader.is_object ());

        // get the list of all keys inside 'categories'
        // they represent the individual categories like 'Desktop', 'Mobile'
        string[] category_names = reader.list_members ();

        foreach (string category in category_names) {
            // read the current category
            tmp = reader.read_member (category);
            assert (tmp == true);
            assert (reader.is_object ());

            SizeCategoryItem category_item = new SizeCategoryItem (category);

            string[] device_names = reader.list_members ();
            // each category contains an object with name of the device as key
            // and the screen size as value
            foreach (string device_name in device_names) {
                // read the device name and its size array
                tmp = reader.read_member (device_name);
                assert (tmp == true);
                assert (reader.is_array ());

                var int_items = parse_array (reader);

                category_item.add_size (int_items, device_name);
            }

            list.append (category_item);
            reader.end_member ();
        }
        reader.end_member ();
    }

    private int[] parse_array (Json.Reader reader) {
        int[] parsed_ints = {};

        int members = reader.count_elements ();

        for (int i = 0; i < members; ++i) {
            reader.read_element (i);

            int item = (int) reader.get_int_value ();
            parsed_ints += item;

            reader.end_element ();
        }

        reader.end_element ();

        return parsed_ints;
    }

    private void recreate_categories_json () {
        Json.Builder builder = new Json.Builder ();

        builder.begin_object ();
        builder.set_member_name ("categories");
        builder.begin_object ();

        for (int j = 0; j < list.get_n_items (); ++j) {
            SizeCategoryItem item = list.get_item (j) as SizeCategoryItem;

            builder.set_member_name (item.category_name);
            builder.begin_object ();

            for (int i = 0; i < item.artboard_sizes.size; ++i) {
                builder.set_member_name (item.artboard_device_names[i]);

                builder.begin_array ();
                builder.add_int_value (item.artboard_sizes[i][0]);
                builder.add_int_value (item.artboard_sizes[i][1]);
                builder.end_array ();
            }

            builder.end_object ();
        }

        builder.end_object ();
        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);
        generator.set_pretty (true);

        settings.artboard_size_categories = generator.to_data (null);
    }

    private Gtk.Expander create_category_expander (SizeCategoryItem category) {

        // create expander for each category of sizes
        Gtk.Expander category_expander = new Gtk.Expander (category.category_name);
        category_expander.get_style_context ().add_class ("size-category-item");

        // create items inside each category
        Gtk.Grid size_items_grid = new Gtk.Grid ();
        for (int i = 0; i < category.artboard_sizes.size; ++i) {
            string button_label = """%s (%d x %d)""".printf (
                category.artboard_device_names[i],
                category.artboard_sizes[i][0],
                category.artboard_sizes[i][1]
            );

            Gtk.Button size_button = new Gtk.Button.with_label (button_label);
            size_button.height_request = 35;
            size_button.hexpand = true;
            size_button.get_style_context ().add_class ("artboard-size-button");

            size_button.clicked.connect ( () => {
                insert_artboard (size_button.label);
            });

            size_items_grid.attach (size_button, 0, i, 1, 1);
        }

        // this button is for adding new sizes to a category
        Gtk.Button add_size_button = new Gtk.Button.with_label ("Add a new size . . .");
        add_size_button.height_request = 35;
        add_size_button.hexpand = true;
        add_size_button.get_style_context ().add_class ("artboard-size-button");

        add_size_button.clicked.connect (() => {
            handle_add_size (category.category_name, add_size_button);
        });

        size_items_grid.attach (add_size_button, 0, category.artboard_sizes.size + 1, 1, 1);
        category_expander.add (size_items_grid);
        size_items_grid.show_all ();

        return category_expander;
    }

    private void insert_artboard (string label) {
        try {
            // create a regex object to match the sizes from label
            Regex reg = new Regex ("""\d+\sx\s\d+""");

            // match the label using regex
            MatchInfo match_info;
            if ( reg.match (label, 0, out match_info) ) {
                // the output we get after regex looks like "width x height"
                // get the actual width and height from it
                string[] split_string = Regex.split_simple ("""\sx\s""", match_info.fetch (0));

                double width = double.parse (split_string[0]);
                double height = double.parse (split_string[1]);

                var canvas = window.main_window.main_canvas.canvas;
                canvas.selected_bound_manager.reset_selection ();

                double pos_x, pos_y;
                get_new_artboard_pos (window.items_manager.artboards, width, height, out pos_x, out pos_y);

                window.items_manager.set_item_to_insert ("artboard");
                var new_artboard = window.items_manager.insert_item (pos_x, pos_y);
                new_artboard.size.width = width;
                new_artboard.size.height = height;

                canvas.selected_bound_manager.add_item_to_selection (new_artboard);
                canvas.update_canvas ();

                // amount of margin when artboard is inserted so that some background canvas is also visible
                double artboard_margin = double.max (width, height) / 10;
                // size of visible canvas
                double window_width = window.main_window.main_canvas.get_allocated_width ();
                double window_height = window.main_window.main_canvas.get_allocated_height ();

                // figure out the zoom level based on the window size and artboard size
                double scale_x = (double) (window_width - artboard_margin) / width;
                double scale_y = (double) (window_height - artboard_margin) / height;
                double final_scale = double.min (scale_x, scale_y);

                double old_scale = window.main_window.main_canvas.canvas.get_scale ();

                // first reset the zoom level to 100%
                window.event_bus.update_scale ( 1 - old_scale );
                // then zoom as per the calcuated level
                window.event_bus.update_scale ( final_scale - 1 );

                // use the position and size of artboard to scroll canvas so that new artboard is in the center
                canvas.convert_to_pixels (ref pos_x, ref pos_y);
                canvas.convert_to_pixels (ref width, ref height);

                pos_x = pos_x + width / 2 - window_width / 2;
                pos_y = pos_y + height / 2 - window_height / 2;

                window.main_window.main_canvas.main_scroll.hadjustment.value = pos_x;
                window.main_window.main_canvas.main_scroll.vadjustment.value = pos_y;
            }
        } catch (Error error) {
            print ("Regex error in ArtboardSizesPanel: %s\n", error.message);
        }
    }

    private void get_new_artboard_pos (
        Akira.Models.ListModel<Lib.Items.CanvasArtboard> artboards,
        double width,
        double height,
        out double pos_x,
        out double pos_y
    ) {
        // if there are no artboards present,
        if (artboards.get_n_items () == 0) {
            // default positions with 10% margins on top and bottom
            pos_x = width / 10;
            pos_y = height / 10;

            return;
        }

        // calculate the new canvas bounds from these
        Goo.CanvasBounds curr_bounds = Goo.CanvasBounds ();

        var previous_artboard = artboards.get_item (0) as Akira.Lib.Items.CanvasArtboard;

        // initially, the x coordinate will be the same as that of previously inserted artboard
        // with a little offset
        curr_bounds.x1 = previous_artboard.coordinates.x + previous_artboard.size.width + 10;
        // the new artboard will be at the same y coordinate as the previous artboard
        curr_bounds.y1 = previous_artboard.coordinates.y;
        curr_bounds.x2 = curr_bounds.x1 + width;
        curr_bounds.y2 = curr_bounds.y1 + height;

        // for every artboard check if there is overlap and move the new artboard
        foreach (var artboard in artboards) {
            Goo.CanvasBounds bounds;
            artboard.get_bounds (out bounds);
            update_pos_till_no_overlap (ref curr_bounds, bounds);
        }

        pos_x = curr_bounds.x1;
        pos_y = curr_bounds.y1;
    }

    private void update_pos_till_no_overlap (ref Goo.CanvasBounds curr_bounds, Goo.CanvasBounds bounds) {
        // check if there is overlap
        if (curr_bounds.x1 >= bounds.x2 || bounds.x1 >= curr_bounds.x2) {
            // exit loop if one artboard is completely to left of other
            return;
        }

        if (curr_bounds.y2 <= bounds.y1 || bounds.y2 <= curr_bounds.y1) {
            // exit loop is one artboard is completely below other
            return;
        }

        // if the artboard overlaps, then move the current artboard accordingly
        curr_bounds.x1 = bounds.x2 + 10;
    }

    private void handle_add_category () {
        Akira.Widgets.ArtboardPanelInsertPopover new_category_popup = new Akira.Widgets.ArtboardPanelInsertPopover (add_category_btn);
        new_category_popup.initialize_popover (false);

        new_category_popup.closed.connect ( ()=>{
            if (new_category_popup.item_name != "") {
                list.append (new SizeCategoryItem (new_category_popup.item_name));

                recreate_categories_json ();
            }
        });

        new_category_popup.popup ();
    }

    private void handle_add_size (string category_name, Gtk.Button add_button) {
        Akira.Widgets.ArtboardPanelInsertPopover new_size_popup = new Akira.Widgets.ArtboardPanelInsertPopover (add_button);
        new_size_popup.initialize_popover (true);

        new_size_popup.closed.connect ( ()=>{

            if (new_size_popup.item_name != "") {

                SizeCategoryItem dummy_item = new SizeCategoryItem (category_name);
                uint position;

                if ( list.find_with_equal_func (
                        dummy_item,
                        (a, b) => {
                            var _a = (SizeCategoryItem) a;
                            var _b = (SizeCategoryItem) b;

                            return (_a.category_name == _b.category_name);
                        },
                        out position) ) {
                    // add the new device name and its size to the list
                    int[] new_size = {new_size_popup.item_width, new_size_popup.item_height};

                    SizeCategoryItem list_item = list.get_item (position) as SizeCategoryItem;
                    list_item.add_size (new_size, new_size_popup.item_name);

                    recreate_categories_json ();
                    reload_list (true);
                }
            }
        });

        new_size_popup.popup ();
    }

    private void reload_list (bool show) {
        list.remove_all ();

        if (show) {
            toggled = true;
            // read the json object containing info about sizes and category names
            sizes_json = settings.artboard_size_categories;
            parse_json (sizes_json);

            show_all ();
        } else {
            toggled = false;
        }
    }
}

// this class represents a category of artboard sizes.
// since this will not be user elsewhere, it is private and has been placed here
private class SizeCategoryItem : Object {
    public string category_name;
    public Gee.ArrayList<GenericArray<int>> artboard_sizes;
    public Gee.ArrayList<string> artboard_device_names;

    public SizeCategoryItem (string _category_name) {
        category_name = _category_name;
        artboard_sizes = new Gee.ArrayList<GenericArray<int>> ();
        artboard_device_names = new Gee.ArrayList<string> ();
    }

    public void add_size (int[] new_size, string device_name) {
        GLib.GenericArray<int> array = new GLib.GenericArray<int> ();
        array.add (new_size[0]);
        array.add (new_size[1]);

        artboard_device_names.add (device_name);

        artboard_sizes.add (array);
    }
}

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
 public class Akira.Widgets.GradientEditor : Gtk.EventBox {
    // dimensions of GradientEditor that we will fetch after size has been allocated to it
    private int widget_width;
    private int widget_height;
    private int widget_x;
    private int widget_y;
    
    private ColorMode color_mode_widget;
    private Models.ColorModel model;
    private bool is_gradient_mode = false;

    // list to store all stop colors in order
    private Gee.ArrayList<StopColor> stop_colors;
    private StopColor selected_stop_color;
    
    // Cairo.Pattern to color the Canvas.Item
    private Cairo.Pattern gradient_pattern;

    public GradientEditor(ColorMode _color_mode_widget, Models.ColorModel _model) {
        color_mode_widget = _color_mode_widget;
        model = _model;

        set_hexpand(true);
        height_request = 35;

        set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        set_above_child(false);

        // the stop colors at start and end are fixed. StopColor has been defined at the end
        stop_colors = new Gee.ArrayList<StopColor>();
        stop_colors.insert(0, new StopColor("#000", 1, 0));
        stop_colors.insert(1, new StopColor("#fff", 1, 100));
        
        selected_stop_color = stop_colors[0];

        size_allocate.connect( () => {
        widget_width = get_allocated_width();
        widget_height = get_allocated_height();

        draw.connect_after ( (context) => {return redraw_editor(context);});
        
        button_press_event.connect( (event) => {return on_button_press(event);});
        button_release_event.connect ( (event) => {return on_button_release(event); });

        });

    }

    private bool redraw_editor(Cairo.Context context) {
        if (is_gradient_mode) {
            double center_y = widget_y + widget_height / 2;
            
            // line through the center. acts as a guideline for the user to place the stop colors   
            context.set_source_rgba(0,0,0,1);
            context.move_to(widget_x, center_y);
            context.line_to(widget_x + widget_width, center_y);
            context.stroke();

            foreach(var item in stop_colors) {
                double center_x = widget_x + item.position * widget_width / 100;
                double radius = 5;
            
                // outer circle of light color. 
                context.set_source_rgba(1,1,1,1);
                context.arc(center_x, center_y, radius + 2, 0, 2 * Math.PI);
                context.fill();
                
                // inner circle of dark color. contrast makes it easier to find stop colors.
                if(item.position == selected_stop_color.position) {
                    context.set_source_rgba(0, 0, 1, 1);
                } else {
                    context.set_source_rgba(0,0,0, 1);
                }
                context.arc(center_x, center_y, radius, 0, 2 * Math.PI);
                context.fill();
            }
            
            // here we are calling update style with the button_type argument as linear.
            // this is because in order to display a gradient at the background, anything other 
            // than "solid" can be used.
            //update_style("linear");
            if(color_mode_widget.color_mode_type == "linear") {
                update_style("linear");
            } else {
                update_style("radial");
            }
        }
        
        return false;
    }

    private bool on_button_press (Gdk.EventButton event) {
        if (is_gradient_mode) {
            var position = (event.x / widget_width) * 100;
            get_stop_color_at(position);
            
            // trigger redraw for the Editor. This renders the stop color 
            queue_draw_area(widget_x, widget_y, widget_width, widget_height);
        }
        
        // start the on motion event handler
        // this will drag the stop color around as long as the button is pressed
        motion_notify_event.connect( on_motion_event );
        
        return false;
    }

    private bool on_motion_event (Gdk.EventMotion event) {
        if(is_gradient_mode) {
            int index = stop_colors.index_of(selected_stop_color);
            
            if(index == 0 || index == stop_colors.size - 1) {
                return false;
            }
            
            stop_colors[index].position = (event.x / widget_width) * 100;
            
            queue_draw_area(widget_x, widget_y, widget_width, widget_height);
        }
        
        return false;
    }
    
    private bool on_button_release (Gdk.EventButton event) {
        // after user releases the button, stop dragging the stop color 
        motion_notify_event.disconnect (on_motion_event);
        
        return false;
    }

    public void on_color_changed(string color, double alpha) {
        int index = stop_colors.index_of(selected_stop_color);
        
        stop_colors[index].color = color;
        stop_colors[index].alpha = alpha;
        
        queue_draw_area(widget_x, widget_y, widget_width, widget_height);
    }
    
    public void delete_selected_step () {
        // get the index of selected step
        int index = stop_colors.index_of(selected_stop_color);
        
        // the first and stop colors are fixed and should not be deleted
        if(index == 0 || index == stop_colors.size - 1) {
            return;
        }
        
        selected_stop_color = stop_colors[index-1];
        stop_colors.remove_at(index);
        
        // redraw the new widget 
        queue_draw_area(widget_x, widget_y, widget_width, widget_height);
    }

    private void get_stop_color_at(double position) {
        int index;

        if(is_stop_color_at_coordinate(position, out index)) {
            selected_stop_color = stop_colors[index];
        } else {
            string prev_color = stop_colors[index].color;
            double prev_alpha = stop_colors[index].alpha;
            stop_colors.insert(index, new StopColor(prev_color, prev_alpha, position));
            selected_stop_color = stop_colors[index];
        }

    }
    
    private bool is_stop_color_at_coordinate(double coordinate, out int index) {
        index = 0;

        for(index = 0; index < stop_colors.size; ++index) {
            if(stop_colors[index].is_close_to(coordinate, widget_width)) {
                return true;
            } else if (stop_colors[index].position > coordinate) {
                return false;
            }
        }

        return false;
    }

    private void update_style(string button_type) {
        string css_style = "";
        string stop_color_string = stop_colors_as_string();

        if(button_type != "solid") {
            is_gradient_mode = true;
        } else {
            is_gradient_mode = false;
        }

        if(button_type == "solid") {
            css_style = "@bg_color";
        } else {
            css_style = """linear-gradient(to right %s)""".printf(stop_color_string);
        }
        
        try {
            var provider = new Gtk.CssProvider ();
            var context = get_style_context ();
            
            var editor_css_style = """*{
                background: %s
            }""".printf(css_style);

            provider.load_from_data (editor_css_style, editor_css_style.length);
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
        } catch (Error e) {
            warning ("Style error: %s", e.message);
            debug ("%s %s\n", name, css_style);
        }
        
        create_gradient_pattern(button_type);
    }

    private string stop_colors_as_string() {
        string colors_string = "";

        foreach(StopColor item in stop_colors) {
            //colors_string += ", " + "%s ".printf( item.color) + item.position.to_string() + "%";
            colors_string += "," + item.to_string();
        }
        
        return colors_string;
    }

    public void on_color_mode_changed () {
    
        if(color_mode_widget.color_mode_type != "solid") {
            is_gradient_mode = true;
        } else {
            is_gradient_mode = false;
        }
        
        update_style(color_mode_widget.color_mode_type);
    }
    
    private void create_gradient_pattern (string color_mode) {
        double item_height, item_width;
        model.get("height", out item_height);
        model.get("width", out item_width);
        
        if(color_mode == "solid") {
            // for solid color, create an empty pattern. In Fills, we check if stop colors exists
            // for this pattern. If they dont, then the Pattern is not applied
            gradient_pattern = new Cairo.Pattern.linear(0,0,0,0);
            model.pattern = gradient_pattern;
            return;
        } else if(color_mode == "linear") {
            gradient_pattern = new Cairo.Pattern.linear(0, 0, 
                                             item_width,  item_height);
        } else {
            int radius = (int) Math.sqrt( item_width * item_width + item_height * item_height);
            gradient_pattern = new Cairo.Pattern.radial(0, 0, 0, 0, 0, radius);
        }
        
        for(int index = 0; index < stop_colors.size; ++index) {
            var stop_color = stop_colors[index];
            
            var rgba = Gdk.RGBA();
            rgba.parse(stop_color.color);
            
            double offset = stop_color.position / 100;
            
            gradient_pattern.add_color_stop_rgba(offset, rgba.red, rgba.green, rgba.blue, stop_color.alpha);
        }
        
        model.pattern = gradient_pattern;
    }

    private class StopColor {
        public string color;
        // position denotes position of stop color in percentage
        public double position;
        public double alpha;

        public StopColor(string _color, double _alpha, double _position) {
            color = _color;
            position = _position;
            alpha = _alpha;
        }

        public bool is_close_to (double other_position, double width) {
            var distance = (position - other_position).abs();
            distance = (distance * width ) / 100;
            // there has to be a min distance between 2 stop colors to easily select them
            // this distance is taken as 7 because that is the radius the StopColor is drawn
            // in the gradient editor
            if( distance <= 7 ) {
                return true;
            }

            return false;
        }
        
        public string to_string() {
            Gdk.RGBA color_rgba = Gdk.RGBA();
            color_rgba.parse(color);
            
            int red = (int) (color_rgba.red * 255);
            int green = (int) (color_rgba.green * 255);
            int blue = (int) (color_rgba.blue * 255);
            int alpha = (int) (alpha * 255);
            
            return """ rgba(%d, %d, %d, %d) %f""".printf(red, green, blue, alpha, position) + "%";
        }
    }
}

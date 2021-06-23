public class Akira.Widgets.GradientEditor : Gtk.EventBox {
    // dimensions of GradientEditor that we will fetch after size has been allocated to it
    private int widget_width;
    private int widget_height;
    private int widget_x;
    private int widget_y;
    
    private ColorMode color_mode_widget;
    private bool is_gradient_mode = false;

    private Gdk.RGBA color;
    public string css_style;

    // list to store all stop colors in order
    private Gee.ArrayList<StopColor> stop_colors;
    private StopColor selected_stop_color;

    public GradientEditor(ColorMode _color_mode_widget) {
        color_mode_widget = _color_mode_widget;

        set_hexpand(true);
        height_request = 35;

        set_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        set_above_child(false);

        color.parse("#333");

        // the stop colors at start and end are fixed. StopColor has been defined at the end
        stop_colors = new Gee.ArrayList<StopColor>();
        stop_colors.insert(0, new StopColor("#000", 0));
        stop_colors.insert(1, new StopColor("#fff", 100));
        
        selected_stop_color = stop_colors[0];

        size_allocate.connect( () => {
        widget_width = get_allocated_width();
        widget_height = get_allocated_height();

        draw.connect_after ( (context) => {return redraw_editor(context);});
        
        button_press_event.connect( (event) => {return on_button_press(event);});

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
            update_style("linear");
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
        
        return false;
    }

    private bool on_motion_event (Gdk.EventMotion event) {

        return false;
    }

    private void on_button_release (Gdk.EventButton event) {
        motion_notify_event.disconnect (on_motion_event);
    }

    public void on_color_changed(string color, double alpha) {

    }

    private void get_stop_color_at(double position) {
        int index;

        if(is_stop_color_at_coordinate(position, out index)) {
            selected_stop_color = stop_colors[index];
        } else {
            string prev_color = stop_colors[index].color;
            stop_colors.insert(index, new StopColor(prev_color, position));
            selected_stop_color = stop_colors[index];
        }

    }
    
    private bool is_stop_color_at_coordinate(double coordinate, out int index) {
        index = 0;

        for(index = 0; index < stop_colors.size; ++index) {
            if(stop_colors[index].is_close_to(coordinate)) {
                return true;
            } else if (stop_colors[index].position > coordinate) {
                return false;
            }
        }

        return false;
    }

    private void update_style(string button_type) {
        css_style = "";
        string stop_color_string = stop_colors_as_string();

        if(button_type != "solid") {
            is_gradient_mode = true;
        } else {
            is_gradient_mode = false;
        }

        switch(button_type) {
            case "solid":
                color.parse("#333");
                css_style = """
                *{
                    background: none;
                    background-color: @bg_color;
                    border: none;
                }""";
                break;

            case "linear":
                color.parse("#212121");
                css_style = """
                * {
                    border: 1px solid @fg_color;
                    background: linear-gradient(to right%s);
                }""".printf( stop_color_string);
                break;
            case "radial":
                color.parse("#212121");
                css_style = """
                *{
                    border: 1px solid @fg_color;
                    background: linear-gradient(to right %s);
                }""".printf(stop_color_string);
            break;
        }

        try {
            var provider = new Gtk.CssProvider ();
            var context = get_style_context ();

            provider.load_from_data (css_style, css_style.length);
            context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Style error: %s", e.message);
            debug ("%s %s\n", name, css_style);
        }
    }

    private string stop_colors_as_string() {
        string colors_string = "";

        foreach(StopColor item in stop_colors) {
            colors_string += ", " + "%s ".printf( item.color) + item.position.to_string() + "%";
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

    private class StopColor {
        public string color;
        // position denotes position of stop color in percentage
        public double position;

        public StopColor(string _color, double _position) {
            color = _color;
            position = _position;
        }

        public bool is_close_to (double other_position) {
            // there has to be a min distance between 2 stop colors to easily select them
            if( (position - other_position).abs() < 1 ) {
                return true;
            }

            return false;
        }
    }
}

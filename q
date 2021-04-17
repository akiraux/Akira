[1mdiff --cc src/Lib/Canvas.vala[m
[1mindex 2244508,617ee5c..0000000[m
[1m--- a/src/Lib/Canvas.vala[m
[1m+++ b/src/Lib/Canvas.vala[m
[36m@@@ -318,16 -263,14 +310,27 @@@[m [mpublic class Akira.Lib.Canvas : Goo.Can[m
          mode_manager.register_mode (new_mode);[m
      }[m
  [m
[32m++<<<<<<< HEAD[m
[32m +    /**[m
[32m +     * Perform a series of updates after an item is created.[m
[32m +     */[m
[32m +    public void update_canvas () {[m
[32m +        // Update the pixel grid if it's visible in order to move it to the foreground.[m
[32m +        if (is_grid_visible) {[m
[32m +            update_pixel_grid ();[m
[32m +        }[m
[32m +        // Synchronous update to make sure item is initialized before any other event.[m
[32m +        update ();[m
[32m++=======[m
[32m+     public void on_escape_key () {[m
[32m+         mode_manager.deregister_active_mode ();[m
[32m+         // Clear the selected export area to be sure to not leave anything behind.[m
[32m+         export_manager.clear ();[m
[32m+         // Clear the image manager in case the user was adding an image.[m
[32m+         window.items_manager.image_manager = null;[m
[32m+ [m
[32m+         on_set_focus_on_canvas ();[m
[32m++>>>>>>> f01496c... Add behavior to escape key via ActionManager[m
      }[m
  [m
      public void on_set_focus_on_canvas () {[m

/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

public class Akira.Layouts.Partials.FillItem : Gtk.Grid {
  public signal void remove_item (Akira.Models.FillsItemModel model);

  public Akira.Models.FillsItemModel model { get; construct; }

  private Akira.Utils.BlendingMode blending_mode {
    owned get {
      return model.blending_mode;
    }
    set {
      model.blending_mode = value;
      selected_blending_mode.label = model.blending_mode.get_name ();
    }
  }

  private string color {
    owned get {
      return model.color;
    }
    set {
      model.color = value;

      set_selected_color_background ();
      set_color_chooser_color ();
    }
  }

  private new uint opacity {
    owned get {
      return model.opacity;
    }
    set {
      // Change only if value is different
      if ((uint) opacity_slider.get_value () != value) {
        opacity_slider.set_value (value);
      }

      model.opacity = value;
      current_opacity.label = "%d %%".printf ((int) value);
    }
  }

  private new bool visible {
    owned get {
      return model.visible;
    }
    set {
      model.visible = value;

      if (visible_button_icon != null) {
        visible_button.remove (visible_button_icon);
      }

      visible_button_icon = new Gtk.Image.from_icon_name (
        "layer-%s-symbolic".printf (model.visible ? "visible" : "hidden"),
        Gtk.IconSize.SMALL_TOOLBAR
        );

      visible_button.add (visible_button_icon);

      visible_button_icon.show_all ();
    }
  }

  private Gtk.Grid fill_chooser;
  private Gtk.Button visible_button;
  private Gtk.Button delete_button;
  private Gtk.Button show_options_button;
  private Gtk.Image visible_button_icon;
  private Gtk.Button selected_blending_mode_cont;
  private Gtk.Label selected_blending_mode;
  private Gtk.Button current_opacity_cont;
  private Gtk.Label current_opacity;
  private Gtk.Button selected_color;
  private Gtk.Popover popover;
  private Gtk.ListBox blending_mode_popover_items;
  private Gtk.Scale opacity_slider;
  private Gtk.Grid color_picker;
  private Gtk.ColorChooserWidget color_chooser_widget;

  public FillItem (Akira.Models.FillsItemModel model) {
    Object (
      model: model
      );
  }

  construct {
    create_ui ();

    // Update view BEFORE event bindings in order
    // not to trigger bindings on first assignment
    update_view ();

    create_event_bindings ();
    show_all ();
  }

  private void update_view () {
    opacity = model.opacity;
    visible = model.visible;
    blending_mode = model.blending_mode;
    color = model.color;
  }

  private void create_ui () {
    selected_blending_mode = new Gtk.Label ("");

    fill_chooser = new Gtk.Grid ();
    fill_chooser.hexpand = true;

    selected_color = new Gtk.Button ();
    selected_color.can_focus = false;
    selected_color.get_style_context ().add_class ("selected-color");

    selected_blending_mode = new Gtk.Label ("");
    selected_blending_mode.hexpand = true;
    selected_blending_mode.halign = Gtk.Align.START;

    selected_blending_mode_cont = new Gtk.Button ();
    selected_blending_mode_cont.get_style_context ().add_class ("flat");
    selected_blending_mode_cont.get_style_context ().add_class ("flat-btn");
    selected_blending_mode_cont.can_focus = false;
    selected_blending_mode_cont.hexpand = true;
    selected_blending_mode_cont.add (selected_blending_mode);

    show_options_button = new Gtk.Button ();
    show_options_button.can_focus = false;
    show_options_button.valign = Gtk.Align.CENTER;
    show_options_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    show_options_button.get_style_context ().add_class ("popover-toggler");

    show_options_button.add (new Gtk.Image.from_icon_name ("pan-down-symbolic",
                                                           Gtk.IconSize.SMALL_TOOLBAR));

    current_opacity = new Gtk.Label ("");
    current_opacity.halign = Gtk.Align.CENTER;
    current_opacity.width_chars = 5;
    current_opacity.get_style_context ().add_class ("opacity");

    current_opacity_cont = new Gtk.Button ();
    current_opacity_cont.can_focus = false;
    current_opacity_cont.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    current_opacity_cont.add (current_opacity);

    fill_chooser.attach (selected_color, 0, 0, 1, 1);
    fill_chooser.attach (selected_blending_mode_cont, 1, 0, 1, 1);
    fill_chooser.attach (show_options_button, 2, 0, 1, 1);
    fill_chooser.attach (current_opacity_cont, 3, 0, 1, 1);

    fill_chooser.get_style_context ().add_class ("fill-chooser");

    visible_button = new Gtk.Button ();
    visible_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    visible_button.can_focus = false;
    visible_button.valign = Gtk.Align.CENTER;

    delete_button = new Gtk.Button ();
    delete_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
    delete_button.can_focus = false;
    delete_button.valign = Gtk.Align.CENTER;
    delete_button.add (new Gtk.Image.from_icon_name ("user-trash-symbolic",
                                                     Gtk.IconSize.SMALL_TOOLBAR));

    blending_mode_popover_items = new Gtk.ListBox ();
    blending_mode_popover_items.get_style_context ().add_class ("popover-list");

    opacity_slider = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
    opacity_slider.hexpand = true;
    opacity_slider.digits = 0;
    opacity_slider.draw_value = false;
    opacity_slider.get_style_context ().add_class ("opacity-slider");

    color_chooser_widget = new Gtk.ColorChooserWidget ();
    color_chooser_widget.hexpand = true;
    color_chooser_widget.show_editor = true;

    color_picker = new Gtk.Grid ();
    color_picker.get_style_context ().add_class ("padding");
    color_picker.attach (color_chooser_widget, 0, 0, 1, 1);

    var popover_item_index = 0;

    foreach (Akira.Utils.BlendingMode mode in Akira.Utils.BlendingMode.all () ) {
      blending_mode_popover_items
        .insert (new Akira.Layouts.Partials.BlendingModeItem (mode), popover_item_index++);
    }

    popover = new Gtk.Popover (selected_blending_mode_cont);
    popover.position = Gtk.PositionType.BOTTOM;

    attach (fill_chooser, 0, 0, 1, 1);
    attach (visible_button, 1, 0, 1, 1);
    attach (delete_button, 2, 0, 1, 1);

    get_style_context ().add_class ("fill-chooser-cont");
  }

  private void create_event_bindings () {
    delete_button.clicked.connect (on_delete_item);
    visible_button.clicked.connect (toggle_visibility);

    blending_mode_popover_items.row_activated.connect (on_row_activated);
    blending_mode_popover_items.row_selected.connect (on_popover_item_selected);

    selected_blending_mode_cont.clicked.connect (() => { on_show_popover ("blending_mode"); });

    selected_color.clicked.connect (() => { on_show_popover ("color"); });
    color_chooser_widget.notify["rgba"].connect (on_color_changed);

    current_opacity_cont.clicked.connect (() => { on_show_popover ("opacity"); });
    opacity_slider.value_changed.connect (on_opacity_changed);

    show_options_button.clicked.connect (() => { on_show_popover ("blending_mode"); });

    model.notify.connect (on_model_changed);
  }

  private void on_color_changed () {
    var selectedColor = color_chooser_widget.rgba;

    color = "#%02X%02X%02X".printf (
      (int) (selectedColor.red * 255),
      (int) (selectedColor.green * 255),
      (int) (selectedColor.blue * 255)
    );
  }

  private void on_model_changed () {
    model.list_model.update_fills ();
  }

  private void on_row_activated (Gtk.ListBoxRow? item) {
    var fillItem = (Akira.Layouts.Partials.BlendingModeItem) item.get_child ();
    blending_mode = fillItem.mode;
    popover.hide ();
  }

  private void on_popover_item_selected (Gtk.ListBoxRow? item) {
  }

  private void on_show_popover (string target) {
    foreach (Gtk.Widget elem in popover.get_children ()) {
      popover.remove (elem);
    }

    switch (target) {
      case "blending_mode":
        popover.width_request = get_allocated_width ();
        popover.relative_to = selected_blending_mode_cont;
        popover.child = blending_mode_popover_items;
        break;

      case "opacity":
        popover.width_request = get_allocated_width ();
        popover.relative_to = current_opacity_cont;
        popover.child = opacity_slider;
        break;

      case "color":
        popover.width_request = get_allocated_width ();
        popover.relative_to = selected_color;
        popover.child = color_picker;
        break;
    }

    if (!popover.visible) {
      popover.show_all ();
    } else {
      popover.hide ();
    }
  }

  private void on_delete_item () {
    remove_item (model);
  }

  private void toggle_visibility () {
    visible = !visible;
  }

  private void on_opacity_changed (Gtk.Range slider) {
    opacity = (uint) slider.get_value ();
  }

  private void set_selected_color_background () {
    try {
      var provider = new Gtk.CssProvider ();
      var context = selected_color.get_style_context ();

      var css = """
        .selected-color {
          background-color: shade (%s, 1);
          border-color: shade (%s, 0.7);
        }
      """.printf (color, color);

      provider.load_from_data (css, css.length);

      context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    } catch (Error e) {
      warning ("Style error: %s", e.message);
    }
  }

  private void set_color_chooser_color () {
      var newRGBA = Gdk.RGBA ();
      newRGBA.parse (model.color);

      color_chooser_widget.set_rgba (newRGBA);
  }
}

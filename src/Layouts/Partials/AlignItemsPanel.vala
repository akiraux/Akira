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
public class Akira.Layouts.Partials.AlignItemsPanel : Gtk.Grid {
  public weak Akira.Window window { get; construct; }

  private Gtk.Grid alignment_box;
  private Gtk.Grid outer_box;

  struct AlignBoxItem {
    public string type;
    public string icon_name;
    public string action;
    public string title;

    public AlignBoxItem (string type, string action = "", string icon_name = "", string title = "") {
      this.type = type;
      this.action = action;
      this.icon_name = icon_name;
      this.title = title;
    }
  }

  public AlignItemsPanel (Akira.Window main_window) {
    Object (
      window: main_window,
      orientation: Gtk.Orientation.VERTICAL
    );
  }

  construct {
    vexpand = false;
    hexpand = true;

    outer_box = new Gtk.Grid ();

    outer_box.hexpand = true;
    outer_box.get_style_context ().add_class ("alignment-box");

    alignment_box = new Gtk.Grid ();
    alignment_box.halign = Gtk.Align.CENTER;

    AlignBoxItem[] alignBoxItems = {
      AlignBoxItem ("btn", "even-h", "distribute-horizontal-center", "Distribute centers evenly horizontally"),
      AlignBoxItem ("btn", "even-v", "distribute-vertical-center", "Distribute center evenly vertically"),
      AlignBoxItem ("sep"),
      AlignBoxItem ("btn", "alig-h-l", "align-horizontal-left", "Align left sides"),
      AlignBoxItem ("btn", "alig-h-c", "align-horizontal-center", "Center on horizontal axis"),
      AlignBoxItem ("btn", "alig-h-r", "align-horizontal-right", "Align right sides"),
      AlignBoxItem ("sep"),
      AlignBoxItem ("btn", "alig-v-t", "align-vertical-top", "Align top sides"),
      AlignBoxItem ("btn", "alig-v-c", "align-vertical-center", "Center on vertical axis"),
      AlignBoxItem ("btn", "alig-v-b", "align-vertical-bottom", "Align bottom sides")
    };

    int loop = 0;

    foreach (var item in alignBoxItems) {
      switch (item.type) {
        case "sep":
          alignment_box.attach ( new Gtk.Separator (Gtk.Orientation.VERTICAL), loop++, 0, 1, 1 );
          break;

        case "btn":
          var tmpAlignBoxButton = new Akira.Partials.AlignBoxButton (item.action, item.icon_name, item.title);

          tmpAlignBoxButton.triggered.connect (on_button_event);

          alignment_box.attach (tmpAlignBoxButton, loop++, 0, 1, 1);
          break;
      }
    }

    outer_box.attach (alignment_box, 1, 0, 1, 1);

    attach (outer_box, 1, 0, 1, 1);

    connect_signals ();
  }

  private void update_icons_style (string icon_style) {
    alignment_box.foreach ((child) => {
      if (child is Akira.Partials.AlignBoxButton) {
        var button = (Akira.Partials.AlignBoxButton) child;

        button.change_icon_style ();
      }
    });
  }

  private void connect_signals () {
    event_bus.update_icons_style.connect (() => {
      update_icons_style (settings.icon_style);
    });
  }

  private void on_button_event (Akira.Partials.AlignBoxButton button) {
    print ("Action Triggered: %s\n", button.action);
  }
}

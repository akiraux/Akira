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
 * Authored by: Giacomo Alberini <giacomoalbe@gmail.com>
 */

public enum InsertType {
  RECT,
  ELLIPSE,
  TEXT
}

public class Akira.Lib.Managers.ItemsManager : Object {
  private InsertType? insert_type { get; set; }

  public ItemsManager () {
    Object ();
  }

  construct {
    debug ("ItemsManager created");

    event_bus.insert_item.connect (insert_item);
  }

  public void set_insert_type_from_key (uint keyval) {
    // TODO: take those values from preferences/settings and not from hardcoded values
    switch (keyval) {
      case Gdk.Key.R:
        insert_item ("rectangle");
        break;

      case Gdk.Key.E:
        insert_item ("ellipse");
        break;

      case Gdk.Key.T:
        insert_item ("text");
        break;

    }
  }

  private void insert_item (string type) {
    debug (@"Adding $(type) item");

    switch (type) {
      case "rectangle":
        insert_type = InsertType.RECT;
        break;

      case "ellipse":
        insert_type = InsertType.ELLIPSE;
        break;

      case "text":
        insert_type = InsertType.TEXT;
        break;
    }
  }
}

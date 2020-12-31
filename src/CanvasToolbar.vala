/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
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
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;

public class CanvasToolbar : Toolbar {

  private CanvasItems _items;

  /* Constructor */
  public CanvasToolbar( CanvasItems items ) {

    _items = items;

    create_shapes();
    create_color();
    create_stroke_width();

    show_all();

  }

  /* Creates the shape toolbar item */
  private void create_shapes() {

    var icons = _items.shape_icons;
    var mb    = new MenuButton();
    mb.popup  = new Gtk.Menu();

    for( int i=0; i<icons.length; i++ ) {
      var menu_item   = new Gtk.MenuItem();
      var shape_index = i;
      menu_item.activate.connect(() => {
        _items.draw_index = shape_index;
      });
      menu_item.add( icons.index( i ) );
      mb.popup.add( menu_item );
    }

    mb.popup.show_all();

    var btn = new ToolItem();
    btn.set_tooltip_text( _( "Add Shape" ) );
    btn.add( mb );

    add( btn );

  }

  private void create_color() {

    var colors = new ColorButton();
    colors.color_set.connect(() => {
      _items.color = colors.rgba;
    });

    var btn = new ToolItem();
    btn.set_tooltip_text( _( "Item Color" ) );
    btn.add( colors );

    add( btn );

  }

  private void create_stroke_width() {

    var mb   = new MenuButton();
    mb.popup = new Gtk.Menu();

    for( int i=1; i<=4; i++ ) {
      var width     = i * 2;
      var menu_item = new Gtk.MenuItem.with_label( width.to_string() );
      menu_item.activate.connect(() => {
        _items.stroke_width = width;
        mb.label = width.to_string();
      });
      mb.popup.add( menu_item );
    }
    mb.popup.show_all();

    var btn = new ToolItem();
    btn.set_tooltip_text( _( "Stroke Width" ) );
    btn.add( mb );

    add( btn );

  }

}



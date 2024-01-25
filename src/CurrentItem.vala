/*
* Copyright (c) 2020-2021 (https://github.com/phase1geo/Annotator)
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

public class CurrentItem {

  private CanvasItemType _canvas = CanvasItemType.NONE;
  private CustomItem?    _custom = null;

  /* Default constructor */
  public CurrentItem() {}

  /* Constructor */
  public CurrentItem.with_canvas_item( CanvasItemType type ) {
    _canvas = type;
  }

  /* Constructor */
  public CurrentItem.with_custom_item( CustomItem item ) {
    _custom = item;
  }

  /* Sets the current item to a canvas item */
  public void canvas_item( CanvasItemType type ) {
    _canvas = type;
    _custom = null;
  }

  /* Sets the current item to a custom item */
  public void custom_item( CustomItem item ) {
    _canvas = CanvasItemType.NONE;
    _custom = item;
  }

  /* Adds the current item to the canvas */
  public void add_item( CanvasItems items ) {
    if( _canvas != CanvasItemType.NONE ) {
      items.add_shape_item( _canvas );
    } else if( _custom != null ) {
      var it = _custom.item.duplicate();
      it.bbox = items.center_box( it.bbox.width, it.bbox.height );
      items.add_item( it, -1, true );
    }
  }

  public Image? get_image( MainWindow win ) {
    if( _canvas != CanvasItemType.NONE ) {
      var image = new Image.from_icon_name( _canvas.icon_name( win.dark_mode ) );
      win.theme_changed.connect((dark_mode) => {
        image.icon_name = _canvas.icon_name( dark_mode );
      });
      return( image );
    } else if( _custom != null ) {
      return( _custom.get_image( win ) );
    }
    return( null );
  }

}

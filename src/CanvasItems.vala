/*
* Copyright (c) 2020 (https://github.com/phase1geo/Annotator)
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
using Gdk;
using Cairo;

public class CanvasItems {

  private Canvas           _canvas;
  private List<CanvasItem> _items;
  private CanvasItem?      _active         = null;
  private int              _selector_index = -1;
  private double           _last_x;
  private double           _last_y;
  private int              _draw_index     = -1;
  private RGBA             _color          = {1.0, 1.0, 1.0, 1.0};
  private int              _stroke_width   = 5;
  private Array<string>    _shape_icons;

  public int draw_index {
    get {
      return( _draw_index );
    }
    set {
      if( _draw_index != value ) {
        _draw_index = value;
        if( _draw_index != -1 ) {
          clear_selection();
        }
      }
    }
  }
  public bool draw_text {
    get {
      return( _draw_index == 5 );
    }
    set {
      _draw_index = value ? 5 : -1;
      if( _draw_index != -1 ) {
        clear_selection();
      }
    }
  }
  public RGBA color {
    get {
      return( _color );
    }
    set {
      if( !_color.equal( value ) ) {
        _color = value;
        update_selected_attributes();
      }
    }
  }
  public int stroke_width {
    get {
      return( _stroke_width );
    }
    set {
      if( _stroke_width != value ) {
        _stroke_width = value;
        update_selected_attributes();
      }
    }
  }

  /* Constructor */
  public CanvasItems( Canvas canvas ) {

    _canvas = canvas;

    /* Create storage for the canvas items */
    _items = new List<CanvasItem>();

    /* Load the shapes */
    _shape_icons = new Array<string>();
    _shape_icons.append_val( "rect-stroke-symbolic" );
    _shape_icons.append_val( "rect-fill-symbolic" );
    _shape_icons.append_val( "circle-stroke-symbolic" );
    _shape_icons.append_val( "circle-fill-symbolic" );
    _shape_icons.append_val( "arrow-symbolic" );

  }

  /* Returns the number of shapes that we support */
  public int num_shapes() {
    return( (int)_shape_icons.length );
  }

  /* Returns the shape of the icon */
  public Image get_shape_icon( int index ) {
    return( new Image.from_icon_name( _shape_icons.index( index ), IconSize.LARGE_TOOLBAR ) );
  }

  /* Adds the given shape to the top of the item stack */
  private void add_shape_item( double x, double y ) {
    switch( draw_index ) {
      case 0  :  _active = new CanvasItemRect(   x, y, false, color, stroke_width );  break;
      case 1  :  _active = new CanvasItemRect(   x, y, true,  color, stroke_width );  break;
      case 2  :  _active = new CanvasItemCircle( x, y, false, color, stroke_width );  break;
      case 3  :  _active = new CanvasItemCircle( x, y, true,  color, stroke_width );  break;
      case 4  :  _active = new CanvasItemArrow( x, y, color, stroke_width );          break;
      case 5  :  _active = new CanvasItemText( _canvas, x, y, color );                break;
      default :  assert_not_reached();
    }
    _items.append( _active );
  }

  /* Removes all of the canvas items */
  private void clear() {
    while( _items.first() != null ) {
      _items.delete_link( _items.first() );
    }
    _canvas.queue_draw();
  }

  /* Deletes all of the selected items */
  private bool remove_selected() {
    var retval = false;
    for( unowned List<CanvasItem> item=_items.first(); item!=null; item=item.next ) {
      if( item.data.mode == CanvasItemMode.SELECTED ) {
        _items.delete_link( item );
        _canvas.set_cursor( null );
        retval = true;
      }
    }
    return( retval );
  }

  /* Clears the currently selected items */
  public void clear_selection() {
    _selector_index = -1;
    foreach( CanvasItem item in _items ) {
      item.mode = CanvasItemMode.NONE;
    }
  }

  /* Update the selected attributes */
  private void update_selected_attributes() {
    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        item.color        = color;
        item.stroke_width = stroke_width;
      }
    }
    _canvas.queue_draw();
  }

  /* Handles keypress events */
  public bool key_pressed( uint keyval, ModifierType state ) {

    switch( keyval ) {
      case Key.BackSpace :
      case Key.Delete    :  return( remove_selected() );
    }

    return( false );

  }

  /*
   Called whenever the cursor is pressed.  Returns true if the canvas should
   draw itself.
  */
  public bool cursor_pressed( double x, double y, ModifierType state ) {

    /* If we need to draw a shape, create the shape at the given coordinates */
    if( draw_index != -1 ) {
      clear_selection();
      add_shape_item( x, y );

    /* Otherwise, see if we clicked on an item */
    } else {

      _active = null;

      foreach( CanvasItem item in _items ) {
        _selector_index = item.is_within_selector( x, y );
        if( _selector_index != -1 ) {
          _active = item;
          return( false );
        }
        if( item.is_within( x, y ) ) {
          _active      = item;
          _active.mode = CanvasItemMode.SELECTED;
          _canvas.set_cursor_from_name( "grabbing" );
          return( true );
        }
      }

      /* If we didn't click on anything, clear the selection */
      if( _active == null ) {
        clear_selection();
      }

    }

    return( false );

  }

  /*
   Called whenever the cursor is moved.  Returns true if the canvas should draw
   itself.
  */
  public bool cursor_moved( double x, double y, ModifierType state ) {

    var diff_x = x - _last_x;
    var diff_y = y - _last_y;

    _last_x = x;
    _last_y = y;

    /* If we are drawing something, resize the item */
    if( (draw_index != -1) && (_active != null) ) {
      _active.resize( diff_x, diff_y );
      return( true );

    /* Since we pressed on a selector, move the selector */
    } else if( _selector_index != -1 ) {
      _active.move_selector( _selector_index, diff_x, diff_y );
      return( true );

    /* Otherwise, move any selected items by the given amount */
    } else if( _active != null ) {
      var retval = false;
      foreach( CanvasItem item in _items ) {
        if( item.mode == CanvasItemMode.SELECTED ) {
          item.move_item( diff_x, diff_y );
          retval = true;
        }
      }
      return( retval );

    /* Otherwise, we are just moving the cursor around the screen */
    } else {
      foreach( CanvasItem item in _items ) {
        if( item.mode == CanvasItemMode.SELECTED ) {
          var sel_index = item.is_within_selector( x, y );
          if( sel_index != -1 ) {
            _canvas.set_cursor( item.get_selector_cursor( sel_index ) );
            return( false );
          }
        }
      }
      foreach( CanvasItem item in _items ) {
        if( item.is_within( x, y ) ) {
          _canvas.set_cursor_from_name( "grab" );
          return( false );
        }
      }
      _canvas.set_cursor( null );
    }

    return( false );

  }

  /*
   Called whenever the cursor button is released.  Returns true if the canvas
   should draw itself.
  */
  public bool cursor_released( double x, double y, ModifierType state ) {

    /* If we were drawing a shape, select the shape */
    if( draw_index != -1 ) {
      draw_index = -1;
      _active.mode = CanvasItemMode.SELECTED;
      _active      = null;
      _canvas.grab_focus();
      return( true );

    /* If we are finished dragging the selector, clear it */
    } else if( _selector_index != -1 ) {
      _selector_index = -1;
      _active         = null;
    }

    /* Clear the active element */
    _active = null;

    /* Clear the cursor */
    _canvas.set_cursor( null );

    /* Make sure that the canvas has input focus */
    _canvas.grab_focus();

    return( false );

  }

  /* Draws all of the canvas items on the given context */
  public void draw( Context ctx ) {
    foreach( CanvasItem item in _items ) {
      item.draw_item( ctx );
    }
    foreach( CanvasItem item in _items ) {
      item.draw_selectors( ctx );
    }
  }

}



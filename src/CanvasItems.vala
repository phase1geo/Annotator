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
  private CanvasRect?      _select_box       = null;
  private int              _draw_index       = -1;
  private RGBA             _fill             = {1.0, 1.0, 1.0, 1.0};
  private RGBA             _stroke           = {1.0, 1.0, 1.0, 1.0};
  private int              _stroke_width     = 4;

  public Array<Image> shape_icons  { get; private set; default = new Array<Image>(); }
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
  public RGBA fill {
    get {
      return( _fill );
    }
    set {
      if( !_fill.equal( value ) ) {
        _fill = value;
        update_selected_attributes();
      }
    }
  }
  public RGBA stroke {
    get {
      return( _stroke );
    }
    set {
      if( !_stroke.equal( value ) ) {
        _stroke = value;
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
    shape_icons.append_val( new Image.from_icon_name( "media-playback-stop-symbolic", IconSize.SMALL_TOOLBAR ) );

  }

  /* Adds the given shape to the top of the item stack */
  private void add_shape_item( double x, double y ) {
    switch( draw_index ) {
      case 0  :  _active = new CanvasItemRect( x, y, fill, stroke, stroke_width );  break;
      default :  assert_not_reached();
    }
    _items.append( _active );
  }

  /* Converts the selection box into something that can be compared and drawn */
  private Cairo.Rectangle convert_select_box() {
    Cairo.Rectangle box = {
      ((_select_box.width  < 0) ? (_select_box.x + _select_box.width)  : _select_box.x),
      ((_select_box.height < 0) ? (_select_box.y + _select_box.height) : _select_box.y),
      ((_select_box.width  < 0) ? (0 - _select_box.width)  : _select_box.width),
      ((_select_box.height < 0) ? (0 - _select_box.height) : _select_box.height)
    };
    return( box );
  }

  /* Clears the currently selected items */
  public void clear_selection() {
    _selector_index = -1;
    foreach( CanvasItem item in _items ) {
      item.mode = CanvasItemMode.NONE;
    }
  }

  /* Selects all items in the canvas that are within the given selection box */
  private void select_items_within() {
    CanvasRect box;
    _select_box.normalize( out box );
    foreach( CanvasItem item in _items ) {
      item.mode = item.is_within_box( box ) ? CanvasItemMode.SELECTED : CanvasItemMode.NONE;
    }
  }

  /* Update the selected attributes */
  private void update_selected_attributes() {
    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        item.fill         = fill;
        item.stroke       = stroke;
        item.stroke_width = stroke_width;
      }
    }
    _canvas.queue_draw();
  }

  /*
   Called whenever the cursor is pressed.  Returns true if the canvas should
   draw itself.
  */
  public bool cursor_pressed( double x, double y ) {

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

      /* If we didn't click on anything, draw out a selection box */
      if( _active == null ) {
        clear_selection();
        _select_box = new CanvasRect.from_coords( x, y, 0.0, 0.0 );
      }

    }

    return( false );

  }

  /*
   Called whenever the cursor is moved.  Returns true if the canvas should draw
   itself.
  */
  public bool cursor_moved( double x, double y ) {

    var diff_x = x - _last_x;
    var diff_y = y - _last_y;

    _last_x = x;
    _last_y = y;

    /*
     If we are drawing out a selection box, draw the box and select any items
     that are within the selection box.
    */
    if( _select_box != null ) {
      _select_box.width  += diff_x;
      _select_box.height += diff_y;
      select_items_within();
      return( true );

    /* If we are drawing something, item */
    } else if( (draw_index != -1) && (_active != null) ) {
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
  public bool cursor_released( double x, double y ) {

    /* If we are drawing out a selection box, stop it */
    if( _select_box != null ) {
      _select_box = null;
      return( true );

    /* If we were drawing a shape, select the shape */
    } else if( draw_index != -1 ) {
      draw_index = -1;
      _active.mode = CanvasItemMode.SELECTED;
      _active      = null;
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

    return( false );

  }

  /* Draws the selection box */
  private void draw_select_box( Context ctx ) {

    if( _select_box == null ) return;

    CanvasRect box;
    var        blue = Utils.color_from_string( "light blue" );

    _select_box.normalize( out box );

    Utils.set_context_color_with_alpha( ctx, blue, 0.5 );
    ctx.set_line_width( 1 );
    ctx.rectangle( box.x, box.y, box.width, box.height );
    ctx.fill();

  }

  /* Draws all of the canvas items on the given context */
  public void draw( Context ctx ) {
    foreach( CanvasItem item in _items ) {
      item.draw( ctx );
    }
    draw_select_box( ctx );
  }

}



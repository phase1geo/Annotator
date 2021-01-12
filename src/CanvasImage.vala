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
using Gdk;
using Cairo;

public class CanvasImage {

  private const int selector_size = 10;

  private Pixbuf?       _buf        = null;
  private ImageSurface? _surface    = null;
  private CanvasRect?   _crop_rect  = new CanvasRect();
  private int           _crop_index = -1;
  private Canvas        _canvas;
  private double        _last_x     = 0;
  private double        _last_y     = 0;

  public bool     cropping { get; private set; default = false; }
  public Exporter exporter { get; private set; }

  public signal void crop_ended();

  /* Constructor */
  public CanvasImage( Canvas canvas ) {
    _canvas  = canvas;
    exporter = new Exporter( canvas );
  }

  /* Returns true if the surface image has been set */
  public bool is_surface_set() {
    return( _surface != null );
  }

  /* Returns the dimensions of the stored image */
  public void get_dimensions( out int width, out int height ) {
    width  = _buf.width;
    height = _buf.height;
  }

  /* Draws a blur in the given rectangle onto the provided context */
  public void draw_blur_rectangle( Cairo.Context ctx, CanvasRect rect, int blur_radius = 10 ) {

    var x       = (rect.x < 0) ? 0 : (int)rect.x;
    var y       = (rect.y < 0) ? 0 : (int)rect.y;
    var w       = ((rect.x + rect.width)  >= _buf.width)  ? (_buf.width  - (int)rect.x) : (int)rect.width;
    var h       = ((rect.y + rect.height) >= _buf.height) ? (_buf.height - (int)rect.y) : (int)rect.height;
    var sub     = new Pixbuf.subpixbuf( _buf, x, y, w, h );
    var surface = cairo_surface_create_from_pixbuf( sub, 1, null );
    var buffer  = new Granite.Drawing.BufferSurface.with_surface( w, h, surface );

    /* Copy the surface contents over */
    buffer.context.set_source_surface( surface, 0, 0 );
    buffer.context.paint();

    /* Perform the blur */
    buffer.exponential_blur( blur_radius );

    /* Draw the blurred pixbuf onto the context */
    ctx.set_source_surface( buffer.surface, x, y );
    ctx.paint();

  }

  /* Returns the RGBA color value that averages the colors in the given rectangle */
  public RGBA get_average_color( CanvasRect rect ) {

    var x     = (rect.x < 0) ? 0 : (int)rect.x;
    var y     = (rect.y < 0) ? 0 : (int)rect.y;
    var w     = ((rect.x + rect.width)  >= _buf.width)  ? (_buf.width  - (int)rect.x) : (int)rect.width;
    var h     = ((rect.y + rect.height) >= _buf.height) ? (_buf.height - (int)rect.y) : (int)rect.height;
    var sub   = new Pixbuf.subpixbuf( _buf, x, y, w, h );
    var color = Granite.Drawing.Utilities.average_color( sub );

    RGBA rgba = {color.R, color.G, color.B, color.A};
    return( rgba );

  }

  /* Pastes an image from the given pixbuf to the canvas */
  public void set_image( Pixbuf buf ) {

    _buf     = buf.copy();
    _surface = (ImageSurface)cairo_surface_create_from_pixbuf( _buf, 1, null );
    _canvas.set_size_request( _buf.width, _buf.height );

  }

  /****************************************************************************/
  //  EVENT HANDLERS
  /****************************************************************************/

  /* Handles a keypress event */
  public bool key_pressed( uint keyval, ModifierType state ) {

    switch( keyval ) {
      case Key.Return :  return( end_crop() );
      case Key.Escape :  return( cancel_crop() );
    }

    return( false );

  }

  /* Handles a cursor press event */
  public bool cursor_pressed( double x, double y, ModifierType state, int press_count ) {

    var rect = new CanvasRect();

    _last_x     = x;
    _last_y     = y;
    _crop_index = -2;

    if( cropping ) {
      for( int i=0; i<8; i++ ) {
        selector_bbox( i, rect );
        if( rect.contains( x, y ) ) {
          _crop_index = i;
          return( true );
        }
      }
      if( _crop_rect.contains( x, y ) ) {
        _crop_index = -1;
        _canvas.set_cursor_from_name( "grabbing" );
      }
    }

    return( false );

  }

  /* Handles a cursor motion event */
  public bool cursor_moved( double x, double y, ModifierType state ) {

    var diffx = x - _last_x;
    var diffy = y - _last_y;
    var box   = new CanvasRect.from_rect( _crop_rect );

    _last_x = x;
    _last_y = y;

    /* If we clicked into the crop rectangle, move the rectangle */
    if( _crop_index == -1 ) {
      box.x += diffx;
      box.y += diffy;
      if( (box.x >= 0) &&
          (box.y >= 0) &&
          ((box.x + box.width) <= _buf.width) &&
          ((box.y + box.height) <= _buf.height) ) {
        _crop_rect.copy( box );
        return( true );
      }

    /* If we are dragging a selector box, handle the move and resize */
    } else if( _crop_index >= 0 ) {
      switch( _crop_index ) {
        case 0  :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
        case 1  :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
        case 2  :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
        case 3  :                                    box.width += diffx;  box.height += diffy;  break;
        case 4  :                   box.y += diffy;                       box.height -= diffy;  break;
        case 5  :                                                         box.height += diffy;  break;
        case 6  :  box.x += diffx;                   box.width -= diffx;                        break;
        case 7  :                                    box.width += diffx;                        break;
        default :  assert_not_reached();
      }
      if( (box.width  >= (selector_size * 3)) &&
          (box.height >= (selector_size * 3)) &&
          (box.width  <= _buf.width) &&
          (box.height <= _buf.height) ) {
        _crop_rect.copy( box );
        return( true );
      }

    /* If we are hovering over a crop selector, change the cursor */
    } else {
      var rect = new CanvasRect();
      for( int i=0; i<8; i++ ) {
        selector_bbox( i, rect );
        if( rect.contains( x, y ) ) {
          switch( i ) {
            case 0 :  _canvas.set_cursor( CursorType.UL_ANGLE );     return( false );
            case 1 :  _canvas.set_cursor( CursorType.UR_ANGLE );     return( false );
            case 2 :  _canvas.set_cursor( CursorType.LL_ANGLE );     return( false );
            case 3 :  _canvas.set_cursor( CursorType.LR_ANGLE );     return( false );
            case 4 :  _canvas.set_cursor( CursorType.TOP_SIDE );     return( false );
            case 5 :  _canvas.set_cursor( CursorType.BOTTOM_SIDE );  return( false );
            case 6 :  _canvas.set_cursor( CursorType.LEFT_SIDE );    return( false );
            case 7 :  _canvas.set_cursor( CursorType.RIGHT_SIDE );   return( false );
          }
        }
      }
      _canvas.set_cursor( null );
    }

    return( false );

  }

  /* Handles a cursor release event */
  public bool cursor_released( double x, double y, ModifierType state ) {

    _crop_index = -2;
    _canvas.set_cursor( null );

    return( false );

  }

  /****************************************************************************/
  //  CROP HANDLING CODE
  /****************************************************************************/

  /* Start the cropping function */
  public void start_crop() {
    cropping = true;
    _crop_rect.copy_coords( 0, 0, _buf.width, _buf.height );
  }

  /* Cancels the crop operation */
  public bool cancel_crop() {
    cropping = false;
    _canvas.queue_draw();
    crop_ended();
    return( true );
  }

  /* Completes the cropping operation */
  public bool end_crop() {
    cropping = false;
    var buf = new Pixbuf.subpixbuf( _buf, (int)_crop_rect.x, (int)_crop_rect.y, (int)_crop_rect.width, (int)_crop_rect.height );
    set_image( buf );
    _canvas.items.adjust_items( _crop_rect.x, _crop_rect.y );
    _canvas.queue_draw();
    crop_ended();
    return( true );
  }

  /* Make sure that everything is cleared from the image */
  private void clean_image() {
    cropping = false;
    _canvas.items.clear_selection();
    _canvas.queue_draw();
  }

  /* Exports to the given image type */
  public void export_image( ExportType type, string? filename = null ) {
    clean_image();
    exporter.export_image( _surface, type, filename );
  }

  /* Exports the image to the clipboard */
  public void export_clipboard() {
    clean_image();
    exporter.export_clipboard( _surface );
  }

  /* Exports the image to the printer */
  public void export_print() {
    clean_image();
    exporter.export_print( _surface );
  }

  /* Calculates the box for the given selector */
  private void selector_bbox( int index, CanvasRect rect ) {

    switch( index ) {
      case 0 :  // UL
      case 1 :  // UR
      case 2 :  // LL
      case 3 :  // LR
        rect.x = ((index & 1) == 0) ? _crop_rect.x1() : (_crop_rect.x2() - selector_size);
        rect.y = ((index & 2) == 0) ? _crop_rect.y1() : (_crop_rect.y2() - selector_size);
        break;
      case 4 :  // TOP
      case 5 :  // BOTTOM
        rect.x = _crop_rect.mid_x() - (selector_size / 2);
        rect.y = (index == 4) ? _crop_rect.y1() : (_crop_rect.y2() - selector_size);
        break;
      case 6 :  // LEFT
      case 7 :  // RIGHT
        rect.x = (index == 6) ? _crop_rect.x1() : (_crop_rect.x2() - selector_size);
        rect.y = _crop_rect.mid_y() - (selector_size / 2);
        break;
    }

    rect.width  = selector_size;
    rect.height = selector_size;

  }

  /* Draw the image being annotated */
  private void draw_image( Context ctx ) {
    ctx.set_source_surface( _surface, 0, 0 );
    ctx.paint();
  }

  /* Draws the drop_outline */
  private void draw_crop_outline( Context ctx, RGBA color ) {

    var width  = _buf.width;
    var height = _buf.height;

    Utils.set_context_color_with_alpha( ctx, color, 0.5 );

    ctx.rectangle( 0, 0, _crop_rect.x1(), height );
    ctx.fill();

    ctx.rectangle( _crop_rect.x1(), 0, _crop_rect.width, _crop_rect.y1() );
    ctx.fill();

    ctx.rectangle( _crop_rect.x1(), _crop_rect.y2(), _crop_rect.width, (height - _crop_rect.y2()) );
    ctx.fill();

    ctx.rectangle( _crop_rect.x2(), 0, (width - _crop_rect.x2()), height );
    ctx.fill();

  }

  /* Draws the thirds dividers when cropping */
  private void draw_crop_dividers( Context ctx, RGBA color ) {

    var third_width  = _crop_rect.width  / 3;
    var third_height = _crop_rect.height / 3;

    Utils.set_context_color_with_alpha( ctx, color, 0.5 );
    ctx.set_line_width( 1 );

    /* Draw vertical lines */
    ctx.move_to( (_crop_rect.x1() + third_width), _crop_rect.y1() );
    ctx.line_to( (_crop_rect.x1() + third_width), _crop_rect.y2() );
    ctx.stroke();

    ctx.move_to( (_crop_rect.x2() - third_width), _crop_rect.y1() );
    ctx.line_to( (_crop_rect.x2() - third_width), _crop_rect.y2() );
    ctx.stroke();

    /* Draw horizontal lines */
    ctx.move_to( _crop_rect.x1(), (_crop_rect.y1() + third_height) );
    ctx.line_to( _crop_rect.x2(), (_crop_rect.y1() + third_height) );
    ctx.stroke();

    ctx.move_to( _crop_rect.x1(), (_crop_rect.y2() - third_height) );
    ctx.line_to( _crop_rect.x2(), (_crop_rect.y2() - third_height) );
    ctx.stroke();

  }

  /* Draws the cropping selectors */
  private void draw_crop_selectors( Context ctx ) {

    var blue  = Utils.color_from_string( "light blue" );
    var black = Utils.color_from_string( "black" );
    var rect  = new CanvasRect();

    for( int i=0; i<8; i++ ) {

      selector_bbox( i, rect );

      Utils.set_context_color( ctx, blue );
      ctx.rectangle( rect.x, rect.y, rect.width, rect.height );
      ctx.fill_preserve();

      Utils.set_context_color( ctx, black );
      ctx.set_line_width( 1 );
      ctx.stroke();

    }

  }

  /* Draw the cropping area if we are in that mode */
  private void draw_cropping( Context ctx ) {
    if( !cropping ) return;
    var color = get_average_color( _crop_rect );
    draw_crop_outline( ctx, color );
    draw_crop_dividers( ctx, color );
    draw_crop_selectors( ctx );
  }

  /* Draws the image */
  public void draw( Context ctx ) {
    draw_image( ctx );
    draw_cropping( ctx );
  }

}



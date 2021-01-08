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

  public bool cropping { get; private set; default = false; }

  /* Constructor */
  public CanvasImage( Canvas canvas ) {
    _canvas = canvas;
  }

  /* Returns true if the surface image has been set */
  public bool is_surface_set() {
    return( _surface != null );
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

  /* Handles a cursor press event */
  public bool cursor_pressed( double x, double y, ModifierType state, int press_count ) {

    var rect = new CanvasRect();

    _last_x     = x;
    _last_y     = y;
    _crop_index = -1;

    if( cropping ) {
      for( int i=0; i<4; i++ ) {
        selector_bbox( i, rect );
        if( rect.contains( x, y ) ) {
          _crop_index = i;
          return( true );
        }
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

    if( _crop_index != -1 ) {
      switch( _crop_index ) {
        case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
        case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
        case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
        case 3 :                                    box.width += diffx;  box.height += diffy;  break;
        default :  assert_not_reached();
      }
      if( (box.width >= (selector_size * 3)) && (box.height >= (selector_size * 3)) ) {
        _crop_rect.copy( box );
        return( true );
      }
    }

    return( false );

  }

  /* Handles a cursor release event */
  public bool cursor_released( double x, double y, ModifierType state ) {
    _crop_index = -1;
    return( false );
  }

  /* Start the cropping function */
  public void start_crop() {
    cropping = true;
    _crop_rect.copy_coords( 0, 0, _buf.width, _buf.height );
    _canvas.queue_draw();
  }

  /* Cancels the crop operation */
  public void cancel_crop() {
    cropping = false;
    _canvas.queue_draw();
  }

  /* Completes the cropping operation */
  public void end_crop() {
    cropping = false;
    var buf = new Pixbuf.subpixbuf( _buf, (int)_crop_rect.x, (int)_crop_rect.y, (int)_crop_rect.width, (int)_crop_rect.height );
    set_image( buf );
    _canvas.queue_draw();
  }

  /* Calculates the box for the given selector */
  private void selector_bbox( int index, CanvasRect rect ) {
    rect.x      = ((index & 1) == 0) ? _crop_rect.x1() : (_crop_rect.x2() - selector_size);
    rect.y      = ((index & 2) == 0) ? _crop_rect.y1() : (_crop_rect.y2() - selector_size);
    rect.width  = selector_size;
    rect.height = selector_size;
  }

  /* Draw the image being annotated */
  private void draw_image( Context ctx ) {
    ctx.set_source_surface( _surface, 0, 0 );
    ctx.paint();
  }

  /* Draws the drop_outline */
  private void draw_crop_outline( Context ctx ) {

    var black  = Utils.color_from_string( "black" );
    var width  = _buf.width;
    var height = _buf.height;

    Utils.set_context_color_with_alpha( ctx, black, 0.5 );

    ctx.rectangle( 0, 0, _crop_rect.x1(), height );
    ctx.fill();

    ctx.rectangle( _crop_rect.x1(), 0, _crop_rect.width, _crop_rect.y1() );
    ctx.fill();

    ctx.rectangle( _crop_rect.x1(), _crop_rect.y2(), _crop_rect.width, (height - _crop_rect.y2()) );
    ctx.fill();

    ctx.rectangle( _crop_rect.x2(), 0, (width - _crop_rect.x2()), height );
    ctx.fill();

  }

  /* Draws the cropping selectors */
  private void draw_crop_selectors( Context ctx ) {

    var blue  = Utils.color_from_string( "light blue" );
    var black = Utils.color_from_string( "black" );
    var rect  = new CanvasRect();

    for( int i=0; i<4; i++ ) {

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
    draw_crop_outline( ctx );
    draw_crop_selectors( ctx );
  }

  /* Draws the image */
  public void draw( Context ctx ) {
    draw_image( ctx );
    draw_cropping( ctx );
  }

}



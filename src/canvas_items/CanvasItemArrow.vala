/*s
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

public class CanvasItemArrow : CanvasItem {

  private enum ArrowHeadDirection {
    UPPER_LEFT,
    UPPER_RIGHT,
    LOWER_LEFT,
    LOWER_RIGHT
  }

  private enum PType {
    HD = 0,  // Head
    PP,      // Primary peak
    PV,      // Primary valley
    TL,      // Tail
    SV,      // Secondary valley
    SP       // Secondary peak
  }

  private double             _valley_c = 30;           // Distance from head to valley point
  private double             _valley_a = Math.PI / 8;  // Angle between valley_c and spine
  private double             _peak_c   = 50;           // Distance from head to peak point
  private double             _peak_a   = Math.PI / 4;  // Angle between peak_c and spine
  private ArrowHeadDirection _dir      = ArrowHeadDirection.UPPER_LEFT;

  /* Constructor */
  public CanvasItemArrow( double x, double y, RGBA color, int stroke_width ) {

    base( "arrow", x, y, color, stroke_width );

    points.append_val( new CanvasPoint( true ) );
    points.append_val( new CanvasPoint( true ) );
    points.append_val( new CanvasPoint( true ) );
    points.append_val( new CanvasPoint( true ) );
    points.append_val( new CanvasPoint( false ) );
    points.append_val( new CanvasPoint( false ) );

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    double pvw, pvh, ppw, pph;
    double svw, svh, spw, sph;

    /* Calculate the peak and valley width and height */
    calc_flight_point( _valley_a, _valley_c, true,  out pvw, out pvh );
    calc_flight_point( _peak_a,   _peak_c,   true,  out ppw, out pph );
    calc_flight_point( _valley_a, _valley_c, false, out svw, out svh );
    calc_flight_point( _peak_a,   _peak_c,   false, out spw, out sph );

    switch( _dir ) {
      case ArrowHeadDirection.UPPER_LEFT :
        points.index( PType.HD ).copy_coords( bbox.x1(), bbox.y1() );
        points.index( PType.TL ).copy_coords( bbox.x2(), bbox.y2() );
        points.index( PType.PP ).copy_coords( (bbox.x1() + ppw), (bbox.y1() + pph) );
        points.index( PType.PV ).copy_coords( (bbox.x1() + pvw), (bbox.y1() + pvh) );
        points.index( PType.SP ).copy_coords( (bbox.x1() + spw), (bbox.y1() + sph) );
        points.index( PType.SV ).copy_coords( (bbox.x1() + svw), (bbox.y1() + svh) );
        break;
      case ArrowHeadDirection.LOWER_LEFT :
        points.index( PType.HD ).copy_coords( bbox.x1(), bbox.y2() );
        points.index( PType.TL ).copy_coords( bbox.x2(), bbox.y1() );
        points.index( PType.PP ).copy_coords( (bbox.x1() + ppw), (bbox.y2() - pph) );
        points.index( PType.PV ).copy_coords( (bbox.x1() + pvw), (bbox.y2() - pvh) );
        points.index( PType.SP ).copy_coords( (bbox.x1() + spw), (bbox.y2() - sph) );
        points.index( PType.SV ).copy_coords( (bbox.x1() + svw), (bbox.y2() - svh) );
        break;
      case ArrowHeadDirection.UPPER_RIGHT :
        points.index( PType.HD ).copy_coords( bbox.x2(), bbox.y1() );
        points.index( PType.TL ).copy_coords( bbox.x1(), bbox.y2() );
        points.index( PType.PP ).copy_coords( (bbox.x2() - ppw), (bbox.y1() + pph) );
        points.index( PType.PV ).copy_coords( (bbox.x2() - pvw), (bbox.y1() + pvh) );
        points.index( PType.SP ).copy_coords( (bbox.x2() - spw), (bbox.y1() + sph) );
        points.index( PType.SV ).copy_coords( (bbox.x2() - svw), (bbox.y1() + svh) );
        break;
      case ArrowHeadDirection.LOWER_RIGHT :
        points.index( PType.HD ).copy_coords( bbox.x2(), bbox.y2() );
        points.index( PType.TL ).copy_coords( bbox.x1(), bbox.y1() );
        points.index( PType.PP ).copy_coords( (bbox.x2() - ppw), (bbox.y2() - pph) );
        points.index( PType.PV ).copy_coords( (bbox.x2() - pvw), (bbox.y2() - pvh) );
        points.index( PType.SP ).copy_coords( (bbox.x2() - spw), (bbox.y2() - sph) );
        points.index( PType.SV ).copy_coords( (bbox.x2() - svw), (bbox.y2() - svh) );
        break;
    }

  }

  /* Calculates the width and height values for a peak/valley which are used in adjusting the selector */
  private void calc_flight_point( double a, double c, bool primary, out double width, out double height ) {

    var spine_a = Math.atan( bbox.height / bbox.width );

    width  = Math.cos( primary ? (spine_a + a) : (spine_a - a) ) * c;
    height = Math.sin( primary ? (spine_a + a) : (spine_a - a) ) * c;

  }

  /* Adjusts the valley/peak length and angle based on the placement of the associated selector */
  private void adjust_flight_point( int selector_index, ref double a, ref double c ) {

    var point = points.index( selector_index );
    var width = 0.0, height = 0.0;

    /* Calculate _valley_c (length from head) */
    switch( _dir ) {
      case ArrowHeadDirection.UPPER_LEFT  :  width = point.x - bbox.x1();  height = point.y - bbox.y1();  break;
      case ArrowHeadDirection.LOWER_LEFT  :  width = point.x - bbox.x1();  height = bbox.y2() - point.y;  break;
      case ArrowHeadDirection.UPPER_RIGHT :  width = bbox.x2() - point.x;  height = point.y - bbox.y1();  break;
      case ArrowHeadDirection.LOWER_RIGHT :  width = bbox.x2() - point.x;  height = bbox.y2() - point.y;  break;
      default                             :  assert_not_reached();
    }

    var angle = Math.atan( height / width );
    a = angle - Math.atan( bbox.height / bbox.width );
    c = height / Math.sin( angle );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy ) {

    double w = 0, h = 0;

    var box  = new CanvasRect.from_rect( bbox );
    var head = new CanvasPoint.from_point( points.index( PType.HD ) );
    var tail = new CanvasPoint.from_point( points.index( PType.TL ) );

    switch( index ) {
      case PType.HD :  head.x += diffx;  head.y += diffy;  break;
      case PType.TL :  tail.x += diffx;  tail.y += diffy;  break;
      case PType.PP :
        points.index( PType.PP ).x += diffx;
        points.index( PType.PP ).y += diffy;
        adjust_flight_point( PType.PP, ref _peak_a, ref _peak_c );
        calc_flight_point( _peak_a, _peak_c, false, out w, out h );
        break;
      case PType.PV :
        points.index( PType.PV ).x += diffx;
        points.index( PType.PV ).y += diffy;
        adjust_flight_point( PType.PV, ref _valley_a, ref _valley_c );
        calc_flight_point( _valley_a, _valley_c, false, out w, out h );
        break;
      default :  assert_not_reached();
    }

    if( head.x < tail.x ) {
      if( head.y < tail.y ) {
        switch( index ) {
          case PType.HD :  box.x = head.x;  box.y = head.y;  box.width -= diffx;  box.height -= diffy;  break;
          case PType.TL :                                    box.width += diffx;  box.height += diffy;  break;
          case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x1() + w), (bbox.y1() + h) );  break;
          case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x1() + w), (bbox.y1() + h) );  break;
        }
        _dir = ArrowHeadDirection.UPPER_LEFT;
      } else {
        switch( index ) {
          case PType.HD :  box.x = head.x;                   box.width -= diffx;  box.height += diffy;  break;
          case PType.TL :                   box.y = tail.y;  box.width += diffx;  box.height -= diffy;  break;
          case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x1() + w), (bbox.y2() - h) );  break;
          case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x1() + w), (bbox.y2() - h) );  break;
        }
        _dir = ArrowHeadDirection.LOWER_LEFT;
      }
    } else if( head.y < tail.y ) {
      switch( index ) {
        case PType.HD :                   box.y = head.y;  box.width += diffx;  box.height -= diffy;  break;
        case PType.TL :  box.x = tail.x;                   box.width -= diffx;  box.height += diffy;  break;
        case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x2() - w), (bbox.y1() + h) );  break;
        case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x2() - w), (bbox.y1() + h) );  break;
      }
      _dir = ArrowHeadDirection.UPPER_RIGHT;
    } else {
      switch( index ) {
        case PType.HD :                                    box.width += diffx;  box.height += diffy;  break;
        case PType.TL :  box.x = tail.x;  box.y = tail.y;  box.width -= diffx;  box.height -= diffy;  break;
        case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x2() - w), (bbox.y2() - h) );  break;
        case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x2() - w), (bbox.y2() - h) );  break;
      }
      _dir = ArrowHeadDirection.LOWER_RIGHT;
    }

    bbox = box;

  }

  /* Performs resize operation */
  public override void resize( double diffx, double diffy ) {
    move_selector( PType.TL, diffx, diffy );
  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.TCROSS );
  }

  public override bool is_within( double x, double y ) {
    return( Utils.is_within_polygon( x, y, points ) );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    Utils.set_context_color( ctx, color );

    ctx.set_line_width( 1 );
    ctx.new_path();
    ctx.move_to( points.index( 0 ).x, points.index( 0 ).y );
    for( int i=1; i<6; i++ ) {
      ctx.line_to( points.index( i ).x, points.index( i ).y );
    }
    ctx.close_path();
    ctx.fill_preserve();

    var outline = Granite.contrasting_foreground_color( color );
    Utils.set_context_color_with_alpha( ctx, outline, 0.5 );
    ctx.stroke();

  }

}



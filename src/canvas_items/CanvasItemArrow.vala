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

  private double             _valley_c = 30;           // Distance from head to valley point
  private double             _valley_a = Math.PI / 8;  // Angle between valley_c and spine
  private double             _peak_c   = 50;           // Distance from head to peak point
  private double             _peak_a   = Math.PI / 4;  // Angle between peak_c and spine
  private ArrowHeadDirection _dir      = ArrowHeadDirection.UPPER_LEFT;

  /* Constructor */
  public CanvasItemArrow( double x, double y, RGBA color, int stroke_width ) {

    base( "arrow", x, y, color, stroke_width );

    selects.append_val( new CanvasPoint() );  // Head
    selects.append_val( new CanvasPoint() );  // Tail
    selects.append_val( new CanvasPoint() );  // Valley
    selects.append_val( new CanvasPoint() );  // Peak

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    double vw, vh;
    double pw, ph;

    /* Calculate the peak and valley width and height */
    calc_flight_point( _valley_a, _valley_c, true, out vw, out vh );
    calc_flight_point( _peak_a,   _peak_c,   true, out pw, out ph );

    switch( _dir ) {
      case ArrowHeadDirection.UPPER_LEFT :
        selects.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
        selects.index( 1 ).copy_coords( bbox.x2(), bbox.y2() );
        selects.index( 2 ).copy_coords( (bbox.x1() + vw), (bbox.y1() + vh) );
        selects.index( 3 ).copy_coords( (bbox.x1() + pw), (bbox.y1() + ph) );
        break;
      case ArrowHeadDirection.LOWER_LEFT :
        selects.index( 0 ).copy_coords( bbox.x1(), bbox.y2() );
        selects.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
        selects.index( 2 ).copy_coords( (bbox.x1() + vw), (bbox.y2() - vh) );
        selects.index( 3 ).copy_coords( (bbox.x1() + pw), (bbox.y2() - ph) );
        break;
      case ArrowHeadDirection.UPPER_RIGHT :
        selects.index( 0 ).copy_coords( bbox.x2(), bbox.y1() );
        selects.index( 1 ).copy_coords( bbox.x1(), bbox.y2() );
        selects.index( 2 ).copy_coords( (bbox.x2() - vw), (bbox.y1() + vh) );
        selects.index( 3 ).copy_coords( (bbox.x2() - pw), (bbox.y1() + ph) );
        break;
      case ArrowHeadDirection.LOWER_RIGHT :
        selects.index( 0 ).copy_coords( bbox.x2(), bbox.y2() );
        selects.index( 1 ).copy_coords( bbox.x1(), bbox.y1() );
        selects.index( 2 ).copy_coords( (bbox.x2() - vw), (bbox.y2() - vh) );
        selects.index( 3 ).copy_coords( (bbox.x2() - pw), (bbox.y2() - ph) );
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

    var point = selects.index( selector_index );
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

    var box  = new CanvasRect.from_rect( bbox );
    var head = new CanvasPoint.from_point( selects.index( 0 ) );
    var tail = new CanvasPoint.from_point( selects.index( 1 ) );

    switch( index ) {
      case 0  :  head.x += diffx;  head.y += diffy;  break;
      case 1  :  tail.x += diffx;  tail.y += diffy;  break;
      case 2  :
        selects.index( 2 ).x += diffx;
        selects.index( 2 ).y += diffy;
        adjust_flight_point( 2, ref _valley_a, ref _valley_c );
        return;
      case 3  :
        selects.index( 3 ).x += diffx;
        selects.index( 3 ).y += diffy;
        adjust_flight_point( 3, ref _peak_a, ref _peak_c );
        return;
      default :  assert_not_reached();
    }

    if( head.x < tail.x ) {
      if( head.y < tail.y ) {
        switch( index ) {
          case 0 :  box.x = head.x;  box.y = head.y;  box.width -= diffx;  box.height -= diffy;  break;
          case 1 :                                    box.width += diffx;  box.height += diffy;  break;
        }
        _dir = ArrowHeadDirection.UPPER_LEFT;
      } else {
        switch( index ) {
          case 0 :  box.x = head.x;                   box.width -= diffx;  box.height += diffy;  break;
          case 1 :                   box.y = tail.y;  box.width += diffx;  box.height -= diffy;  break;
        }
        _dir = ArrowHeadDirection.LOWER_LEFT;
      }
    } else if( head.y < tail.y ) {
      switch( index ) {
        case 0 :                   box.y = head.y;  box.width += diffx;  box.height -= diffy;  break;
        case 1 :  box.x = tail.x;                   box.width -= diffx;  box.height += diffy;  break;
      }
      _dir = ArrowHeadDirection.UPPER_RIGHT;
    } else {
      switch( index ) {
        case 0 :                                    box.width += diffx;  box.height += diffy;  break;
        case 1 :  box.x = tail.x;  box.y = tail.y;  box.width -= diffx;  box.height -= diffy;  break;
      }
      _dir = ArrowHeadDirection.LOWER_RIGHT;
    }

    bbox = box;

  }

  /* Performs resize operation */
  public override void resize( double diffx, double diffy ) {
    move_selector( 1, diffx, diffy );
  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.TCROSS );
  }

  /*
  private Array<CanvasPoint> get_points() {

    double vpw, vph, vsw, vsh;
    double ppw, pph, psw, psh;

    calc_flight_point( _valley_a, _valley_c, true,  out vpw, out vph );
    calc_flight_point( _valley_a, _valley_c, false, out vsw, out vsh );
    calc_flight_point( _peak_a,   _peak_c,   true,  out ppw, out pph );
    calc_flight_point( _peak_a,   _peak_c,   false, out psw, out psh );

    switch( _dir ) {
      case ArrowHeadDirection.UPPER_LEFT :
        points.append_val( new CanvasPoint.from_coords( bbox.x1(), bbox.y1() ) );
        points.append_val( new CanvasPoint.from_coords( bbox.x2(), bbox.y2() ) );
        points.append_val( new CanvasPoint.from_coords( (bbox.x1() + ppw), (bbox.y1() + pph) ) );
        points.append_val( new CanvasPointvpx = bbox.x1() + vpw;  vpy = bbox.y1() + vph;
        psx = bbox.x1() + psw;  psy = bbox.y1() + psh;
        vsx = bbox.x1() + vsw;  vsy = bbox.y1() + vsh;
        break;
      case ArrowHeadDirection.LOWER_LEFT :
        hx  = bbox.x1();        hy  = bbox.y2();
        tx  = bbox.x2();        ty  = bbox.y1();
        ppx = bbox.x1() + ppw;  ppy = bbox.y2() - pph;
        vpx = bbox.x1() + vpw;  vpy = bbox.y2() - vph;
        psx = bbox.x1() + psw;  psy = bbox.y2() - psh;
        vsx = bbox.x1() + vsw;  vsy = bbox.y2() - vsh;
        break;
      case ArrowHeadDirection.UPPER_RIGHT :
        hx  = bbox.x2();        hy  = bbox.y1();
        tx  = bbox.x1();        ty  = bbox.y2();
        ppx = bbox.x2() - ppw;  ppy = bbox.y1() + pph;
        vpx = bbox.x2() - vpw;  vpy = bbox.y1() + vph;
        psx = bbox.x2() - psw;  psy = bbox.y1() + psh;
        vsx = bbox.x2() - vsw;  vsy = bbox.y1() + vsh;
        break;
      case ArrowHeadDirection.LOWER_RIGHT :
        hx  = bbox.x2();        hy  = bbox.y2();
        tx  = bbox.x1();        ty  = bbox.y1();
        ppx = bbox.x2() - ppw;  ppy = bbox.y2() - pph;
        vpx = bbox.x2() - vpw;  vpy = bbox.y2() - vph;
        psx = bbox.x2() - psw;  psy = bbox.y2() - psh;
        vsx = bbox.x2() - vsw;  vsy = bbox.y2() - vsh;
        break;
      default :  assert_not_reached();
    }
  }

  public override bool is_within( double x, double y ) {
  }
  */

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    double vpw, vph, vsw, vsh;
    double ppw, pph, psw, psh;

    calc_flight_point( _valley_a, _valley_c, true,  out vpw, out vph );
    calc_flight_point( _valley_a, _valley_c, false, out vsw, out vsh );
    calc_flight_point( _peak_a,   _peak_c,   true,  out ppw, out pph );
    calc_flight_point( _peak_a,   _peak_c,   false, out psw, out psh );

    Utils.set_context_color( ctx, color );

    double hx  = 0.0, hy  = 0.0, tx  = 0.0, ty  = 0.0;
    double ppx = 0.0, ppy = 0.0, vpx = 0.0, vpy = 0.0;
    double psx = 0.0, psy = 0.0, vsx = 0.0, vsy = 0.0;

    switch( _dir ) {
      case ArrowHeadDirection.UPPER_LEFT :
        hx  = bbox.x1();        hy  = bbox.y1();
        tx  = bbox.x2();        ty  = bbox.y2();
        ppx = bbox.x1() + ppw;  ppy = bbox.y1() + pph;
        vpx = bbox.x1() + vpw;  vpy = bbox.y1() + vph;
        psx = bbox.x1() + psw;  psy = bbox.y1() + psh;
        vsx = bbox.x1() + vsw;  vsy = bbox.y1() + vsh;
        break;
      case ArrowHeadDirection.LOWER_LEFT :
        hx  = bbox.x1();        hy  = bbox.y2();
        tx  = bbox.x2();        ty  = bbox.y1();
        ppx = bbox.x1() + ppw;  ppy = bbox.y2() - pph;
        vpx = bbox.x1() + vpw;  vpy = bbox.y2() - vph;
        psx = bbox.x1() + psw;  psy = bbox.y2() - psh;
        vsx = bbox.x1() + vsw;  vsy = bbox.y2() - vsh;
        break;
      case ArrowHeadDirection.UPPER_RIGHT :
        hx  = bbox.x2();        hy  = bbox.y1();
        tx  = bbox.x1();        ty  = bbox.y2();
        ppx = bbox.x2() - ppw;  ppy = bbox.y1() + pph;
        vpx = bbox.x2() - vpw;  vpy = bbox.y1() + vph;
        psx = bbox.x2() - psw;  psy = bbox.y1() + psh;
        vsx = bbox.x2() - vsw;  vsy = bbox.y1() + vsh;
        break;
      case ArrowHeadDirection.LOWER_RIGHT :
        hx  = bbox.x2();        hy  = bbox.y2();
        tx  = bbox.x1();        ty  = bbox.y1();
        ppx = bbox.x2() - ppw;  ppy = bbox.y2() - pph;
        vpx = bbox.x2() - vpw;  vpy = bbox.y2() - vph;
        psx = bbox.x2() - psw;  psy = bbox.y2() - psh;
        vsx = bbox.x2() - vsw;  vsy = bbox.y2() - vsh;
        break;
      default :  assert_not_reached();
    }

    var black = Utils.color_from_string( "black" );

    ctx.set_line_width( 1 );
    ctx.new_path();
    ctx.move_to( hx, hy );
    ctx.line_to( ppx, ppy );
    ctx.line_to( vpx, vpy );
    ctx.line_to( tx, ty );
    ctx.line_to( vsx, vsy );
    ctx.line_to( psx, psy );
    ctx.close_path();
    ctx.fill_preserve();

    Utils.set_context_color( ctx, black );
    ctx.stroke();

  }

}



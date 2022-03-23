/*s
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
  public CanvasItemArrow( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.ARROW, canvas, props );
    create_points();
  }

  /* Creates the selection points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );
    points.append_val( new CanvasPoint() );
    points.append_val( new CanvasPoint() );
  }

  /* Copies the given arrow item properties to this one */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var arrow_item = (CanvasItemArrow)item;
    if( arrow_item != null ) {
      _peak_a   = arrow_item._peak_a;
      _peak_c   = arrow_item._peak_c;
      _valley_a = arrow_item._valley_a;
      _valley_c = arrow_item._valley_c;
    }
  }

  /* Creates a duplicate of this item and returns it */
  public override CanvasItem duplicate() {
    var item = new CanvasItemArrow( canvas, props );
    item.copy( this );
    return( item );
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
    var peak  = _peak_a == a;

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

    /* Make sure that the arrow shape doesn't get weird */
    if( (_peak_a - _valley_a) < 0.25 ) {
      // a = peak ? (_valley_a + 0.25) : (_peak_a - 0.25);
    }

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

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
          case PType.HD :
          case PType.TL :  box.x = head.x;  box.y = head.y;  break;
          case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x1() + w), (bbox.y1() + h) );  break;
          case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x1() + w), (bbox.y1() + h) );  break;
        }
        _dir = ArrowHeadDirection.UPPER_LEFT;
      } else {
        switch( index ) {
          case PType.HD :
          case PType.TL :  box.x = head.x;  box.y = tail.y;  break;
          case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x1() + w), (bbox.y2() - h) );  break;
          case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x1() + w), (bbox.y2() - h) );  break;
        }
        _dir = ArrowHeadDirection.LOWER_LEFT;
      }
    } else if( head.y < tail.y ) {
      switch( index ) {
        case PType.HD :
        case PType.TL :  box.x = tail.x;  box.y = head.y;  break;
        case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x2() - w), (bbox.y1() + h) );  break;
        case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x2() - w), (bbox.y1() + h) );  break;
      }
      _dir = ArrowHeadDirection.UPPER_RIGHT;
    } else {
      switch( index ) {
        case PType.HD :
        case PType.TL :  box.x = tail.x;  box.y = tail.y;  break;
        case PType.PP :  points.index( PType.SP ).copy_coords( (bbox.x2() - w), (bbox.y2() - h) );  break;
        case PType.PV :  points.index( PType.SV ).copy_coords( (bbox.x2() - w), (bbox.y2() - h) );  break;
      }
      _dir = ArrowHeadDirection.LOWER_RIGHT;
    }

    if( (index == PType.HD) || (index == PType.TL) ) {
      box.width  = Math.fabs( tail.x - head.x );
      box.height = Math.fabs( tail.y - head.y );
    }

    bbox = box;

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.TCROSS );
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "peak-angle",    _peak_a.to_string() );
    node->set_prop( "peak-length",   _peak_c.to_string() );
    node->set_prop( "valley-angle",  _valley_a.to_string() );
    node->set_prop( "valley-length", _valley_c.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var pa = node->get_prop( "peak-angle" );
    if( pa != null ) {
      _peak_a = double.parse( pa );
    }
    var pc = node->get_prop( "peak-length" );
    if( pc != null ) {
      _peak_c = double.parse( pc );
    }
    var va = node->get_prop( "valley-angle" );
    if( va != null ) {
      _valley_a = double.parse( va );
    }
    var vc = node->get_prop( "valley-length" );
    if( vc != null ) {
      _valley_c = double.parse( vc );
    }
    bbox_changed();
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var alpha = mode.alpha( props.alpha );

    set_color( ctx, color, props.color, alpha );

    ctx.set_line_width( 1 );
    ctx.new_path();
    ctx.move_to( points.index( 0 ).x, points.index( 0 ).y );
    for( int i=1; i<6; i++ ) {
      ctx.line_to( points.index( i ).x, points.index( i ).y );
    }
    ctx.close_path();
    save_path( ctx, CanvasItemPathType.FILL );
    ctx.fill_preserve();

    var outline = Granite.contrasting_foreground_color( props.color );
    set_color( ctx, color, outline, (alpha / 2) );
    ctx.stroke();

  }

}



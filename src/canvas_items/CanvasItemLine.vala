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

public class CanvasItemLine : CanvasItem {

  private enum LineStartDirection {
    UPPER_LEFT,
    UPPER_RIGHT,
    LOWER_LEFT,
    LOWER_RIGHT
  }

  private LineStartDirection _dir = LineStartDirection.UPPER_LEFT;

  /* Constructor */
  public CanvasItemLine( CanvasItemProperties props ) {
    base( "arrow", props );
    create_points();
  }

  /* Creates the selection points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // Start
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // End
    points.append_val( new CanvasPoint() );  // Above Start
    points.append_val( new CanvasPoint() );  // Below Start
    points.append_val( new CanvasPoint() );  // Above End
    points.append_val( new CanvasPoint() );  // Below End
  }

  /* Copies the given arrow item properties to this one */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var line_item = (CanvasItemLine)item;
    if( line_item != null ) {
      _dir = line_item._dir;
    }
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    switch( _dir ) {
      case LineStartDirection.UPPER_LEFT :
        points.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
        points.index( 1 ).copy_coords( bbox.x2(), bbox.y2() );
        break;
      case LineStartDirection.LOWER_LEFT :
        points.index( 0 ).copy_coords( bbox.x1(), bbox.y2() );
        points.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
        break;
      case LineStartDirection.UPPER_RIGHT :
        points.index( 0 ).copy_coords( bbox.x2(), bbox.y1() );
        points.index( 1 ).copy_coords( bbox.x1(), bbox.y2() );
        break;
      case LineStartDirection.LOWER_RIGHT :
        points.index( 0 ).copy_coords( bbox.x2(), bbox.y2() );
        points.index( 1 ).copy_coords( bbox.x1(), bbox.y1() );
        break;
    }

    /*
    points.index( 2 ).copy_coords(  )
    points.index( 3 ).copy_coords(  )
    points.index( 4 ).copy_coords(  )
    points.index( 5 ).copy_coords(  )
    */

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box  = new CanvasRect.from_rect( bbox );
    var head = new CanvasPoint.from_point( points.index( 0 ) );
    var tail = new CanvasPoint.from_point( points.index( 1 ) );

    switch( index ) {
      case 0  :  head.x += diffx;  head.y += diffy;  break;
      case 1  :  tail.x += diffx;  tail.y += diffy;  break;
      default :  assert_not_reached();
    }

    if( head.x < tail.x ) {
      if( head.y < tail.y ) {
        box.x = head.x;
        box.y = head.y;
        _dir  = LineStartDirection.UPPER_LEFT;
      } else {
        box.x = head.x;
        box.y = tail.y;
        _dir  = LineStartDirection.LOWER_LEFT;
      }
    } else if( head.y < tail.y ) {
      box.x = tail.x;
      box.y = head.y;
      _dir  = LineStartDirection.UPPER_RIGHT;
    } else {
      box.x = tail.x;
      box.y = tail.y;
      _dir  = LineStartDirection.LOWER_RIGHT;
    }

    box.width  = Math.fabs( tail.x - head.x );
    box.height = Math.fabs( tail.y - head.y );

    bbox = box;

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

    var alpha   = mode.alpha( props.alpha );
    var outline = Granite.contrasting_foreground_color( props.color );
    var sw      = props.stroke_width.width();

    /* Draw the outline */
    Utils.set_context_color_with_alpha( ctx, outline, (alpha / 2) );
    ctx.set_line_width( sw + 2 );
    props.dash.set_bg_pattern( ctx );
    ctx.move_to( points.index( 0 ).x, points.index( 0 ).y );
    ctx.line_to( points.index( 1 ).x, points.index( 1 ).y );
    ctx.stroke_preserve();

    Utils.set_context_color_with_alpha( ctx, props.color, alpha );
    ctx.set_line_width( sw );
    props.dash.set_fg_pattern( ctx );
    ctx.stroke();

  }

}



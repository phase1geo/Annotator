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

public class CanvasItemBlur : CanvasItem {

  private CanvasImage _image;

  /* Constructor */
  public CanvasItemBlur( CanvasImage image, CanvasItemProperties props ) {
    base( "blur", props );
    _image = image;
    create_points();
  }

  /* Create the points */
  private void create_points() {
    points.append_val( new CanvasPoint( true ) );  // upper-left
    points.append_val( new CanvasPoint( true ) );  // upper-right
    points.append_val( new CanvasPoint( true ) );  // lower-left
    points.append_val( new CanvasPoint( true ) );  // lower-right
    points.append_val( new CanvasPoint( true ) );  // top
    points.append_val( new CanvasPoint( true ) );  // right
    points.append_val( new CanvasPoint( true ) );  // bottom
    points.append_val( new CanvasPoint( true ) );  // left
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( 2 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( 3 ).copy_coords( bbox.x2(), bbox.y2() );

    points.index( 4 ).copy_coords( bbox.mid_x(), bbox.y1() );
    points.index( 5 ).copy_coords( bbox.x2(), bbox.mid_y() );
    points.index( 6 ).copy_coords( bbox.mid_x(), bbox.y2() );
    points.index( 7 ).copy_coords( bbox.x1(), bbox.mid_y() );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    adjust_diffs( shift, box, ref diffx, ref diffy );

    switch( index ) {
      case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3 :                                    box.width += diffx;  box.height += diffy;  break;
      case 4 :                   box.y += diffy;                       box.height -= diffy;  break;
      case 5 :                                    box.width += diffx;                        break;
      case 6 :                                                         box.height += diffy;  break;
      case 7 :  box.x += diffx;                   box.width -= diffx;                        break;
    }

    if( (box.width >= (selector_size * 3)) && (box.height >= (selector_size * 3)) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    switch( index ) {
      case 0  :  return( CursorType.UL_ANGLE );
      case 1  :  return( CursorType.UR_ANGLE );
      case 2  :  return( CursorType.LL_ANGLE );
      case 3  :  return( CursorType.LR_ANGLE );
      case 4  :  return( CursorType.TOP_SIDE );
      case 5  :  return( CursorType.RIGHT_SIDE );
      case 6  :  return( CursorType.BOTTOM_SIDE );
      case 7  :  return( CursorType.LEFT_SIDE );
      default :  assert_not_reached();
    }
  }

  public override bool is_within( double x, double y ) {
    return( base.is_within( x, y ) );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    /* If we are moving the node or resizing it, just draw an alpha box */
    if( mode.moving() ) {
      var blur_color = _image.get_average_color( bbox );
      Utils.set_context_color_with_alpha( ctx, blur_color, mode.alpha() );
      ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
      ctx.fill();

    /* Otherwise, calculate and apply the blur */
    } else {
      _image.draw_blur_rectangle( ctx, bbox, props.blur_radius );
    }

  }

}



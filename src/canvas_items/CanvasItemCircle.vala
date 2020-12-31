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

public class CanvasItemCircle : CanvasItem {

  private bool _fill;

  /* Constructor */
  public CanvasItemCircle( double x, double y, bool fill, RGBA color, int stroke_width ) {

    base( "circle", x, y, color, stroke_width );

    _fill = fill;

    selects.append_val( new CanvasPoint() );  // upper-left
    selects.append_val( new CanvasPoint() );  // upper-right
    selects.append_val( new CanvasPoint() );  // lower-left
    selects.append_val( new CanvasPoint() );  // lower-right

    selects.append_val( new CanvasPoint() );  // top
    selects.append_val( new CanvasPoint() );  // right
    selects.append_val( new CanvasPoint() );  // bottom
    selects.append_val( new CanvasPoint() );  // left

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    selects.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
    selects.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
    selects.index( 2 ).copy_coords( bbox.x1(), bbox.y2() );
    selects.index( 3 ).copy_coords( bbox.x2(), bbox.y2() );

    selects.index( 4 ).copy_coords( bbox.mid_x(), bbox.y1() );
    selects.index( 5 ).copy_coords( bbox.x2(), bbox.mid_y() );
    selects.index( 6 ).copy_coords( bbox.mid_x(), bbox.y2() );
    selects.index( 7 ).copy_coords( bbox.x1(), bbox.mid_y() );
  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy ) {

    var box = new CanvasRect.from_rect( bbox );

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

    if( (box.width >= (select_offset * 3)) && (box.height >= (select_offset * 3)) ) {
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

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var scale_width  = (bbox.width < bbox.height) ? (bbox.width / bbox.height) : 1.0;
    var scale_height = (bbox.width < bbox.height) ? 1.0 : (bbox.height / bbox.width);
    var radius       = (bbox.width < bbox.height) ? (bbox.height / 2.0) : (bbox.width / 2.0);

    Utils.set_context_color( ctx, color );

    var save_matrix = ctx.get_matrix();
    ctx.translate( bbox.mid_x(), bbox.mid_y() );
    ctx.scale( scale_width, scale_height );
    ctx.translate( (0 - bbox.mid_x()), (0 - bbox.mid_y()) );
    ctx.new_path();
    ctx.arc( bbox.mid_x(), bbox.mid_y(), radius, 0, (2 * Math.PI) );
    ctx.set_matrix( save_matrix );
    ctx.set_line_width( stroke_width );
    if( _fill ) {
      ctx.fill_preserve();
    }
    ctx.stroke();

  }

}



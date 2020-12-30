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

public class CanvasItemRect : CanvasItem {

  /* Constructor */
  public CanvasItemRect( double x, double y, RGBA fill, RGBA stroke, int stroke_width ) {

    base( "rectangle", x, y, fill, stroke, stroke_width );

    selects.append_val( new CanvasPoint() );  // upper-left
    selects.append_val( new CanvasPoint() );  // upper-right
    selects.append_val( new CanvasPoint() );  // lower-left
    selects.append_val( new CanvasPoint() );  // lower-right

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    selects.index( 0 ).copy_coords( (bbox.x1() - select_offset), (bbox.y1() - select_offset) );
    selects.index( 1 ).copy_coords( (bbox.x2() - select_offset), (bbox.y1() - select_offset) );
    selects.index( 2 ).copy_coords( (bbox.x1() - select_offset), (bbox.y2() - select_offset) );
    selects.index( 3 ).copy_coords( (bbox.x2() - select_offset), (bbox.y2() - select_offset) );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy ) {

    var box = new CanvasRect.from_rect( bbox );

    switch( index ) {
      case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3 :                                    box.width += diffx;  box.height += diffy;  break;
    }

    if( (box.width >= (select_offset * 2)) && (box.height >= (select_offset * 2)) ) {
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
      default :  assert_not_reached();
    }
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    ctx.set_line_width( stroke_width );

    Utils.set_context_color( ctx, fill );
    ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
    ctx.fill_preserve();

    Utils.set_context_color( ctx, stroke );
    ctx.stroke();

  }

}



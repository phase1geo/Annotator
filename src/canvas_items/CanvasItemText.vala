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

public class CanvasItemText : CanvasItem {

  private enum TextMode {
    NONE,
    EDITABLE
  }

  private TextMode _mode = TextMode.NONE;

  /* Constructor */
  public CanvasItemText( double x, double y, RGBA color ) {

    base( "text", x, y, color, 1 );

    

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( 2 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( 3 ).copy_coords( bbox.x2(), bbox.y2() );
    points.index( 4 ).copy_coords( bbox.x2(), bbox.mid_y() );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy ) {

    /* TBD */

    var box = new CanvasRect.from_rect( bbox );

    switch( index ) {
      case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3 :                                    box.width += diffx;  box.height += diffy;  break;
      case 4 :                   box.y += diffy;                       box.height -= diffy;  break;
    }

    if( (box.width >= (select_offset * 2)) && (box.height >= (select_offset * 2)) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.RIGHT_SIDE );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    /* TBD */

  }

}



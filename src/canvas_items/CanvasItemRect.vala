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

public class CanvasItemRect : CanvasItem {

  private Cursor[] _sel_cursors;

  /* Constructor */
  public CanvasItemRect( Canvas canvas, bool fill, CanvasItemProperties props ) {
    base( (fill ? CanvasItemType.RECT_FILL : CanvasItemType.RECT_STROKE), canvas, props );
    create_points();
    _sel_cursors = new Cursor[8];
    _sel_cursors[0] = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[1] = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[3] = new Cursor.from_name( "se-resize", null );
    _sel_cursors[4] = new Cursor.from_name( "n-resize", null );
    _sel_cursors[5] = new Cursor.from_name( "e-resize", null );
    _sel_cursors[6] = new Cursor.from_name( "s-resize", null );
    _sel_cursors[7] = new Cursor.from_name( "w-resize", null );
  }

  /* Create the points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // upper-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // upper-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // lower-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // lower-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER2 ) );  // top
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER3 ) );  // right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER2 ) );  // bottom
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER3 ) );  // left
  }

  /* Returns a duplicate of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemRect( canvas, (itype == CanvasItemType.RECT_FILL), props );
    item.copy( this );
    return( item );
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

    if( (box.width >= 1) && (box.height >= 1) ) {
      bbox = box;
    }

    if( (box.abs_width() >= (selector_width * 3)) && (box.abs_height() >= (selector_height * 3)) ) {
      set_selector_visual( index, false );
    } else {
      set_selector_visual( index, true );
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursors[index] );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var outline = Granite.contrasting_foreground_color( props.color );
    var alpha   = mode.alpha( props.alpha );

    ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );

    save_path( ctx, CanvasItemPathType.FILL );

    if( itype == CanvasItemType.RECT_FILL ) {

      set_color( ctx, color, props.color, alpha );

      if( props.outline ) {
        ctx.fill_preserve();
        set_color( ctx, color, outline, 0.5 );
        ctx.set_line_width( 1 );
        ctx.stroke();
      } else {
        ctx.fill();
      }
  
    } else {

      var sw = props.stroke_width.width();

      if( props.outline ) {
        set_color( ctx, color, outline, 0.5 );
        ctx.set_line_width( sw + 2 );
        props.dash.set_bg_pattern( ctx );
        ctx.stroke_preserve();
      }

      set_color( ctx, color, props.color, alpha );
      ctx.set_line_width( sw );
      props.dash.set_fg_pattern( ctx );
      ctx.stroke();

    }

  }

}



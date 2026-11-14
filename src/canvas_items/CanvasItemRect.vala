/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Annotator)
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

public class CanvasItemRect : CanvasItemRotatable {

  private Cursor[] _sel_cursors;

  //-------------------------------------------------------------
  // Constructor
  public CanvasItemRect( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.RECT, canvas, props );
    create_points();
    _sel_cursors = new Cursor[8];  // The rotator uses the default cursor
    _sel_cursors[0] = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[1] = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[3] = new Cursor.from_name( "se-resize", null );
    _sel_cursors[4] = new Cursor.from_name( "n-resize", null );
    _sel_cursors[5] = new Cursor.from_name( "e-resize", null );
    _sel_cursors[6] = new Cursor.from_name( "s-resize", null );
    _sel_cursors[7] = new Cursor.from_name( "w-resize", null );
  }

  //-------------------------------------------------------------
  // Create the points
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // upper-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // upper-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // lower-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // lower-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER2 ) );  // top
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER3 ) );  // right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER2 ) );  // bottom
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER3 ) );  // left
    points.append_val( new CanvasPoint( CanvasPointType.ROTATOR ) );   // rotator
    rotator_index = 8;
  }

  //-------------------------------------------------------------
  // Returns the southeast selector.
  public override int resize_selector() {
    return( 3 );
  }

  //-------------------------------------------------------------
  // Returns a duplicate of this item
  public override CanvasItem duplicate() {
    var item = new CanvasItemRect( canvas, props );
    item.copy( this );
    return( item );
  }

  //-------------------------------------------------------------
  // Updates the selection boxes whenever the bounding box changes
  protected override void bbox_changed() {

    set_point_rotated( 0, bbox.x1(),    bbox.y1() );
    set_point_rotated( 1, bbox.x2(),    bbox.y1() );
    set_point_rotated( 2, bbox.x1(),    bbox.y2() );
    set_point_rotated( 3, bbox.x2(),    bbox.y2() );

    set_point_rotated( 4, bbox.mid_x(), bbox.y1() );
    set_point_rotated( 5, bbox.x2(),    bbox.mid_y() );
    set_point_rotated( 6, bbox.mid_x(), bbox.y2() );
    set_point_rotated( 7, bbox.x1(),    bbox.mid_y() );

    // The rotation selector (index 8) is positioned at draw time

  }

  //-------------------------------------------------------------
  // Adjusts the bounding box
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    if( index == rotator_index ) {
      rotate_selector( index, diffx, diffy, shift );
      return;
    }

    var box = new CanvasRect.from_rect( bbox );
    double anchor_lx, anchor_ly, anchor_wx, anchor_wy;

    // Work in the item's unrotated space and remember where the
    // opposite side is so that it doesn't move when resizing
    get_anchor( index, out anchor_lx, out anchor_ly, out anchor_wx, out anchor_wy );
    unrotate_diffs( ref diffx, ref diffy );
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
      fix_anchor( box, anchor_lx, anchor_ly, anchor_wx, anchor_wy );
      bbox = box;
    }

    if( (box.abs_width() >= (selector_width * 3)) && (box.abs_height() >= (selector_height * 3)) ) {
      set_selector_visual( index, false );
    } else {
      set_selector_visual( index, true );
    }

  }

  //-------------------------------------------------------------
  // Provides cursor to display when mouse cursor is hovering over
  // the given selector
  public override Cursor? get_selector_cursor( int index ) {
    if( index == rotator_index ) {
      return( base.get_selector_cursor( index ) );
    }
    return( _sel_cursors[index] );
  }

  //-------------------------------------------------------------
  // Draw the rectangle
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var alpha       = mode.alpha( props.color.alpha );
    var save_matrix = ctx.get_matrix();

    // Build the path in the item's rotated space, then restore the
    // matrix so that stroke widths aren't distorted by the rotation
    ctx.translate( bbox.mid_x(), bbox.mid_y() );
    ctx.rotate( angle );
    ctx.translate( (0 - bbox.mid_x()), (0 - bbox.mid_y()) );
    ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
    ctx.set_matrix( save_matrix );

    save_path( ctx, CanvasItemPathType.FILL );

    if( props.outline ) {
      var outline = Granite.contrasting_foreground_color( props.color );
      set_color( ctx, color, outline, (alpha / 2) );
      if( props.fill ) {
        ctx.set_line_width( 1 );
        ctx.stroke_preserve();
      }
      if( props.stroke ) {
        props.dash.set_bg_pattern( ctx );
        ctx.set_line_width( props.stroke_width.width() + 2 );
        ctx.stroke_preserve();
      }
    }

    if( props.fill ) {
      set_color( ctx, color, props.color, alpha );
      if( props.stroke ) {
        ctx.fill_preserve();
      } else {
        ctx.fill();
      }
    }

    if( props.stroke ) {
      props.dash.set_fg_pattern( ctx );
      set_color( ctx, color, props.stroke_color, mode.alpha( props.stroke_color.alpha ) );
      ctx.set_line_width( props.stroke_width.width() );
      ctx.stroke();
    }
  
  }

}



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

public class CanvasItemBubble : CanvasItem {

  private Cursor[] _sel_cursors;
  private bool     _point_moved = false;
  private bool     _base0_moved = false;
  private bool     _base1_moved = false;

  /* Constructor */
  public CanvasItemBubble( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.BUBBLE, canvas, props );
    create_points();
    _sel_cursors = new Cursor[9];
    _sel_cursors[0]  = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[1]  = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[2]  = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[3]  = new Cursor.from_name( "se-resize", null );
    _sel_cursors[4]  = new Cursor.from_name( "n-resize", null );
    _sel_cursors[5]  = new Cursor.from_name( "e-resize", null );
    _sel_cursors[6]  = new Cursor.from_name( "s-resize", null );
    _sel_cursors[7]  = new Cursor.from_name( "w-resize", null );
    _sel_cursors[8]  = new Cursor.from_name( "crosshair", null );  // Talking point
    _sel_cursors[9]  = new Cursor.from_name( "ew-resize", null );  // Base 0
    _sel_cursors[10] = new Cursor.from_name( "ew-resize", null );  // Base 1
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
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );   // Talk point
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );   // Where talk point attaches to bubble
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );   // Where talk point attaches to bubble
  }

  public override void copy( CanvasItem item ) {
    base.copy( item );
    var bubble_item = (CanvasItemBubble)item;
    if( bubble_item != null ) {
      _point_moved = bubble_item._point_moved;
      _base0_moved = bubble_item._base0_moved;
      _base1_moved = bubble_item._base1_moved;
    }
  }
 
  /* Returns a duplicate of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemBubble( canvas, props );
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

    if( !_point_moved ) {
      points.index( 8 ).copy_coords( bbox.mid_x(), (bbox.y2() + 50) );
    } else {
      var diffy = points.index( 8 ).y - points.index( 9 ).y;
      points.index( 8 ).copy_coords( points.index( 8 ).x, (bbox.y2() + diffy) );
    }

    if( !_base0_moved ) {
      points.index( 9 ).copy_coords( (bbox.mid_x() + 20), bbox.y2() );
    }

    if( !_base1_moved ) {
      points.index( 10 ).copy_coords( (bbox.mid_x() + 80), bbox.y2() );
    }

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    adjust_diffs( shift, box, ref diffx, ref diffy );

    switch( index ) {
      case 0  :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1  :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2  :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3  :                                    box.width += diffx;  box.height += diffy;  break;
      case 4  :                   box.y += diffy;                       box.height -= diffy;  break;
      case 5  :                                    box.width += diffx;                        break;
      case 6  :                                                         box.height += diffy;  break;
      case 7  :  box.x += diffx;                   box.width -= diffx;                        break;
      case 8  :  points.index( 8 ).x += diffx;  points.index( 8 ).y += diffy;  _point_moved = true;  break;
      case 9  :  points.index( 9 ).x += diffx;   _base0_moved = true;  break;
      case 10 :  points.index( 10 ).x += diffx;  _base1_moved = true;  break;
    }

    if( (box.width >= 1) && (box.height >= 1) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursors[index] );
  }

  private void draw_bubble( Context ctx ) {

    var deg    = Math.PI / 180.0;
    var radius = 40;

    ctx.new_sub_path();
    ctx.arc( (bbox.x + bbox.width - radius), (bbox.y + radius),     radius, (-90 * deg), (0 * deg) );
    ctx.arc( (bbox.x + bbox.width - radius), (bbox.y + bbox.height - radius), radius, (0 * deg),   (90 * deg) );
    ctx.line_to( points.index( 10 ).x, points.index( 10 ).y );
    ctx.line_to( points.index( 8 ).x,  points.index( 8 ).y );
    ctx.line_to( points.index( 9 ).x,  points.index( 9 ).y );
    ctx.arc( (bbox.x + radius),     (bbox.y + bbox.height - radius), radius, (90 * deg),  (180 * deg) );
    ctx.arc( (bbox.x + radius),     (bbox.y + radius),     radius, (180 * deg), (270 * deg) );
    ctx.close_path();

  }

  private void draw_cloud( Context ctx ) {

    var deg = Math.PI / 180.0;

    // Draw cloud
    var num_horizontal = (int)(bbox.width  / 40.0);
    var hrad           = ((bbox.width  / num_horizontal) / 2);
    var num_vertical   = (int)((bbox.height - (hrad * 2)) / 40.0);
    var vrad           = (((bbox.height - (hrad * 2)) / num_vertical) / 2);

    // Draw main cloud
    ctx.new_sub_path();
    for( int i=0; i<(num_horizontal + 1); i++ ) {
      var first = (i == 0);
      var last  = (i == num_horizontal);
      ctx.arc( (bbox.x + (i * (hrad * 2))), bbox.y, hrad, (first ? (-270 * deg) : (-180 * deg)), (last ? (90 * deg) : (0 * deg)) );
    }
    for( int i=0; i<num_vertical; i++ ) {
      ctx.arc( (bbox.x + bbox.width), (bbox.y + hrad + vrad + (i * (vrad * 2))), vrad, (-90 * deg), (90 * deg) );
    }
    for( int i=num_horizontal; i>=0; i-- ) {
      var first = (i == num_horizontal);
      var last  = (i == 0);
      ctx.arc( (bbox.x + (i * (hrad * 2))), (bbox.y + bbox.height), hrad, (first ? (270 * deg) : (0 * deg)), (last ? (270 * deg) : (180 * deg)) );
    }
    for( int i=(num_vertical - 1); i>=0; i-- ) {
      ctx.arc( bbox.x, (bbox.y + hrad + vrad + (i * (vrad * 2))), vrad, (90 * deg), (-90 * deg) );
    }
    ctx.close_path();

    // Draw thinking circles
    ctx.new_sub_path();
    ctx.arc( points.index( 8 ).x, points.index( 8 ).y, 20, (0 * deg), (360 * deg) );
    ctx.close_path();

  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var fill   = Granite.contrasting_foreground_color( props.color );
    var alpha  = mode.alpha( props.alpha );
    var sw     = props.stroke_width.width();

    // Draw rounded rectangle with triangle talk point
    // draw_bubble( ctx );
    draw_cloud( ctx );

    save_path( ctx, CanvasItemPathType.FILL );

    set_color( ctx, color, fill, alpha );
    ctx.fill_preserve();

    set_color( ctx, color, props.color, 1.0 );
    ctx.set_line_width( sw );
    ctx.stroke();
  
  }

}



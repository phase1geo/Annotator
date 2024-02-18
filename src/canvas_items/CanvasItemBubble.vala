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

public enum CanvasBubbleType {
  TALK,
  THINK;

  public string to_string() {
    switch( this ) {
      case TALK  :  return( "talk" );
      case THINK :  return( "think" );
      default    :  assert_not_reached();
    }
  }

  public CanvasItemType item_type() {
    switch( this ) {
      case TALK  :  return( CanvasItemType.TALK );
      case THINK :  return( CanvasItemType.THINK );
      default    :  assert_not_reached();
    }
  }

  public CanvasBubbleType parse( string str ) {
    switch( str ) {
      case "talk"  :  return( TALK );
      case "think" :  return( THINK );
      default      :  return( TALK );
    }
  }

}

public class CanvasItemBubble : CanvasItem {

  private Cursor[]         _sel_cursors;
  private CanvasBubbleType _type;
  private bool             _point_moved = false;
  private bool             _base_moved  = false;
  private double           _radius      = 40.0;

  /* Constructor */
  public CanvasItemBubble( Canvas canvas, CanvasBubbleType type, CanvasItemProperties props ) {
    base( type.item_type(), canvas, props );
    _type = type;
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
      _type        = bubble_item._type;
      _point_moved = bubble_item._point_moved;
      _base_moved  = bubble_item._base_moved;
    }
  }
 
  /* Returns a duplicate of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemBubble( canvas, _type, props );
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
      points.index( 8 ).copy_coords( bbox.mid_x(), (bbox.y2() + 70) );
    }

    if( !_base_moved ) {
      points.index( 9 ).copy_coords( (bbox.mid_x() + 20), bbox.y2() );
      points.index( 10 ).copy_coords( (bbox.mid_x() + 50), bbox.y2() );
    } else {
      points.index( 9 ).copy_coords( points.index( 9 ).x, bbox.y2() );
      points.index( 10 ).copy_coords( points.index( 10 ).x, bbox.y2() );
    }

    if( points.index( 10 ).x > bbox.x2() ) {
      points.index( 10 ).x = bbox.x2();
    }

    if( points.index( 9 ).x < bbox.x1() ) {
      points.index( 9 ).x = bbox.x1();
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
      case 9  :  points.index( 9 ).x += diffx;   _base_moved = true;  break;
      case 10 :  points.index( 10 ).x += diffx;  _base_moved = true;  break;
    }

    if( (box.width >= 60) && (box.height >= 1) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursors[index] );
  }

  private void draw_bubble( Context ctx ) {

    var deg    = Math.PI / 180.0;
    var radius = _radius;

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

  private double get_talking_x( double y ) {

    var mid = ((points.index( 10 ).x - points.index( 9 ).x) / 2) + points.index( 9 ).x;
    var b   = Math.fabs( mid - points.index( 8 ).x );
    var a   = points.index( 8 ).y - points.index( 9 ).y;
    var B   = Math.atan( b / a );
    var a2  = y - points.index( 9 ).y;
    var b2  = Math.tan( B ) * a2;

    return( (mid > points.index( 8 ).x) ? (mid - b2) : (mid + b2) );

  }

  private void draw_cloud( Context ctx ) {

    var deg = Math.PI / 180.0;

    // Draw cloud
    var num_horizontal = (int)(bbox.width  / _radius);
    var hrad           = ((bbox.width  / num_horizontal) / 2);
    var num_vertical   = (int)((bbox.height - (hrad * 2)) / _radius);
    var vrad           = (((bbox.height - (hrad * 2)) / num_vertical) / 2);
    var x              = bbox.x + 60;
    var y              = bbox.y2() - 60;
    var scale_x        = (bbox.width / 320);
    var scale_y        = (bbox.height / 200);
    var trans_x        = (bbox.x    - (bbox.x    * scale_x));
    var trans_y        = (bbox.y2() - (bbox.y2() * scale_y));

    // Draw cloud (scale it to match bbox size)
    ctx.new_sub_path();
    ctx.save();
    ctx.translate( trans_x, trans_y );
    ctx.scale( scale_x, scale_y );
    ctx.arc(x, y, 60, Math.PI * 0.5, Math.PI * 1.5);
    ctx.arc(x + 70, y - 60, 70, Math.PI * 1, Math.PI * 1.85);
    ctx.arc(x + 152, y - 45, 50, Math.PI * 1.37, Math.PI * 1.91);
    ctx.arc(x + 200, y, 60, Math.PI * 1.5, Math.PI * 0.5);
    ctx.close_path();
    ctx.restore();

    // Draw thinking circles
    var w  = points.index( 10 ).x - points.index( 9 ).x;
    var h  = points.index( 8 ).y - points.index( 9 ).y;
    var y0 = points.index( 9 ).y;
    var r1 = (w / 2);
    var y1 = y0 + r1;
    var r2 = ((r1 - 10) / 2) + 10;
    var y2 = ((points.index( 8 ).y - y1) / 2) + y1;

    // Draw thinking circles
    ctx.new_sub_path();
    ctx.arc( get_talking_x( y1 ), y1, r1, (0 * deg), (360 * deg) );
    ctx.close_path();

    ctx.new_sub_path();
    ctx.arc( get_talking_x( y2 ), y2, r2, (0 * deg), (360 * deg) );
    ctx.close_path();

    ctx.new_sub_path();
    ctx.arc( points.index( 8 ).x, points.index( 8 ).y, 10, (0 * deg), (360 * deg) );
    ctx.close_path();

  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var fill   = Granite.contrasting_foreground_color( props.color );
    var alpha  = mode.alpha( props.alpha );
    var sw     = props.stroke_width.width();

    // Draw rounded rectangle with triangle talk point
    switch( _type ) {
      case CanvasBubbleType.TALK  :  draw_bubble( ctx );  break;
      case CanvasBubbleType.THINK :  draw_cloud( ctx );   break;
    }

    save_path( ctx, CanvasItemPathType.FILL );

    set_color( ctx, color, fill, alpha );
    ctx.fill_preserve();

    set_color( ctx, color, props.color, 1.0 );
    ctx.set_line_width( sw );
    ctx.stroke();
  
  }

}



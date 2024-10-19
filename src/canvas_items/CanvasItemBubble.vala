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
    }

    if( (box.width >= 60) && (box.height >= 1) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursors[index] );
  }

  /* Helper function that finds the two tangential points on a circle to a given point */
  private bool find_tangents( CanvasPoint center, double radius, CanvasPoint external, CanvasPoint pt1, CanvasPoint pt2 ) {

    var dx  = center.x - external.x;
    var dy  = center.y - external.y;
    var dsq = (dx * dx) + (dy * dy);
    var rsq = radius * radius;
    if( dsq < rsq ) {
      return( false );
    }
    var l = Math.sqrt( dsq - rsq );

    return( find_circle_circle_intersections( center, radius, external, l, pt1, pt2 ) );

  }

  /* Helper function that finds the two points where two circles intersect */
  private bool find_circle_circle_intersections( CanvasPoint c0, double r0, CanvasPoint c1, double r1, CanvasPoint pt1, CanvasPoint pt2 ) {

    var dx   = c0.x - c1.x;
    var dy   = c0.y - c1.y;
    var dist = Math.sqrt( (dx * dx) + (dy * dy) );
    if( (dist > (r0 + r1)) || (dist < Math.fabs( r0 - r1 )) || ((dist == 0) && (r0 == r1)) ) {
      return( false );
    }
    var a = ((r0 * r0) - (r1 * r1) + (dist * dist)) / (2 * dist);
    var h = Math.sqrt( (r0 * r0) - (a * a) );
    var cx2 = c0.x + a * (c1.x - c0.x) / dist;
    var cy2 = c0.y + a * (c1.y - c0.y) / dist;

    pt1.copy_coords( (cx2 + (h * (c1.y - c0.y) / dist)), (cy2 - (h * (c1.x - c0.x) / dist)) );
    pt2.copy_coords( (cx2 - (h * (c1.y - c0.y) / dist)), (cy2 + (h * (c1.x - c0.x) / dist)) );

    return( true );

  }

  //-------------------------------------------------------------
  // Returns the X, Y point where two lines intersect where p0 and p1
  // are the points for the first line and p2, p3 are the points for the second line
  private bool get_line_intersection( CanvasPoint p0, CanvasPoint p1, CanvasPoint p2, CanvasPoint p3, out CanvasPoint? pi ) {

    var s1 = new CanvasPoint.from_coords( (p1.x - p0.x), (p1.y - p0.y) );
    var s2 = new CanvasPoint.from_coords( (p3.x - p2.x), (p3.y - p2.y) );

    var s = (-s1.y * (p0.x - p2.x) + s1.x * (p0.y - p2.y)) / (-s2.x * s1.y + s1.x * s2.y);
    var t = ( s2.x * (p0.y - p2.y) - s2.y * (p0.x - p2.x)) / (-s2.x * s1.y + s1.x * s2.y);

    if( (s >= 0) && (s <= 1) && (t >= 0) && (t <= 1) ) {
      pi = new CanvasPoint.from_coords( (p0.x + (t * s1.x)), (p0.y + (t * s1.y)) );
      return( true );
    }

    pi = null;
    return( false );  // No collision

  }

  //-------------------------------------------------------------
  // Draw the bubble starting at the top.
  private bool draw_bubble_top( Context ctx, CanvasPoint? pa, CanvasPoint? pb ) {

    var pa_n = (pa != null) && (pa.y == bbox.y1());
    var pb_n = (pb != null) && (pb.y == bbox.y1());

    if( !pa_n && !pb_n ) return( false );

    var deg  = Math.PI / 180.0;
    var pa_e = (pa.x == bbox.x2());
    var pa_w = (pa.x == bbox.x1());
    var pb_e = (pb.x == bbox.x2());
    var pb_w = (pb.x == bbox.x1());

    CanvasPoint p1, p2;
    bool ul, ur;

    if( pa_w || pb_e || (pa.x < pb.x) ) {
      p1 = pa;  p2 = pb;  ul = pa_w;  ur = pb_e;
    } else {
      p1 = pb;  p2 = pa;  ul = pb_w;  ur = pa_e;
    }

    if( ul ) {
      ctx.move_to( p1.x, p1.y );
      ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
      ctx.line_to( p2.x, p2.y );
    } else {
      var r = ((p1.x - bbox.x1()) < _radius) ? (p1.x - bbox.x1()) : _radius;
      ctx.arc( (bbox.x1() + r), (bbox.y1() + r), r, (180 * deg), (270 * deg) );
      ctx.line_to( p1.x, p1.y );
      ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
      ctx.line_to( p2.x, p2.y );
    }
    if( !ur ) {
      var r = ((bbox.x2() - p2.x) < _radius) ? (bbox.x2() - p2.x) : _radius;
      ctx.arc( (bbox.x2() - r), (bbox.y1() + r), r, (-90 * deg), (0 * deg) );
    }

    ctx.arc( (bbox.x2() - _radius), (bbox.y2() - _radius), _radius, (0 * deg),   (90 * deg) );
    ctx.arc( (bbox.x1() + _radius), (bbox.y2() - _radius), _radius, (90 * deg),  (180 * deg) );

    return( true );

  }

  //-------------------------------------------------------------
  // Draw the bubble starting at the bottom.
  private bool draw_bubble_bottom( Context ctx, CanvasPoint? pa, CanvasPoint? pb ) {
 
    var pa_s = (pa != null) && (pa.y == bbox.y2());
    var pb_s = (pb != null) && (pb.y == bbox.y2());

    if( !pa_s && !pb_s ) return( false );

    var deg  = Math.PI / 180.0;
    var pa_e = (pa.x == bbox.x2());
    var pa_w = (pa.x == bbox.x1());
    var pb_e = (pb.x == bbox.x2());
    var pb_w = (pb.x == bbox.x1());

    CanvasPoint p1, p2;
    bool ll, lr;

    if( pa_e || pb_w || (pa.x > pb.x) ) {
      p1 = pa;  p2 = pb;  ll = pb_w;  lr = pa_e;
    } else {
      p1 = pb;  p2 = pa;  ll = pa_w;  lr = pb_e;
    }

    if( lr ) {
      ctx.move_to( p1.x, p1.y );
      ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
      ctx.line_to( p2.x, p2.y );
    } else {
      var r = ((bbox.x2() - p1.x) < _radius) ? (bbox.x2() - p1.x) : _radius;
      ctx.arc( (bbox.x2() - r), (bbox.y2() - r), r, (0 * deg), (90 * deg) );
      ctx.line_to( p1.x, p1.y );
      ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
      ctx.line_to( p2.x, p2.y );
    }
    if( !ll ) {
      var r = ((p2.x - bbox.x1()) < _radius) ? (p2.x - bbox.x1()) : _radius;
      ctx.arc( (bbox.x1() + r), (bbox.y2() - r), r, (90 * deg), (180 * deg) );
    }

    ctx.arc( (bbox.x1() + _radius), (bbox.y1() + _radius), _radius, (180 * deg), (270 * deg) );
    ctx.arc( (bbox.x2() - _radius), (bbox.y1() + _radius), _radius, (-90 * deg), (0 * deg) );

    return( true );

  }


  //-------------------------------------------------------------
  // Draw the bubble starting on the right
  private bool draw_bubble_right( Context ctx, CanvasPoint? pa, CanvasPoint? pb ) {

    var pa_e = (pa != null) && (pa.x == bbox.x2());
    var pb_e = (pb != null) && (pb.x == bbox.x2());

    if( !pa_e && !pb_e ) return( false );

    var deg = Math.PI / 180.0;
    CanvasPoint p1, p2;

    if( pa.y < pb.y ) {
      p1 = pa;  p2 = pb;
    } else {
      p1 = pb;  p2 = pa;
    }

    var r1 = ((p1.y - bbox.y1()) < _radius) ? (p1.y - bbox.y1()) : _radius;
    var r2 = ((bbox.y2() - p2.y) < _radius) ? (bbox.y2() - p2.y) : _radius;
    ctx.arc( (bbox.x2() - r1), (bbox.y1() + r1), r1, (-90 * deg), (0 * deg) );
    ctx.line_to( p1.x, p1.y );
    ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
    ctx.line_to( p2.x, p2.y );
    ctx.arc( (bbox.x2() - r2), (bbox.y2() - r2), r2, (0 * deg), (90 * deg) );
    ctx.arc( (bbox.x1() + _radius), (bbox.y2() - _radius), _radius, (90 * deg),  (180 * deg) );
    ctx.arc( (bbox.x1() + _radius), (bbox.y1() + _radius), _radius, (180 * deg), (270 * deg) );

    return( true );

  }

  //-------------------------------------------------------------
  // Draw the bubble starting on the left
  private bool draw_bubble_left( Context ctx, CanvasPoint? pa, CanvasPoint? pb ) {

    var pa_w = (pa != null) && (pa.x == bbox.x1());
    var pb_w = (pb != null) && (pb.x == bbox.x1());

    if( !pa_w && !pb_w ) return( false );

    var deg = Math.PI / 180.0;
    CanvasPoint p1, p2;

    if( pa.y > pb.y ) {
      p1 = pa;  p2 = pb;
    } else {
      p1 = pb;  p2 = pa;
    }

    var r1 = ((bbox.y2() - p1.y) < _radius) ? (bbox.y2() - p1.y) : _radius;
    var r2 = (p2.y - (bbox.y1()) < _radius) ? (p2.y - bbox.y1()) : _radius;
    ctx.arc( (bbox.x1() + r1), (bbox.y2() - r1), r1, (90 * deg),  (180 * deg) );
    ctx.line_to( p1.x, p1.y );
    ctx.line_to( points.index( 8 ).x, points.index( 8 ).y );
    ctx.line_to( p2.x, p2.y );
    ctx.arc( (bbox.x1() + r2), (bbox.y1() + r2), r2, (180 * deg), (270 * deg) );
    ctx.arc( (bbox.x2() - _radius), (bbox.y1() + _radius), _radius, (-90 * deg), (0 * deg) );
    ctx.arc( (bbox.x2() - _radius), (bbox.y2() - _radius), _radius, (0 * deg), (90 * deg) );

    return( true );

  }

  //-------------------------------------------------------------
  // Draw a talking bubble.
  private void draw_bubble( Context ctx ) {

    var center = new CanvasPoint.from_coords( bbox.mid_x(), bbox.mid_y() );
    var deg    = Math.PI / 180.0;
    var rad    = (bbox.width < bbox.height) ? (bbox.width / 5) : (bbox.height / 5);
    var pt1    = new CanvasPoint();
    var pt2    = new CanvasPoint();
    var pa     = new CanvasPoint();  // Intersecting point
    var pb     = new CanvasPoint();  // Intersecting point

    var rul    = new CanvasPoint.from_coords( bbox.x1(), bbox.y1() );
    var rur    = new CanvasPoint.from_coords( bbox.x2(), bbox.y1() );
    var rll    = new CanvasPoint.from_coords( bbox.x1(), bbox.y2() );
    var rlr    = new CanvasPoint.from_coords( bbox.x2(), bbox.y2() );

    if( !find_tangents( center, rad, points.index( 8 ), pt1, pt2 ) ) return;

    if( get_line_intersection( pt1, points.index( 8 ), rul, rur, out pa ) ||
        get_line_intersection( pt1, points.index( 8 ), rur, rlr, out pa ) ||
        get_line_intersection( pt1, points.index( 8 ), rlr, rll, out pa ) ||
        get_line_intersection( pt1, points.index( 8 ), rll, rul, out pa ) ) {
      if( get_line_intersection( pt2, points.index( 8 ), rul, rur, out pb ) ||
          get_line_intersection( pt2, points.index( 8 ), rur, rlr, out pb ) ||
          get_line_intersection( pt2, points.index( 8 ), rlr, rll, out pb ) ||
          get_line_intersection( pt2, points.index( 8 ), rll, rul, out pb ) ) {
        ctx.new_sub_path();
        if( draw_bubble_top( ctx, pa, pb )  || draw_bubble_bottom( ctx, pa, pb ) ||
            draw_bubble_left( ctx, pa, pb ) || draw_bubble_right( ctx, pa, pb ) ) {
          ctx.close_path();
          return;
        }
      }
    }

    ctx.new_sub_path();
    ctx.arc( (bbox.x1() + _radius), (bbox.y1() + _radius), _radius, (180 * deg), (270 * deg) );
    ctx.arc( (bbox.x2() - _radius), (bbox.y1() + _radius), _radius, (-90 * deg), (0 * deg) );
    ctx.arc( (bbox.x2() - _radius), (bbox.y2() - _radius), _radius, (0 * deg),   (90 * deg) );
    ctx.arc( (bbox.x1() + _radius), (bbox.y2() - _radius), _radius, (90 * deg),  (180 * deg) );
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



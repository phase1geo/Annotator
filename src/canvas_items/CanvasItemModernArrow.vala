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

//-------------------------------------------------------------
// A clean, modern arrow: a uniform-width shaft with a rounded
// tail and a swept-back triangular head.  Shaft thickness follows
// the stroke width setting and the head scales with it.
public class CanvasItemModernArrow : CanvasItem {

  private enum PType {
    TAIL = 0,
    HEAD
  }

  private enum ArrowTailDirection {
    UPPER_LEFT,
    UPPER_RIGHT,
    LOWER_LEFT,
    LOWER_RIGHT;

    public string to_string() {
      switch( this ) {
        case UPPER_LEFT  :  return( "ul" );
        case UPPER_RIGHT :  return( "ur" );
        case LOWER_LEFT  :  return( "ll" );
        case LOWER_RIGHT :  return( "lr" );
        default          :  assert_not_reached();
      }
    }

    public static ArrowTailDirection parse( string val ) {
      switch( val ) {
        case "ul" :  return( UPPER_LEFT );
        case "ur" :  return( UPPER_RIGHT );
        case "ll" :  return( LOWER_LEFT );
        case "lr" :  return( LOWER_RIGHT );
        default   :  return( UPPER_LEFT );
      }
    }
  }

  private ArrowTailDirection _dir = ArrowTailDirection.UPPER_LEFT;
  private Cursor             _sel_cursor;

  //-------------------------------------------------------------
  // Constructor.
  public CanvasItemModernArrow( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.MODERN_ARROW, canvas, props );
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Tail
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Head
    _sel_cursor = new Cursor.from_name( "crosshair", null );
  }

  //-------------------------------------------------------------
  // Copies the given arrow item properties to this one.
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var arrow_item = (CanvasItemModernArrow)item;
    if( arrow_item != null ) {
      _dir = arrow_item._dir;
    }
  }

  //-------------------------------------------------------------
  // Returns a copy of this item.
  public override CanvasItem duplicate() {
    var item = new CanvasItemModernArrow( canvas, props );
    item.copy( this );
    return( item );
  }

  //-------------------------------------------------------------
  // Updates the selection points whenever the bounding box changes.
  protected override void bbox_changed() {
    var tail = points.index( PType.TAIL );
    var head = points.index( PType.HEAD );
    switch( _dir ) {
      case ArrowTailDirection.UPPER_LEFT :
        tail.copy_coords( bbox.x1(), bbox.y1() );
        head.copy_coords( bbox.x2(), bbox.y2() );
        break;
      case ArrowTailDirection.LOWER_LEFT :
        tail.copy_coords( bbox.x1(), bbox.y2() );
        head.copy_coords( bbox.x2(), bbox.y1() );
        break;
      case ArrowTailDirection.UPPER_RIGHT :
        tail.copy_coords( bbox.x2(), bbox.y1() );
        head.copy_coords( bbox.x1(), bbox.y2() );
        break;
      case ArrowTailDirection.LOWER_RIGHT :
        tail.copy_coords( bbox.x2(), bbox.y2() );
        head.copy_coords( bbox.x1(), bbox.y1() );
        break;
    }
  }

  //-------------------------------------------------------------
  // Moves the tail or head point and recomputes the bounding box.
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box  = new CanvasRect.from_rect( bbox );
    var tail = new CanvasPoint.from_point( points.index( PType.TAIL ) );
    var head = new CanvasPoint.from_point( points.index( PType.HEAD ) );

    switch( index ) {
      case PType.TAIL :  tail.x += diffx;  tail.y += diffy;  break;
      case PType.HEAD :  head.x += diffx;  head.y += diffy;  break;
      default         :  assert_not_reached();
    }

    if( tail.x < head.x ) {
      box.x = tail.x;
      if( tail.y < head.y ) {
        box.y = tail.y;
        _dir  = ArrowTailDirection.UPPER_LEFT;
      } else {
        box.y = head.y;
        _dir  = ArrowTailDirection.LOWER_LEFT;
      }
    } else {
      box.x = head.x;
      if( tail.y < head.y ) {
        box.y = tail.y;
        _dir  = ArrowTailDirection.UPPER_RIGHT;
      } else {
        box.y = head.y;
        _dir  = ArrowTailDirection.LOWER_RIGHT;
      }
    }

    box.width  = Math.fabs( head.x - tail.x );
    box.height = Math.fabs( head.y - tail.y );

    bbox = box;

  }

  //-------------------------------------------------------------
  // Provides cursor to display when mouse cursor is hovering over
  // the given selector.
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  //-------------------------------------------------------------
  // Saves the contents of this item in XML format.
  public override Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    node->set_prop( "dir", _dir.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this item with XML formatted data.
  public override void load( Xml.Node* node ) {
    var d = node->get_prop( "dir" );
    if( d != null ) {
      _dir = ArrowTailDirection.parse( d );
    }
    base.load( node );
  }

  //-------------------------------------------------------------
  // Builds the arrow outline as a single closed path.  Coordinates
  // are computed along the arrow axis (u) and perpendicular to it (v)
  // and then mapped to canvas space so the saved path can be used
  // directly for hit testing.
  private void build_path( Context ctx ) {

    var tx  = points.index( PType.TAIL ).x;
    var ty  = points.index( PType.TAIL ).y;
    var hx  = points.index( PType.HEAD ).x;
    var hy  = points.index( PType.HEAD ).y;
    var len = Math.sqrt( ((hx - tx) * (hx - tx)) + ((hy - ty) * (hy - ty)) );
    var ang = Math.atan2( (hy - ty), (hx - tx) );
    var cs  = Math.cos( ang );
    var sn  = Math.sin( ang );

    // Shaft half-thickness, head length/half-width and back notch
    var r     = props.stroke_width.width() / 2.0;
    var hl    = double.min( (14.0 + (r * 6.0)), (len * 0.6) );
    var hw    = double.max( (hl * 0.5), (r * 2.2) );
    var notch = hl * 0.22;
    var base_u = len - hl;

    ctx.new_path();
    ctx.move_to( (tx + (0 * cs) - (-r * sn)), (ty + (0 * sn) + (-r * cs)) );
    double[] us = { (base_u + notch), base_u, len, base_u, (base_u + notch), 0 };
    double[] vs = { -r,               -hw,    0,   hw,     r,                r };
    for( int i=0; i<us.length; i++ ) {
      ctx.line_to( (tx + (us[i] * cs) - (vs[i] * sn)), (ty + (us[i] * sn) + (vs[i] * cs)) );
    }
    ctx.arc( tx, ty, r, (ang + (Math.PI / 2)), (ang + (Math.PI * 1.5)) );
    ctx.close_path();

  }

  //-------------------------------------------------------------
  // Draws the arrow.
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var alpha = mode.alpha( props.alpha );

    ctx.set_line_join( LineJoin.ROUND );
    build_path( ctx );
    save_path( ctx, CanvasItemPathType.FILL );

    // Optional contrasting outline drawn underneath the fill
    if( props.outline ) {
      var outline = Granite.contrasting_foreground_color( props.color );
      set_color( ctx, color, outline, (alpha / 2) );
      ctx.set_line_width( 4 );
      ctx.stroke_preserve();
    }

    // Fill, plus a thin same-colour stroke to soften the corners
    set_color( ctx, color, props.color, alpha );
    ctx.fill_preserve();
    ctx.set_line_width( 1.5 );
    ctx.stroke();

  }

}

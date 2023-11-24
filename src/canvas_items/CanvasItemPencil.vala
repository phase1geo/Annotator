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

public class CanvasItemPencil : CanvasItem {

  private Array<CanvasPoint> _edit_points = new Array<CanvasPoint>();
  private Cursor             _sel_cursor;

  /* Constructor */
  public CanvasItemPencil( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.PENCIL, canvas, props );
    create_points();
    _sel_cursor = new Cursor.from_name( "grab" );
  }

  /* Creates the selection points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Start
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // End
  }

  /* Copies the given arrow item properties to this one */
  public override void copy( CanvasItem item ) {
    var cast_item = (item as CanvasItemPencil);
    if( cast_item == null ) return;
    base.copy( item );
    _edit_points.remove_range( 0, _edit_points.length );
    for( int i=0; i<cast_item._edit_points.length; i++ ) {
      var point = cast_item._edit_points.index( i );
      draw( point.x, point.y );
    }
  }

  /* Returns a copy of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemPencil( canvas, props );
    item.copy( this );
    return( item );
  }

  /* If a selector is moved, move the entire thing */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {
    move_item( diffx, diffy );
  }

  /* Move the item */
  public override void move_item( double diffx, double diffy, bool moving = true ) {
    for( int i=0; i<_edit_points.length; i++ ) {
      _edit_points.index( i ).adjust( diffx, diffy );
    }
    points.index( 0 ).adjust( diffx, diffy );
    points.index( 1 ).adjust( diffx, diffy );
  }

  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  /* Add an edit point */
  public override void draw( double x, double y ) {
    _edit_points.append_val( new CanvasPoint.from_coords( x, y, CanvasPointType.RESIZER0 ) );
    points.index( 0 ).copy( _edit_points.index( 0 ) );
    points.index( 1 ).copy( _edit_points.index( _edit_points.length - 1 ) );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    if( _edit_points.length == 0 ) return;

    var alpha   = mode.alpha( props.alpha );
    var outline = Granite.contrasting_foreground_color( props.color );
    var sw      = props.stroke_width.width();

    /* Draw the outline */
    if( props.outline ) {
      set_color( ctx, color, outline, (alpha / 2) );
      ctx.set_line_width( sw + 2 );
      ctx.set_line_cap( LineCap.ROUND );
      props.dash.set_bg_pattern( ctx );
    }

    ctx.move_to( _edit_points.index( 0 ).x, _edit_points.index( 0 ).y );

    for( int i=1; i<_edit_points.length; i++ ) {
      ctx.line_to( _edit_points.index( i ).x, _edit_points.index( i ).y );
    }

    save_path( ctx, CanvasItemPathType.STROKE );

    if( props.outline ) {
      ctx.stroke_preserve();
    }

    set_color( ctx, color, props.color, alpha );
    ctx.set_line_width( sw );
    props.dash.set_fg_pattern( ctx );
    ctx.stroke();

  }

}



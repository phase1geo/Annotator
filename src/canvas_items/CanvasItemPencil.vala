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

public class CanvasItemPencil : CanvasItem {

  private Array<CanvasPoint> _edit_points = new Array<CanvasPoint>();

  /* Constructor */
  public CanvasItemPencil( CanvasItemProperties props ) {
    base( "arrow", props );
    create_points();
  }

  /* Creates the selection points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // Start
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // End
  }

  /* Copies the given arrow item properties to this one */
  public override void copy( CanvasItem item ) {
    var cast_item = (item as CanvasItemPencil);
    if( cast_item == null ) return;
    base.copy( item );
    _edit_points.remove_range( 0, _edit_points.length );
    for( int i=0; i<cast_item._edit_points.length; i++ ) {
      _edit_points.append_val( new CanvasPoint.from_point( cast_item._edit_points.index( i ) ) );
    }
  }

  public override bool is_within( double x, double y ) {
    /* TBD */
    return( Utils.is_within_polygon( x, y, points ) );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var alpha   = mode.alpha( props.alpha );
    var outline = Granite.contrasting_foreground_color( props.color );
    var sw      = props.stroke_width.width();

    /* Draw the outline */
    Utils.set_context_color_with_alpha( ctx, outline, (alpha / 2) );
    ctx.set_line_width( sw + 2 );
    props.dash.set_bg_pattern( ctx );
    ctx.move_to( _edit_points.index( 0 ).x, _edit_points.index( 0 ).y );

    for( int i=1; i<_edit_points.length; i++ ) {
      ctx.line_to( _edit_points.index( i ).x, _edit_points.index( i ).y );
    }

    ctx.stroke_preserve();

    Utils.set_context_color_with_alpha( ctx, props.color, alpha );
    ctx.set_line_width( sw );
    props.dash.set_fg_pattern( ctx );
    ctx.stroke();

  }

}



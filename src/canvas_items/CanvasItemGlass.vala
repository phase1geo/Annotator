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

public class CanvasItemGlass : CanvasItem {

  private CanvasPoint _line_end = new CanvasPoint( CanvasPointType.NONE );

  /* Constructor */
  public CanvasItemGlass( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.GLASS, canvas, props );
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Resizes circle
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // Moves the line end
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    var radius        = bbox.width / 2;
    var RAD_distance  = ((2 * Math.PI) / 8);
    var RAD_half_PI   = Math.PI / 2;
    var new_outer_RAD = RAD_distance * 3;

    var x0 = bbox.mid_x() + Math.cos( (RAD_distance * 3) - RAD_half_PI ) * radius;
    var y0 = bbox.mid_y() + Math.sin( (RAD_distance * 3) - RAD_half_PI ) * radius;

    points.index( 0 ).copy_coords( x0, y0 );
    // points.index( 1 ).copy_coords( x1, y1 );

  }

  /*
   If the mode changes to RESIZING, capture the current zoom factor point in case it
   is the one being moved so that we can recalculate the proper zoom_factor value.
  */
  protected override void mode_changed() {
    if( mode == CanvasItemMode.RESIZING ) {
      _line_end.copy( points.index( 1 ) );
    }
  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    if( index == 0 ) {
      box.width  += diffy;
      box.height += diffy;
    } else {
      points.index( 1 ).x += diffx;
      points.index( 1 ).y += diffy;
    }

    bbox = box;

  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var alpha = mode.alpha( props.alpha );

    /* Draw circle */
    Utils.set_context_color_with_alpha( ctx, props.color, alpha );
    ctx.set_line_width( props.stroke_width.width() );
    ctx.arc( bbox.mid_x(), bbox.mid_y(), (bbox.width / 2), 0, (2 * Math.PI) );
    save_path( ctx, CanvasItemPathType.STROKE );
    ctx.stroke_preserve();

    /* Draw line outside of circle (but line always points to center */
    var cx     = bbox.mid_x();
    var cy     = bbox.mid_y();
    var radius = bbox.width / 2;
    var angle  = Math.atan2( (points.index( 1 ).y - cy), (points.index( 1 ).x - cx) );
    var x0     = cx + Math.cos( angle ) * radius;
    var y0     = cy + Math.sin( angle ) * radius;

    ctx.move_to( x0, y0 );
    ctx.line_to( points.index( 1 ).x, points.index( 1 ).y );
    save_path( ctx, CanvasItemPathType.STROKE );
    ctx.stroke_preserve();

  }

}



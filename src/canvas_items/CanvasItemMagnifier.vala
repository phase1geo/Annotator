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

public class CanvasItemMagnifier : CanvasItem {

  private const double max_zoom = 5.0;
  private const double min_zoom = 1.5;

  private CanvasImage _image;
  private double      _zoom_factor = 2.0;
  private CanvasRect  _zoom_rect   = new CanvasRect();
  private CanvasPoint _press       = new CanvasPoint();

  /* Constructor */
  public CanvasItemMagnifier( CanvasImage image, double zoom_factor, CanvasItemProperties props ) {
    base( "oval", props );
    _image       = image;
    _zoom_factor = zoom_factor;
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );  // Magnification
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // Resizer
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    var radius        = bbox.width / 2;
    var RAD_distance  = ((2 * Math.PI) / 8);
    var RAD_half_PI   = Math.PI / 2;
    var new_outer_RAD = RAD_distance * 3;
    var angle         = (((_zoom_factor - min_zoom) / (max_zoom - min_zoom)) - 1) * RAD_half_PI;

    var x0 = bbox.mid_x() + Math.cos( angle ) * radius;
    var y0 = bbox.mid_y() + Math.sin( angle ) * radius;

    var x1 = bbox.mid_x() + Math.cos( (RAD_distance * 3) - RAD_half_PI ) * radius;
    var y1 = bbox.mid_y() + Math.sin( (RAD_distance * 3) - RAD_half_PI ) * radius;

    points.index( 0 ).copy_coords( x0, y0 );
    points.index( 1 ).copy_coords( x1, y1 );

    update_zoom_rect();

  }

  /*
   If the mode changes to RESIZING, capture the current zoom factor point in case it
   is the one being moved so that we can recalculate the proper zoom_factor value.
  */
  protected override void mode_changed() {
    if( mode == CanvasItemMode.RESIZING ) {
      _press.copy( points.index( 0 ) );
    }
  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    if( index == 0 ) {
      _press.x += diffx;
      _press.y += diffy;
      var b = (_press.x - bbox.mid_x());
      var a = (bbox.mid_y() - _press.y);
      if( (a >= 0) && (b >= 0) ) {
        var half_PI = Math.PI / 2;
        var angle   = Math.atan( a / b );    // 0 = max zoom (5), PI/2 = min zoom (1)
        _zoom_factor = ((1 - (angle / half_PI)) * (max_zoom - min_zoom)) + min_zoom;
      }
    } else {
      box.width  += diffy;
      box.height += diffy;
    }

    if( box.width >= (selector_size * 3) ) {
      bbox = box;
    }

  }

  /* Returns the zoom rectangle */
  private void update_zoom_rect() {
    var width  = bbox.width / _zoom_factor;
    var adjust = (bbox.width - width) / 2;
    _zoom_rect.copy_coords( (bbox.x + adjust), (bbox.y + adjust), width, width );
  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( (index == 0) ? CursorType.HAND2 : CursorType.BOTTOM_RIGHT_CORNER );
  }

  /* Returns true if the given point is within this circle */
  public override bool is_within( double x, double y ) {
    return( Utils.is_within_oval( x, y, bbox.mid_x(), bbox.mid_y(), (bbox.width / 2), (bbox.width / 2) ) );
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "zoom-factor", _zoom_factor.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var f = node->get_prop( "zoom-factor" );
    if( f != null ) {
      _zoom_factor = double.parse( f );
    }
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var surface = _image.get_surface_for_rect( _zoom_rect );

    Utils.set_context_color_with_alpha( ctx, _image.average_color, 0.5 );

    ctx.set_line_width( 5 );
    ctx.arc( bbox.mid_x(), bbox.mid_y(), (bbox.width / 2), 0, (2 * Math.PI) );
    ctx.stroke_preserve();

    ctx.save();
    ctx.clip();
    ctx.new_path();
   	ctx.scale( _zoom_factor, _zoom_factor );
   	ctx.set_source_surface( surface, (bbox.x / _zoom_factor), (bbox.y / _zoom_factor) );
   	ctx.paint();
   	ctx.restore();

  }

}



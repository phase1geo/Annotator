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

  private CanvasImage _image;
  private double      _zoom_factor = 2.0;

  /* Constructor */
  public CanvasItemMagnifier( CanvasImage image, double zoom_factor, CanvasItemProperties props ) {
    base( "oval", props );
    _image       = image;
    _zoom_factor = zoom_factor;
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( true ) );  // Resizer
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x2(), bbox.y2() );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    box.width  += diffy;
    box.height += diffy;

    if( box.width >= (selector_size * 3) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.TCROSS );
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

    Utils.set_context_color_with_alpha( ctx, Utils.color_from_string( "black" ), 0.5 );

    _image.draw_magnifier( ctx, bbox, _zoom_factor );

  }

}



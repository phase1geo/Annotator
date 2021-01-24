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

public class CanvasItemImage : CanvasItem {

  private string        _filename;
  private Pixbuf        _buf;
  private ImageSurface? _surface;

  /* Constructor */
  public CanvasItemImage( Canvas canvas, string filename, CanvasItemProperties props ) {
    base( "image", canvas, props );
    create_points();
    create_image( filename );
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // Resizer
  }

  /* Creates a pixbuf from the given filename at full size */
  private void create_image( string filename ) {
    try {
      _filename = filename;
      _buf      = new Pixbuf.from_file_at_size( filename, -1, -1 );
      resize_image();
    } catch( Error e ) {
      _buf = null;
    }
  }

  /* Creates an image from the specified filename */
  private void resize_image( int width = -1 ) {
    if( _buf != null ) {
      var height = (width / _buf.width) * _buf.height;
      var buf    = (width == -1) ? _buf : _buf.scale_simple( width, height, InterpType.BILINEAR );
      _surface = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 1, null );
    }
  }

  /* Copies the contents of the given item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var img_item = (CanvasItemImage)item;
    if( img_item != null ) {
      _filename = img_item._filename;
      _buf      = img_item._buf.copy();
      resize_image();
    }
  }

  /* Returns a copy of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemImage( canvas, _filename, props );
    item.copy( this );
    return( item );
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x2(), bbox.y2() );

    if( _buf.width != (int)bbox.width ) {
      resize_image( (int)bbox.width );
    }

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    box.width += diffx;

    if( (box.width > 0) && ((int)box.width <= _buf.width) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.BOTTOM_RIGHT_CORNER );  // TBD
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "filename", _filename.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var f = node->get_prop( "filename" );
    if( f != null ) {
      _filename = f;
    }
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

   	ctx.set_source_surface( _surface, bbox.x, bbox.y );
    save_path( ctx, CanvasItemPathType.FILL );
   	ctx.paint();

  }

}



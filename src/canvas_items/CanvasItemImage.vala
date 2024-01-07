/*
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

public class CanvasItemImage : CanvasItem {

  private string? _name = null;
  private bool    _file = false;
  private Pixbuf? _buf  = null;
  private Cursor  _sel_cursor;

  /* Constructor */
  public CanvasItemImage( Canvas canvas, string? name, bool file, CanvasItemProperties props ) {
    base( (file ? CanvasItemType.IMAGE : CanvasItemType.STICKER), canvas, props );
    create_points();
    create_image( name, file, (file ? 300 : 64) );
    _sel_cursor = new Cursor.from_name( "se-resize", null );
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Resizer
  }

  /* Creates a pixbuf from the given filename or resource at full size */
  private void create_image( string? name, bool file, int width ) {
    if( name == null ) return;
    try {
      _name = name;
      _file = file;
      if( file ) {
        _buf = new Pixbuf.from_file_at_size( _name, width, -1 );
      } else {
        _buf = canvas.win.sticker_set.make_pixbuf( _name, width );
      }
    } catch( Error e ) {
      _buf = null;
    }
  }

  /* Creates an image from the specified filename */
  private void resize_image( int width = 0 ) {
    if( (_buf != null) && (width != 0) ) {
      create_image( _name, _file, width );
    }
  }

  /* Copies the contents of the given item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var img_item = (CanvasItemImage)item;
    if( img_item != null ) {
      _name = img_item._name;
      _file = img_item._file;
      _buf  = img_item._buf.copy();
      resize_image();
    }
  }

  /* Returns a copy of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemImage( canvas, _name, _file, props );
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
    var dy  = (diffx / box.width) * box.height;

    box.width  += diffx;
    box.height += dy;

    if( box.width > 5 ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "name", _name );
    node->set_prop( "file", _file.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var n = node->get_prop( "name" );
    if( n != null ) {
      _name = n;
    }
    var f = node->get_prop( "file" );
    if( f != null ) {
      _file = bool.parse( f );
    }
    create_image( _name, _file, (int)bbox.width );
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    ctx.set_line_width( 0 );
    ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
    save_path( ctx, CanvasItemPathType.FILL );
    ctx.stroke();

    cairo_set_source_pixbuf( ctx, _buf, bbox.x, bbox.y );
   	ctx.paint();

  }

}



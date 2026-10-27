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

public class CanvasItemImage : CanvasItem {

  private string? _name = null;
  private Pixbuf? _buf  = null;
  private Cursor  _sel_cursor;

  //-------------------------------------------------------------
  // Constructor.
  public CanvasItemImage( Canvas canvas, bool file, CanvasItemProperties props ) {
    base( (file ? CanvasItemType.IMAGE : CanvasItemType.STICKER), canvas, props );
    create_points();
    _sel_cursor = new Cursor.from_name( "se-resize", null );
  }

  //-------------------------------------------------------------
  // Creates the item points.
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Resizer
  }

  //-------------------------------------------------------------
  // Creates a pixbuf from the given filename or resource at full
  // size.
  public void create_image( string? name ) {
    if( name == null ) return;
    try {
      _name = name;
      if( itype == CanvasItemType.IMAGE ) {
        _buf = new Pixbuf.from_file_at_size( _name, (int)bbox.width, -1 );
      } else {
        _buf = StickerSet.make_pixbuf( _name, (int)bbox.width );
      }
      bbox.width  = _buf.width;
      bbox.height = _buf.height;
    } catch( Error e ) {
      _buf = null;
    }
  }

  public override int resize_selector() {
    return( 0 );
  }

  //-------------------------------------------------------------
  // Creates an image from the specified filename.
  private void resize_image() {
    create_image( _name );
  }

  //-------------------------------------------------------------
  // Copies the contents of the given item to ourselves.
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var img_item = (CanvasItemImage)item;
    if( img_item != null ) {
      _name = img_item._name;
      _buf  = img_item._buf.copy();
    }
  }

  //-------------------------------------------------------------
  // Returns a copy of this item.
  public override CanvasItem duplicate() {
    var item = new CanvasItemImage( canvas, (itype == CanvasItemType.IMAGE), props );
    item.copy( this );
    return( item );
  }

  //-------------------------------------------------------------
  // Updates the selection boxes whenever the bounding box changes.
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x2(), bbox.y2() );

    if( (_buf == null) || (_buf.width != (int)bbox.width) ) {
      resize_image();
    }

  }

  //-------------------------------------------------------------
  // Adjusts the bounding box.
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );
    var dy  = (diffx / box.width) * box.height;

    box.width  += diffx;
    box.height += (_buf == null) ? diffy : dy;

    if( (box.width > 5) && (box.height > 5) ) {
      bbox = box;
    }

  }

  //-------------------------------------------------------------
  // Provides cursor to display when mouse cursor is hovering over
  // the given selector.
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  //-------------------------------------------------------------
  // Saves this item as XML.
  public override Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    if( (image_dir != null) && (itype == CanvasItemType.IMAGE) ) {
      string[] options = { "compression" };
      string[] values  = { "9" };
      var fname = GLib.Path.build_filename( image_dir, "image%d.png".printf( id ) );
      try {
        _buf.savev( fname, "png", options, values );
        node->set_prop( "name", fname );
      } catch( Error e ) {
        critical( e.message );
      }
    } else {
      node->set_prop( "name", _name );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this item from XML.
  public override void load( Xml.Node* node ) {
    var n = node->get_prop( "name" );
    if( n != null ) {
      _name = n;
    }
    base.load( node );
    create_image( _name );
  }

  //-------------------------------------------------------------
  // Draw the rectangle.
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var alpha = mode.alpha( props.alpha );

    ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
    save_path( ctx, CanvasItemPathType.FILL );

    if( props.outline || (_buf == null) ) {
      var outline = Granite.contrasting_foreground_color( props.stroke_color );
      set_color( ctx, color, outline, 0.5 );
      if( props.stroke || (_buf == null) ) {
        props.dash.set_bg_pattern( ctx );
        ctx.set_line_width( props.stroke_width.width() + 2 );
        ctx.stroke_preserve();
      }
    }

    if( _buf != null ) {
      cairo_set_source_pixbuf( ctx, _buf, bbox.x, bbox.y );
     	ctx.paint_with_alpha( alpha );
    }

    if( props.stroke && (_buf != null) ) {
      set_color( ctx, color, props.stroke_color, alpha );
      ctx.set_line_width( props.stroke_width.width() );
      props.dash.set_fg_pattern( ctx );
      ctx.rectangle( bbox.x, bbox.y, bbox.width, bbox.height );
      ctx.stroke();
    }

  }

}



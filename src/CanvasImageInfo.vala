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

public class CanvasImageInfo {

  public int        width       { get; private set; default = 0; }
  public int        height      { get; private set; default = 0; }
  public CanvasRect pixbuf_rect { get; private set; default = new CanvasRect(); }

  //-------------------------------------------------------------
  // Constructor
  public CanvasImageInfo( Gdk.Pixbuf buf ) {
    width       = buf.width;
    height      = buf.height;
    pixbuf_rect = new CanvasRect.from_coords( 0, 0, width, height );
  }

  //-------------------------------------------------------------
  // Constructor from XML
  public CanvasImageInfo.from_xml( Xml.Node* node ) {
    load( node );
  }

  //-------------------------------------------------------------
  // Constructor
  public CanvasImageInfo.from_resizer( int pixbuf_width, int pixbuf_height, int top_margin, int right_margin, int bottom_margin, int left_margin ) {
    width  = left_margin + pixbuf_width + right_margin;
    height = top_margin + pixbuf_height + bottom_margin;
    pixbuf_rect = new CanvasRect.from_coords( left_margin, top_margin, pixbuf_width, pixbuf_height );
  }

  //-------------------------------------------------------------
  // Constructor - Creates an image info based on the amount of
  // angular rotation of the pixbuf with the given dimensions
  public CanvasImageInfo.with_rotation( int pixbuf_width, int pixbuf_height, double angle ) {

    var theta    = angle * (Math.PI / 180.0);
    var absCosRA = Math.fabs( Math.cos( theta ) );
    var absSinRA = Math.fabs( Math.sin( theta ) );

    width  = (int)((pixbuf_width * absCosRA) + (pixbuf_height * absSinRA));
    height = (int)((pixbuf_width * absSinRA) + (pixbuf_height * absCosRA));
    pixbuf_rect = new CanvasRect.from_coords( ((width - pixbuf_width) / 2), ((height - pixbuf_height) / 2), pixbuf_width, pixbuf_height );

  }

  //-------------------------------------------------------------
  // Copy constructor
  public CanvasImageInfo.from_info( CanvasImageInfo info ) {
    pixbuf_rect = new CanvasRect();
    copy( info );
  }

  //-------------------------------------------------------------
  // Copies the given information instance to ours
  public void copy( CanvasImageInfo info ) {
    width  = info.width;
    height = info.height;
    pixbuf_rect.copy( info.pixbuf_rect );
  }

  //-------------------------------------------------------------
  // Returns the proportional value of width to height of the pixbuf
  public double get_proportion() {
    return( (double)pixbuf_rect.width / pixbuf_rect.height );
  }

  //-------------------------------------------------------------
  // Returns the value of the largest side
  public int largest_side() {
    return( (width < height) ? height : width );
  }

  //-------------------------------------------------------------
  // Returns the amount of margin (in pixels) of the top margin
  // area
  public int top_margin() {
    return( (int)pixbuf_rect.y );
  }

  //-------------------------------------------------------------
  // Returns the amount of margin (in pixels) of the bottom margin
  // area
  public int bottom_margin() {
    return( height - (int)(pixbuf_rect.height + pixbuf_rect.y) );
  }

  //-------------------------------------------------------------
  // Returns the amount of margin (in pixels) of the left margin
  // area
  public int left_margin() {
    return( (int)pixbuf_rect.x );
  }

  //-------------------------------------------------------------
  // Returns the amount of margin (in pixels) of the right margin
  // area
  public int right_margin() {
    return( width - (int)(pixbuf_rect.width + pixbuf_rect.x) );
  }

  //-------------------------------------------------------------
  // Generates a string version of this class for debug output.
  public string to_string() {
    return( "width: %d, height: %d, pixbuf_rect: %s\n".printf( width, height, pixbuf_rect.to_string() ) );
  }

  //-------------------------------------------------------------
  // Saves the canvas image information in XML format.
  public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, "image-info" );

    node->set_prop( "width", width.to_string() );
    node->set_prop( "height", height.to_string() );

    node->add_child( pixbuf_rect.save( "rect" ) );

    return( node );

  }

  //-------------------------------------------------------------
  // Loads the canvas image information from XML format.
  private void load( Xml.Node* node ) {

    var w = node->get_prop( "width" );
    if( w != null ) {
      width = int.parse( w );
    }

    var h = node->get_prop( "height" );
    if( h != null ) {
      height = int.parse( h );
    }

    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "rect") ) {
        pixbuf_rect.load( it );
      }
    }

  }

}


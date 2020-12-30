/*
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

public enum CanvasItemMode {
  NONE,
  SELECTED;

  public string to_string() {
    switch( this ) {
      case NONE     :  return( "none" );
      case SELECTED :  return( "selected" );
      default       :  assert_not_reached();
    }
  }

  public static CanvasItemMode parse( string value ) {
    switch( value ) {
      case "none"     :  return( NONE );
      case "selected" :  return( SELECTED );
      default         :  assert_not_reached();
    }
  }
}

public enum CanvasItemType {
  SHAPE,
  SELECTBOX
}

public class CanvasItem {

  private string         _name = "unknown";
  private CanvasRect     _bbox = new CanvasRect();
  private CanvasItemMode _mode = CanvasItemMode.NONE;

  protected Array<CanvasPoint> selects { get; set; default = new Array<CanvasPoint>(); }
  protected const int          select_offset = 3;

  public CanvasRect bbox {
    get {
      return( _bbox );
    }
    set {
      _bbox.copy( value );
      bbox_changed();
    }
  }
  public CanvasItemMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        mode_changed();
      }
    }
  }
  public RGBA fill         { get; set; default = {1.0, 1.0, 1.0, 1.0}; }
  public RGBA stroke       { get; set; default = {1.0, 1.0, 1.0, 1.0}; }
  public int  stroke_width { get; set; default = 4; }

  /* Constructor */
  public CanvasItem( string name, double x, double y, RGBA fill, RGBA stroke, int stroke_width ) {

    _name   = name;
    _bbox.x = x;
    _bbox.y = y;

    this.fill         = fill;
    this.stroke       = stroke;
    this.stroke_width = stroke_width;

  }

  /* Called whenever the bounding box changes */
  protected virtual void bbox_changed() {}

  /* Called whenever the mode changes */
  protected virtual void mode_changed() {}

  protected double x1() {
    return( _bbox.x );
  }

  protected double y1() {
    return( _bbox.y );
  }

  protected double x2() {
    return( _bbox.x + _bbox.width );
  }

  protected double y2() {
    return( _bbox.y + _bbox.height );
  }

  /* Moves the item by the given amount */
  public void move_item( double diffx, double diffy ) {
    bbox.x += diffx;
    bbox.y += diffy;
    bbox_changed();
  }

  /* Adjusts the specified selector by the given amount */
  public virtual void move_selector( int index, double diffx, double diffy ) {}

  /* Returns the type of cursor to use for the given selection cursor */
  public virtual CursorType? get_selector_cursor( int index ) {
    return( CursorType.HAND2 );
  }

  /* Resizes the item when it is being drawn */
  public virtual void resize( double diffx, double diffy ) {
    var width  = bbox.width  + diffx;
    var height = bbox.height + diffy;
    if( (width > 0) && (height > 0) ) {
      bbox.width  = width;
      bbox.height = height;
      bbox_changed();
    }
  }

  /* Returns the bounding box of the given selector */
  private void selector_bbox( int index, CanvasRect rect ) {
    var sel  = selects.index( index );
    rect.x      = sel.x;
    rect.y      = sel.y;
    rect.width  = 10;
    rect.height = 10;
  }

  /* Returns true if this item is within the selection box (calculated with an intersection function */
  public virtual bool is_within_box( CanvasRect box ) {
    return( bbox.intersects( box ) );
  }

  /* Returns true if the given coordinates are within this item */
  public bool is_within( double x, double y ) {
    return( bbox.contains( x, y ) );
  }

  /* Returns the selector index that is below the current pointer coordinate */
  public int is_within_selector( double x, double y ) {
    if( mode != CanvasItemMode.SELECTED ) return( -1 );
    var box = new CanvasRect();
    for( int i=0; i<selects.length; i++ ) {
      selector_bbox( i, box );
      if( box.contains( x, y ) ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Draw the current item */
  public virtual void draw_item( Context ctx ) {}

  /* Draws the current item and draws the selection points, if necessary */
  public void draw( Context ctx ) {
    draw_item( ctx );
    draw_selects( ctx );
  }

  /* Draw the selection boxes */
  protected void draw_selects( Context ctx ) {

    if( mode != CanvasItemMode.SELECTED ) return;

    var blue  = Utils.color_from_string( "light blue" );
    var black = Utils.color_from_string( "black" );

    for( int i=0; i<selects.length; i++ ) {

      var select = selects.index( i );
      ctx.set_line_width( 1 );

      /* Draw the selection rectangle */
      Utils.set_context_color( ctx, blue );
      ctx.rectangle( select.x, select.y, 10, 10 );
      ctx.fill_preserve();

      /* Draw the stroke */
      Utils.set_context_color( ctx, black );
      ctx.stroke();

    }

  }

  /* Saves the item in XML format */
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "item" );
    node->set_prop( "x",      bbox.x.to_string() );
    node->set_prop( "y",      bbox.y.to_string() );
    node->set_prop( "w",      bbox.width.to_string() );
    node->set_prop( "h",      bbox.height.to_string() );
    node->set_prop( "mode",   mode.to_string() );
    node->set_prop( "fill",   Utils.color_from_rgba( fill ) );
    node->set_prop( "stroke", Utils.color_from_rgba( stroke ) );
    return( node );
  }

  /* Loads the item in XML format */
  public virtual void load( Xml.Node* node ) {

    var x = node->get_prop( "x" );
    if( x != null ) {
      bbox.x = int.parse( x );
    }
    var y = node->get_prop( "y" );
    if( y != null ) {
      bbox.y = int.parse( y );
    }
    var w = node->get_prop( "w" );
    if( w != null ) {
      bbox.width = int.parse( w );
    }
    var h = node->get_prop( "h" );
    if( h != null ) {
      bbox.height = int.parse( h );
    }
    var m = node->get_prop( "mode" );
    if( m != null ) {
      mode = CanvasItemMode.parse( m );
    }
    var f = node->get_prop( "fill" );
    if( f != null ) {
      fill.parse( f );
    }
    var s = node->get_prop( "stroke" );
    if( s != null ) {
      stroke.parse( s );
    }

  }

}



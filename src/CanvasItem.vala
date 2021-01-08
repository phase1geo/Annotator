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
  SELECTED,
  MOVING;

  public string to_string() {
    switch( this ) {
      case NONE     :  return( "none" );
      case SELECTED :  return( "selected" );
      case MOVING   :  return( "moving" );
      default       :  assert_not_reached();
    }
  }

  public static CanvasItemMode parse( string value ) {
    switch( value ) {
      case "none"     :  return( NONE );
      case "selected" :  return( SELECTED );
      case "moving"   :  return( MOVING );
      default         :  assert_not_reached();
    }
  }

  /* Returns true if the item can be moved */
  public bool can_move() {
    return( (this == SELECTED) || (this == MOVING) );
  }

  /* Returns the alpha value to use for drawing an item based on the current mode */
  public double alpha() {
    return( (this == MOVING) ? 0.5 : 1.0 );
  }

}

public enum CanvasItemDashPattern {
  NONE,
  SHORT,
  LONG,
  NUM;

  /* Converts this value to a string */
  public string to_string() {
    switch( this ) {
      case NONE  :  return( "none" );
      case SHORT :  return( "short" );
      case LONG  :  return( "long" );
      default    :  assert_not_reached();
    }
  }

  /* Converts a string to this value type */
  public static CanvasItemDashPattern parse( string value ) {
    switch( value ) {
      case "none"  :  return( NONE );
      case "short" :  return( SHORT );
      case "long"  :  return( LONG );
      default      :  assert_not_reached();
    }
  }

  /* Sets the background dash pattern based on the current value */
  public void set_bg_pattern( Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},      0 );  break;
      case SHORT :  ctx.set_dash( { 9, 3}, 0 );  break;
      case LONG  :  ctx.set_dash( {14, 6}, 0 );  break;
    }
  }

  /* Sets the foreground dash pattern based on the current value */
  public void set_fg_pattern( Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},        0 );  break;
      case SHORT :  ctx.set_dash( { 5,  5}, -2 );  break;
      case LONG  :  ctx.set_dash( {10, 10}, -2 );  break;
    }
  }
}

/* Structure containing formatting properties used by canvas items */
public class CanvasItemProperties {

  public RGBA                  color        = Utils.color_from_string( "black" );
  public int                   stroke_width = 4;
  public CanvasItemDashPattern dash         = CanvasItemDashPattern.NONE;

  /* Default constructor */
  public CanvasItemProperties() {}

  /* Constructor */
  public CanvasItemProperties.initialize( RGBA c, int sw, CanvasItemDashPattern d ) {
    color        = c;
    stroke_width = sw;
    dash         = d;
  }

  /* Copies the properties to this class */
  public void copy( CanvasItemProperties props ) {
    color        = props.color;
    stroke_width = props.stroke_width;
    dash         = props.dash;
  }

  /* Saves the contents of this properties class as XML */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "properties" );
    node->set_prop( "color",        Utils.color_to_string( color ) );
    node->set_prop( "stroke-width", stroke_width.to_string() );
    node->set_prop( "dash",         dash.to_string() );
    return( node );
  }

  /* Loads the contents of this properties class from XML */
  public void load( Xml.Node* node ) {
    var c = node->get_prop( "color" );
    if( c != null ) {
      color.parse( c );
    }
    var sw = node->get_prop( "stroke-width" );
    if( sw != null ) {
      stroke_width = int.parse( sw );
    }
    var d = node->get_prop( "dash" );
    if( d != null ) {
      dash = CanvasItemDashPattern.parse( d );
    }
  }

}

public class CanvasItem {

  private CanvasRect     _bbox = new CanvasRect();
  private CanvasItemMode _mode = CanvasItemMode.NONE;

  protected Array<CanvasPoint> points { get; set; default = new Array<CanvasPoint>(); }
  protected double             selector_size = 10;

  public string name { get; private set; default = "unknown"; }
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
  public CanvasItemProperties props { get; set; default = new CanvasItemProperties(); }

  /* Constructor */
  public CanvasItem( string name, CanvasItemProperties props ) {
    this.name  = name;
    this.props.copy( props );
  }

  /* Creates a copy of the given canvas item */
  public virtual void copy( CanvasItem item ) {

    _bbox.copy( item.bbox );
    _mode = item.mode;
    props.copy( item.props );

    for( int i=0; i<item.points.length; i++ ) {
      points.index( i ).copy( item.points.index( i ) );
    }

  }

  /* Called whenever the bounding box changes */
  protected virtual void bbox_changed() {}

  /* Called whenever the mode changes */
  protected virtual void mode_changed() {}

  /* Moves the item by the given amount */
  public void move_item( double diffx, double diffy ) {
    mode = CanvasItemMode.MOVING;
    bbox.x += diffx;
    bbox.y += diffy;
    bbox_changed();
  }

  /*
   This should be called in the move_selector method if the item responds to the
   shift key.
  */
  protected void adjust_diffs( bool shift, CanvasRect box, ref double diffx, ref double diffy ) {
    if( !shift ) return;
    if( box.width != box.height ) {
      box.width  = (box.width < box.height) ? box.width : box.height;
      box.height = (box.width < box.height) ? box.width : box.height;
    }
    if( Math.fabs( diffx ) < Math.fabs( diffy ) ) {
      diffx = diffy;
    } else {
      diffy = diffx;
    }
  }

  /* Adjusts the specified selector by the given amount */
  public virtual void move_selector( int index, double diffx, double diffy, bool shift ) {}

  /* Returns the type of cursor to use for the given selection cursor */
  public virtual CursorType? get_selector_cursor( int index ) {
    return( CursorType.HAND2 );
  }

  /* Returns the bounding box of the given selector */
  private void selector_bbox( int index, CanvasRect rect ) {
    var sel     = points.index( index );
    rect.x      = sel.x - (selector_size / 2);
    rect.y      = sel.y - (selector_size / 2);
    rect.width  = selector_size;
    rect.height = selector_size;
  }

  /* Returns true if this item is within the selection box (calculated with an intersection function */
  public virtual bool is_within_box( CanvasRect box ) {
    return( bbox.intersects( box ) );
  }

  /* Returns true if the given coordinates are within this item */
  public virtual bool is_within( double x, double y ) {
    return( bbox.contains( x, y ) );
  }

  /* Returns the selector index that is below the current pointer coordinate */
  public int is_within_selector( double x, double y ) {
    if( mode != CanvasItemMode.SELECTED ) return( -1 );
    var box = new CanvasRect();
    for( int i=0; i<points.length; i++ ) {
      if( points.index( i ).draw ) {
        selector_bbox( i, box );
        if( box.contains( x, y ) ) {
          return( i );
        }
      }
    }
    return( -1 );
  }

  /* Draw the current item */
  public virtual void draw_item( Context ctx ) {}

  /* Draw the selection boxes */
  public void draw_selectors( Context ctx ) {

    if( mode != CanvasItemMode.SELECTED ) return;

    var blue  = Utils.color_from_string( "light blue" );
    var black = Utils.color_from_string( "black" );
    var box   = new CanvasRect();

    for( int i=0; i<points.length; i++ ) {

      if( points.index( i ).draw ) {

        selector_bbox( i, box );

        ctx.set_line_width( 1 );

        /* Draw the selection rectangle */
        Utils.set_context_color( ctx, blue );
        ctx.rectangle( box.x, box.y, box.width, box.height );
        ctx.fill_preserve();

        /* Draw the stroke */
        Utils.set_context_color( ctx, black );
        ctx.stroke();

      }

    }

  }

  /* Saves the item in XML format */
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, name );
    node->set_prop( "x",    bbox.x.to_string() );
    node->set_prop( "y",    bbox.y.to_string() );
    node->set_prop( "w",    bbox.width.to_string() );
    node->set_prop( "h",    bbox.height.to_string() );
    node->set_prop( "mode", mode.to_string() );
    node->add_child( props.save() );
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

    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "properties") ) {
        props.load( it );
      }
    }

  }

}



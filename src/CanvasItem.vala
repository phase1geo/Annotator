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

public enum CanvasItemMode {
  NONE,
  SELECTED,
  MOVING,
  RESIZING;

  public string to_string() {
    switch( this ) {
      case NONE     :  return( "none" );
      case SELECTED :  return( "selected" );
      case MOVING   :  return( "moving" );
      case RESIZING :  return( "resizing" );
      default       :  assert_not_reached();
    }
  }

  public static CanvasItemMode parse( string value ) {
    switch( value ) {
      case "none"     :  return( NONE );
      case "selected" :  return( SELECTED );
      case "moving"   :  return( MOVING );
      case "resizing" :  return( RESIZING );
      default         :  assert_not_reached();
    }
  }

  /* Returns true if the item can be moved */
  public bool can_move() {
    return( (this == SELECTED) || (this == MOVING) );
  }

  /* Returns true if the item is being moved/resized */
  public bool moving() {
    return( (this == MOVING) || (this == RESIZING) );
  }

  /* Returns the alpha value to use for drawing an item based on the current mode */
  public double alpha( double dflt = 1.0 ) {
    return( ((this == MOVING) || (this == RESIZING)) ? (dflt * 0.5) : dflt );
  }

  /* Returns true if the canvas item should display the selectors */
  public bool draw_selectors() {
    return( (this == SELECTED) || (this == RESIZING) );
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
    if( !mode.draw_selectors() ) return( -1 );
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

    if( !mode.draw_selectors() ) return;

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



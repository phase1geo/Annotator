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

public enum CanvasPointType {
  NONE,
  RESIZER0,
  RESIZER1,
  RESIZER2,
  RESIZER3,
  HIDDEN0,   // This is a resizer that is currently hidden from view
  HIDDEN1,   // This is a resizer that is currently hidden from view
  HIDDEN2,   // This is a resizer that is currently hidden from view
  HIDDEN3,   // This is a resizer that is currently hidden from view
  CONTROL,
  SELECTOR;

  //-------------------------------------------------------------
  // Returns the string version of this type.
  public string to_string() {
    switch( this ) {
      case RESIZER0 :  return( "resizer0" );
      case RESIZER1 :  return( "resizer1" );
      case RESIZER2 :  return( "resizer2" );
      case RESIZER3 :  return( "resizer3" );
      case HIDDEN0  :  return( "hidden0" );
      case HIDDEN1  :  return( "hidden1" );
      case HIDDEN2  :  return( "hidden2" );
      case HIDDEN3  :  return( "hidden3" );
      case CONTROL  :  return( "control" );
      case SELECTOR :  return( "selector" );
      default       :  return( "none" );
    }
  }

  //-------------------------------------------------------------
  // Parses the given string and returns its CanvasPointType value.
  public static CanvasPointType parse( string value ) {
    switch( value ) {
      case "resizer0" :  return( RESIZER0 );
      case "resizer1" :  return( RESIZER1 );
      case "resizer2" :  return( RESIZER2 );
      case "resizer3" :  return( RESIZER3 );
      case "hidden0"  :  return( HIDDEN0 );
      case "hidden1"  :  return( HIDDEN1 );
      case "hidden2"  :  return( HIDDEN2 );
      case "hidden3"  :  return( HIDDEN3 );
      case "control"  :  return( CONTROL );
      case "selector" :  return( SELECTOR );
      default         :  return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns the hidden/shown version of the current type.
  public CanvasPointType version( bool hide ) {
    switch( this ) {
      case RESIZER0 :  return( hide ? HIDDEN0 : RESIZER0 );
      case RESIZER1 :  return( hide ? HIDDEN1 : RESIZER1 );
      case RESIZER2 :  return( hide ? HIDDEN2 : RESIZER2 );
      case RESIZER3 :  return( hide ? HIDDEN3 : RESIZER3 );
      case HIDDEN0  :  return( hide ? HIDDEN0 : RESIZER0 );
      case HIDDEN1  :  return( hide ? HIDDEN1 : RESIZER1 );
      case HIDDEN2  :  return( hide ? HIDDEN2 : RESIZER2 );
      case HIDDEN3  :  return( hide ? HIDDEN3 : RESIZER3 );
      default       :  return( this );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this point should be drawn.
  public bool draw() {
    return( (this == RESIZER0) || (this == RESIZER1) || (this == RESIZER2) || (this == RESIZER3) || (this == CONTROL) || (this == SELECTOR) );
  }

  //-------------------------------------------------------------
  // Returns the color to draw the given point.
  public Gdk.RGBA color() {
    switch( this ) {
      case SELECTOR :
      case HIDDEN0  :
      case HIDDEN1  :
      case HIDDEN2  :
      case HIDDEN3  :
      case RESIZER0 :
      case RESIZER1 :
      case RESIZER2 :
      case RESIZER3 :  return( Utils.color_from_string( "light blue" ) );
      case CONTROL  :  return( Utils.color_from_string( "yellow" ) );
      default       :  return( Utils.color_from_string( "white" ) );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the kind is hidden.
  public bool is_hidden() {
    return( (this == HIDDEN0) || (this == HIDDEN1) || (this == HIDDEN2) || (this == HIDDEN3) );
  }

}

public class CanvasPoint {

  public double          x    { get; set; default = 0.0; }
  public double          y    { get; set; default = 0.0; }
  public CanvasPointType kind { get; private set; default = CanvasPointType.NONE; }

  //-------------------------------------------------------------
  // Constructor.
  public CanvasPoint( CanvasPointType kind = CanvasPointType.NONE ) {
    this.kind = kind;
  }

  //-------------------------------------------------------------
  // Copy constructor
  public CanvasPoint.from_point( CanvasPoint point ) {
    copy( point );
  }

  //-------------------------------------------------------------
  // Constructor.
  public CanvasPoint.from_coords( double x, double y, CanvasPointType kind = CanvasPointType.NONE ) {
    copy_coords( x, y );
    this.kind = kind;
  }

  //-------------------------------------------------------------
  // Copies the point information to this instance.
  public void copy( CanvasPoint point ) {
    this.x    = point.x;
    this.y    = point.y;
    this.kind = point.kind;
  }

  //-------------------------------------------------------------
  // Copies the x,y coordinates to this instance.
  public void copy_coords( double x, double y ) {
    this.x = x;
    this.y = y;
  }

  //-------------------------------------------------------------
  // Adjust the point by the given amounts.
  public void adjust( double diffx, double diffy ) {
    this.x += diffx;
    this.y += diffy;
  }

  //-------------------------------------------------------------
  // Resets the visual aspect of this point to non-hidden state.
  public void reset_visual() {
    kind = kind.version( false );
  }

  //-------------------------------------------------------------
  // Updates the visual status of this point kind.
  public void set_visual( CanvasPointType point_kind, bool hide ) {
    if( point_kind != kind ) {
      kind = kind.version( hide );
    }
  }

  //-------------------------------------------------------------
  // Returns a printable version of this point.
  public string to_string() {
    return( "x: %g, y: %g, kind: %s".printf( x, y, kind.to_string() ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of this point in XML format.
  public Xml.Node* save( string name ) {
    Xml.Node* node = new Xml.Node( null, name );
    node->set_prop( "x", x.to_string() );
    node->set_prop( "y", y.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this point
  public void load( Xml.Node* node ) {

    var x = node->get_prop( "x" );
    if( x != null ) {
      this.x = double.parse( x );
    }

    var y = node->get_prop( "y" );
    if( y != null ) {
      this.y = double.parse( y );
    }

  }

}


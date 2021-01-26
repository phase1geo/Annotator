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
  RESIZER,
  CONTROL,
  SELECTOR;

  /* Returns the string version of this type */
  public string to_string() {
    switch( this ) {
      case RESIZER  :  return( "resizer" );
      case CONTROL  :  return( "control" );
      case SELECTOR :  return( "selector" );
      default       :  return( "none" );
    }
  }

  /* Returns true if this point should be drawn */
  public bool draw() {
    return( this != NONE );
  }

  /* Returns the color to draw the given point */
  public Gdk.RGBA color() {
    switch( this ) {
      case SELECTOR :
      case RESIZER  :  return( Utils.color_from_string( "light blue" ) );
      case CONTROL  :  return( Utils.color_from_string( "yellow" ) );
      default       :  return( Utils.color_from_string( "white" ) );
    }
  }
}

public class CanvasPoint {

  public double          x    { get; set; default = 0.0; }
  public double          y    { get; set; default = 0.0; }
  public CanvasPointType kind { get; private set; default = CanvasPointType.NONE; }

  /* Constructor */
  public CanvasPoint( CanvasPointType kind = CanvasPointType.NONE ) {
    this.kind = kind;
  }

  /* Copy constructor */
  public CanvasPoint.from_point( CanvasPoint point ) {
    copy( point );
  }

  /* Constructor */
  public CanvasPoint.from_coords( double x, double y, CanvasPointType kind = CanvasPointType.NONE ) {
    copy_coords( x, y );
    this.kind = kind;
  }

  /* Copies the point information to this instance */
  public void copy( CanvasPoint point ) {
    this.x    = point.x;
    this.y    = point.y;
    this.kind = point.kind;
  }

  /* Copies the x,y coordinates to this instance */
  public void copy_coords( double x, double y ) {
    this.x = x;
    this.y = y;
  }

  /* Adjust the point by the given amounts */
  public void adjust( double diffx, double diffy ) {
    this.x += diffx;
    this.y += diffy;
  }

  /* Returns a printable version of this point */
  public string to_string() {
    return( "x: %g, y: %g, kind: %s".printf( x, y, kind.to_string() ) );
  }

}


/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
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

public class CanvasPoint {

  public double x    { get; set; default = 0.0; }
  public double y    { get; set; default = 0.0; }
  public bool   draw { get; private set; default = false; }

  /* Constructor */
  public CanvasPoint( bool draw = false ) {
    this.draw = draw;
  }

  /* Copy constructor */
  public CanvasPoint.from_point( CanvasPoint point ) {
    copy( point );
  }

  /* Constructor */
  public CanvasPoint.with_coords( double x, double y, bool draw = false ) {
    copy_coords( x, y );
    this.draw = draw;
  }

  /* Copies the point information to this instance */
  public void copy( CanvasPoint point ) {
    this.x    = point.x;
    this.y    = point.y;
    this.draw = point.draw;
  }

  /* Copies the x,y coordinates to this instance */
  public void copy_coords( double x, double y ) {
    this.x = x;
    this.y = y;
  }

  /* Returns a printable version of this point */
  public string to_string() {
    return( "x: %g, y: %g, draw: %s".printf( x, y, draw.to_string() ) );
  }

}

public class CanvasRect {

  public double x      { get; set; default = 0.0; }
  public double y      { get; set; default = 0.0; }
  public double width  { get; set; default = 0.0; }
  public double height { get; set; default = 0.0; }

  /* Constructor */
  public CanvasRect() {}

  /* Constructor */
  public CanvasRect.from_coords( double x, double y, double width, double height ) {
    this.x      = x;
    this.y      = y;
    this.width  = width;
    this.height = height;
  }

  /* Copy constructor */
  public CanvasRect.from_rect( CanvasRect rect ) {
    copy( rect );
  }

  /* Makes a copy of the given rectangle */
  public void copy( CanvasRect rect ) {
    x      = rect.x;
    y      = rect.y;
    width  = rect.width;
    height = rect.height;
  }

  /* Returns the x1 value */
  public double x1() {
    return( x );
  }

  /* Returns the y1 value */
  public double y1() {
    return( y );
  }

  /* Returns the x2 value */
  public double x2() {
    return( (x + width) );
  }

  /* Returns the y2 value */
  public double y2() {
    return( (y + height) );
  }

  /* Returns the mid-point between x1 and x2 */
  public double mid_x() {
    return( x + (width / 2) );
  }

  /* Returns the mid-point between y1 and y2 */
  public double mid_y() {
    return( y + (height / 2) );
  }

  /* Returns true if the given rectangle intersects with this rectangle */
  public bool intersects( CanvasRect rect ) {
    var x5 = (x1() < rect.x1()) ? rect.x1() : x1();
    var y5 = (y2() < rect.y2()) ? rect.y2() : y2();
    var x6 = (x2() < rect.x2()) ? x2() : rect.x2();
    var y6 = (y1() < rect.y1()) ? y1() : rect.y1();
    return( (x5 <= x6) && (y6 <= y5) );
  }

  /* Returns true if this rectangle contains the given point */
  public bool contains( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, this.y, this.width, this.height ) );
  }

  /* Creates a rectangle that is a drawable version of this rectangle */
  public void normalize( out CanvasRect rect ) {
    rect = new CanvasRect.from_coords(
      ((width  < 0) ? (x + width)  : x),
      ((height < 0) ? (y + height) : y),
      ((width  < 0) ? (0 - width)  : width),
      ((height < 0) ? (0 - height) : height)
    );
  }

  /* Returns a string version of this rectangle */
  public string to_string() {
    return( "x: %g, y: %g, w: %g, h: %g".printf( x, y, width, height ) );
  }

}



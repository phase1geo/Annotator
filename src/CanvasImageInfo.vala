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

public class CanvasImageInfo {

  public int        width       { get; private set; default = 0; }
  public int        height      { get; private set; default = 0; }
  public CanvasRect pixbuf_rect { get; private set; default = new CanvasRect(); }

  /* Constructor */
  public CanvasImageInfo( Gdk.Pixbuf buf ) {
    width       = buf.width;
    height      = buf.height;
    pixbuf_rect = new CanvasRect.from_coords( 0, 0, width, height );
  }

  /* Constructor */
  public CanvasImageInfo.from_resizer( int pixbuf_width, int pixbuf_height, int top_margin, int right_margin, int bottom_margin, int left_margin ) {
    width  = left_margin + pixbuf_width + right_margin;
    height = top_margin + pixbuf_height + bottom_margin;
    pixbuf_rect = new CanvasRect.from_coords( left_margin, top_margin, pixbuf_width, pixbuf_height );
  }

  /* Copy constructor */
  public CanvasImageInfo.from_info( CanvasImageInfo info ) {
    pixbuf_rect = new CanvasRect();
    copy( info );
  }

  /* Copies the given information instance to ours */
  public void copy( CanvasImageInfo info ) {
    width  = info.width;
    height = info.height;
    pixbuf_rect.copy( info.pixbuf_rect );
  }

  /* Returns the proportional value of width to height of the pixbuf */
  public double get_proportion() {
    return( (double)pixbuf_rect.width / pixbuf_rect.height );
  }

  /* Returns the value of the largest side */
  public int largest_side() {
    return( (width < height) ? height : width );
  }

  /* Returns the amount of margin (in pixels) of the top margin area */
  public int top_margin() {
    return( (int)pixbuf_rect.y );
  }

  /* Returns the amount of margin (in pixels) of the bottom margin area */
  public int bottom_margin() {
    return( height - (int)(pixbuf_rect.height + pixbuf_rect.y) );
  }

  /* Returns the amount of margin (in pixels) of the left margin area */
  public int left_margin() {
    return( (int)pixbuf_rect.x );
  }

  /* Returns the amount of margin (in pixels) of the right margin area */
  public int right_margin() {
    return( width - (int)(pixbuf_rect.width + pixbuf_rect.x) );
  }

  /* Generates a string version of this class for debug output */
  public string to_string() {
    return( "width: %d, height: %d, pixbuf_rect: %s\n".printf( width, height, pixbuf_rect.to_string() ) );
  }

}


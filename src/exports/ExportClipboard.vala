/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

public class ExportClipboard : Object {

  private Canvas _canvas;

  /* Default constructor */
  public ExportClipboard( Canvas canvas ) {
    _canvas = canvas;
  }

  public void export( ImageSurface source ) {

    /* Create the drawing surface */
    var surface = new ImageSurface( Format.RGB24, source.get_width(), source.get_height() );
    var context = new Context( surface );
    _canvas.draw_all( context );

    /* Get the pixbuf */
    var pixbuf = pixbuf_get_from_surface( surface, 0, 0, surface.get_width(), surface.get_height() );

    /* Copy the image to the clipboard */
    AnnotatorClipboard.copy_image( pixbuf );

  }

}

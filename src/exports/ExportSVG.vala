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

using Cairo;

public class ExportSVG : Export {

  /* Constructor */
  public ExportSVG( Canvas canvas ) {
    base( canvas, "svg", _( "SVG" ), { ".svg" } );
  }

  /* Default constructor */
  public override bool export( string filename, ImageSurface source ) {

    /* Get the rectangle holding the entire document */
    var x = 0;
    var y = 0;
    var w = source.get_width();
    var h = source.get_height();

    /* Create the drawing surface */
    var surface = new SvgSurface( filename, w, h );
    var context = new Context( surface );

    surface.restrict_to_version( SvgVersion.VERSION_1_1 );

    /* Recreate the image */
    _canvas.draw_all( context );

    /* Draw the page to the PDF file */
    context.show_page();

    return( true );

  }

}

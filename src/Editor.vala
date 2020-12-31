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

public class Editor : Box {

  private CanvasToolbar _toolbar;
  private Canvas        _canvas;
  private string        _filename;

  /* Constructor */
  public Editor( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    /* Create the canvas */
    _canvas = new Canvas( win );
    _canvas.halign = Align.CENTER;

    /* Create the overlay that will hold the canvas so that we can add emoji support */
    var overlay = new Overlay();
    overlay.add( _canvas );

    var sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 600;
    sw.min_content_height = 400;
    sw.vscrollbar_policy  = PolicyType.AUTOMATIC;
    sw.hscrollbar_policy  = PolicyType.AUTOMATIC;
    sw.add( overlay );

    /* Create the toolbar */
    _toolbar = new CanvasToolbar( _canvas.items );
    _toolbar.halign = Align.CENTER;

    /* Pack the box */
    pack_start( _toolbar, false, true, 0 );
    pack_start( sw,       true,  true, 0 );

    show_all();

  }

  /* Opens the given image */
  public void open_image( string filename ) {
    _filename = filename;
    _canvas.open_image( filename );
  }

}



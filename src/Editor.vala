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

public class Editor : Box {

  private string         _filename;
  private ScrolledWindow _sw;

  public Canvas canvas { get; private set; }

  public signal void image_loaded();

  /* Constructor */
  public Editor( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    /* Create the canvas */
    canvas = new Canvas( win, this );
    canvas.halign = Align.CENTER;
    canvas.valign = Align.CENTER;
    canvas.image_loaded.connect(() => {
      image_loaded();
    });

    /* Create the overlay that will hold the canvas so that we can add emoji support */
    var overlay = new Overlay();
    overlay.border_width = 10;
    overlay.add( canvas );

    _sw = new ScrolledWindow( null, null );
    _sw.min_content_width  = 600;
    _sw.min_content_height = 400;
    _sw.vscrollbar_policy  = PolicyType.AUTOMATIC;
    _sw.hscrollbar_policy  = PolicyType.AUTOMATIC;
    _sw.add( overlay );

    /* Create the toolbar */
    var toolbar = new CanvasToolbar( canvas );
    toolbar.halign = Align.CENTER;
    canvas.image.crop_ended.connect(() => {
      toolbar.crop_ended();
    });

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.pack_start( toolbar, true, true );

    /* Pack the box */
    pack_start( box, false, true, 0 );
    pack_start( _sw, true,  true, 0 );

    show_all();

  }

  /* Opens the given image */
  public void open_image( string filename ) {
    _filename = filename;
    canvas.open_image( filename );
  }

  /* Pastes the given image pixbuf to the canvas */
  public void paste_image( Gdk.Pixbuf buf ) {
    canvas.paste_image( buf );
  }

  /* Pastes the given text to the canvas */
  public void paste_text( string txt ) {
    canvas.paste_text( txt );
  }

  /* Pastes the given text as canvas items */
  public void paste_items( string items ) {
    canvas.items.deserialize_for_paste( items );
  }

  /* Returns true if the image has been successfully set */
  public bool is_image_set() {
    return( canvas.is_surface_set() );
  }

  /* Returns the width and height of the overlay area of the canvas */
  public CanvasRect get_displayed_rect() {
    var x = (int)_sw.hadjustment.value;
    var y = (int)_sw.vadjustment.value;
    var w = (canvas.image.info.width  < _sw.get_allocated_width())  ? canvas.image.info.width  : _sw.get_allocated_width();
    var h = (canvas.image.info.height < _sw.get_allocated_height()) ? canvas.image.info.height : _sw.get_allocated_height();
    return( new CanvasRect.from_coords( x, y, w, h ) );
  }

}


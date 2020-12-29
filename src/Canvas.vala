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
using Gdk;
using Cairo;

public class Canvas : DrawingArea {

  private ImageSurface?  _surface = null;
  private IMMulticontext _im_context;

  public MainWindow win { get; private set; }

  /* Constructor */
  public Canvas( MainWindow win ) {

    this.win = win;

    this.draw.connect( on_draw );

    /* Make sure the above events are listened for */
    this.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.POINTER_MOTION_MASK |
      EventMask.KEY_PRESS_MASK |
      EventMask.SMOOTH_SCROLL_MASK |
      EventMask.STRUCTURE_MASK
    );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;

    /* Make sure that we us the IMMulticontext input method when editing text only */
    _im_context = new IMMulticontext();
    _im_context.set_client_window( this.get_window() );
    _im_context.set_use_preedit( false );
    _im_context.commit.connect( handle_im_commit );
    _im_context.retrieve_surrounding.connect( handle_im_retrieve_surrounding );
    _im_context.delete_surrounding.connect( handle_im_delete_surrounding );

  }

  /* Opens a new image and displays it in the drawing area */
  public bool open_image( string filename ) {

    try {
      var buf = new Pixbuf.from_file( filename );
      _surface = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 1, null );
      set_size_request( buf.width, buf.height );
      queue_draw();
    } catch( Error e ) {
      return( false );
    }

    return( true );

  }

  /* Called by the input method manager when the user has a string to commit */
  private void handle_im_commit( string str ) {
    // insert_user_text( str );
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_retrieve_surrounding() {
    /*
    if( is_node_editable() ) {
      retrieve_surrounding_in_text( selected.name );
      return( true );
    } else if( is_note_editable() ) {
      retrieve_surrounding_in_text( selected.note );
      return( true );
    }
    */
    return( false );
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_delete_surrounding( int offset, int nchars ) {
    /*
    if( is_node_editable() ) {
      delete_surrounding_in_text( selected.name, offset, nchars );
      return( true );
    } else if( is_note_editable() ) {
      delete_surrounding_in_text( selected.note, offset, nchars );
      return( true );
    }
    */
    return( false );
  }

  /* Draws the image */
  private void draw_image( Context ctx ) {
    if( _surface != null ) {
      ctx.set_source_surface( _surface, 0, 0 );
      ctx.paint();
    }
  }

  private void draw_items( Context ctx ) {

  }

  /* Draws all of the items in the canvas */
  private bool on_draw( Context ctx ) {
    draw_image( ctx );
    draw_items( ctx );
    return( false );
  }

}



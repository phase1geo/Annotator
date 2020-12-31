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

  public MainWindow  win         { get; private set; }
  public double      sfactor     { get; set; default = 1.0; }
  public CanvasItems items       { get; private set; }
  public UndoBuffer  undo_buffer { get; private set; }

  public signal void image_loaded();

  /* Constructor */
  public Canvas( MainWindow win ) {

    this.win = win;

    this.items       = new CanvasItems( this );
    this.undo_buffer = new UndoBuffer( this );

    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.button_release_event.connect( on_release );
    this.motion_notify_event.connect( on_motion );

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

  /* Returns true if the surface image has been set */
  public bool is_surface_set() {
    return( _surface != null );
  }

  /* Sets the cursor */
  public void set_cursor( CursorType? type = null ) {

    var win    = get_window();
    var cursor = win.get_cursor();

    if( type == null ) {
      win.set_cursor( null );
    } else if( (cursor == null) || (cursor.cursor_type != type) ) {
      win.set_cursor( new Cursor.for_display( get_display(), type ) );
    }

  }

  /* Sets the cursor from the given name */
  public void set_cursor_from_name( string name ) {
    var win    = get_window();
    win.set_cursor( new Cursor.from_name( get_display(), name ) );
  }

  /* Opens a new image and displays it in the drawing area */
  public bool open_image( string filename ) {

    try {
      var buf = new Pixbuf.from_file( filename );
      _surface = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 1, null );
      set_size_request( buf.width, buf.height );
      queue_draw();
      image_loaded();
    } catch( Error e ) {
      return( false );
    }

    return( true );

  }

  /* Pastes an image from the given pixbuf to the canvas */
  public void paste_image( Pixbuf buf ) {
    _surface = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 1, null );
    set_size_request( buf.width, buf.height );
    queue_draw();
    image_loaded();
  }

  /* Pastes a text from the given string to the canvas (only valid when editing a text item */
  public void paste_text( string txt ) {
    /* TBD */
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

  /* Returns the scaled value */
  private double scale_value( double value ) {
    return( value / scale_factor );
  }

  /* Handles a mouse cursor button press event */
  private bool on_press( EventButton e ) {

    var x = scale_value( e.x );
    var y = scale_value( e.y );

    if( _items.cursor_pressed( x, y ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Handles a mouse cursor motion event */
  private bool on_motion( EventMotion e ) {

    var x = scale_value( e.x );
    var y = scale_value( e.y );

    if( _items.cursor_moved( x, y ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Handles a mouse cursor button release event */
  private bool on_release( EventButton e ) {

    var x = scale_value( e.x );
    var y = scale_value( e.y );

    if( _items.cursor_released( x, y ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Draws the image */
  private void draw_image( Context ctx ) {
    if( _surface != null ) {
      ctx.set_source_surface( _surface, 0, 0 );
      ctx.paint();
    }
  }

  /* Draw all of the items */
  private void draw_items( Context ctx ) {
    items.draw( ctx );
  }

  /* Draws all of the items in the canvas */
  private bool on_draw( Context ctx ) {
    draw_image( ctx );
    draw_items( ctx );
    return( false );
  }

}



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

  private Pixbuf?        _buf     = null;
  private ImageSurface?  _surface = null;
  private IMMulticontext _im_context;

  public MainWindow     win         { get; private set; }
  public double         sfactor     { get; set; default = 1.0; }
  public CanvasImage    image       { get; private set; }
  public CanvasItems    items       { get; private set; }
  public UndoBuffer     undo_buffer { get; private set; }
  public UndoTextBuffer undo_text   { get; private set; }

  public signal void image_loaded();

  /* Constructor */
  public Canvas( MainWindow win ) {

    win = win;

    /* Create the canvas image */
    image = new CanvasImage( this );

    /* Create the canvas items */
    items       = new CanvasItems( this );
    items.text_item_edit_changed.connect( edit_mode_changed );

    /* Create the undo buffers */
    undo_buffer = new UndoBuffer( this );
    undo_text   = new UndoTextBuffer( this );

    this.draw.connect( on_draw );
    this.key_press_event.connect( on_keypress );
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
    var win   = get_window();
    win.set_cursor( new Cursor.from_name( get_display(), name ) );
  }

  /* Draws a blur in the given rectangle onto the provided context */
  public void draw_blur_rectangle( Cairo.Context ctx, CanvasRect rect, int blur_radius = 10 ) {

    var x       = (rect.x < 0) ? 0 : (int)rect.x;
    var y       = (rect.y < 0) ? 0 : (int)rect.y;
    var w       = ((rect.x + rect.width)  >= _buf.width)  ? (_buf.width  - (int)rect.x) : (int)rect.width;
    var h       = ((rect.y + rect.height) >= _buf.height) ? (_buf.height - (int)rect.y) : (int)rect.height;
    var sub     = new Pixbuf.subpixbuf( _buf, x, y, w, h );
    var surface = cairo_surface_create_from_pixbuf( sub, 1, null );
    var buffer  = new Granite.Drawing.BufferSurface.with_surface( w, h, surface );

    /* Copy the surface contents over */
    buffer.context.set_source_surface( surface, 0, 0 );
    buffer.context.paint();

    /* Perform the blur */
    buffer.exponential_blur( blur_radius );

    /* Draw the blurred pixbuf onto the context */
    ctx.set_source_surface( buffer.surface, x, y );
    ctx.paint();

  }

  /* Returns the RGBA color value that averages the colors in the given rectangle */
  public RGBA get_average_color( CanvasRect rect ) {

    var x     = (rect.x < 0) ? 0 : (int)rect.x;
    var y     = (rect.y < 0) ? 0 : (int)rect.y;
    var w     = ((rect.x + rect.width)  >= _buf.width)  ? (_buf.width  - (int)rect.x) : (int)rect.width;
    var h     = ((rect.y + rect.height) >= _buf.height) ? (_buf.height - (int)rect.y) : (int)rect.height;
    var sub   = new Pixbuf.subpixbuf( _buf, x, y, w, h );
    var color = Granite.Drawing.Utilities.average_color( sub );

    RGBA rgba = {color.R, color.G, color.B, color.A};
    return( rgba );

  }

  /* Opens a new image and displays it in the drawing area */
  public bool open_image( string filename ) {

    try {
      var buf = new Pixbuf.from_file( filename );
      image.set_image( buf );
      queue_draw();
      image_loaded();
      grab_focus();
    } catch( Error e ) {
      return( false );
    }

    return( true );

  }

  /* Pastes an image from the given pixbuf to the canvas */
  public void paste_image( Pixbuf buf ) {
    image.set_image( buf );
    queue_draw();
    image_loaded();
    grab_focus();
  }

  /* Pastes a text from the given string to the canvas (only valid when editing a text item */
  public void paste_text( string txt ) {
    if( items.in_edit_mode() ) {
      var item = items.get_active_text();
      item.insert( txt, undo_text );
      queue_draw();
      grab_focus();
    }
  }

  /* Called whenever the user changes the edit mode of an active text item */
  private void edit_mode_changed( CanvasItemText item ) {
    if( item.edit ) {
      update_im_cursor( item );
      _im_context.focus_in();
      undo_text.orig.copy( item );
      undo_text.ct = item;
    } else {
      _im_context.reset();
      _im_context.focus_out();
      undo_buffer.add_item( new UndoTextCommit( this, item, undo_text.orig ) );
      undo_text.ct = null;
    }
  }

  /* Updates the input method cursor location */
  private void update_im_cursor( CanvasItemText item ) {
    Gdk.Rectangle rect = {(int)item.bbox.x, (int)item.bbox.y, 0, (int)item.bbox.height};
    _im_context.set_cursor_location( rect );
  }

  /* Called by the input method manager when the user has a string to commit */
  private void handle_im_commit( string str ) {
    if( items.in_edit_mode() ) {
      var item = items.get_active_text();
      item.insert( str, undo_text );
      queue_draw();
    }
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_retrieve_surrounding() {
    if( items.in_edit_mode() ) {
      int cursor, selstart, selend;
      var item = items.get_active_text();
      var text = item.text.text;
      item.get_cursor_info( out cursor, out selstart, out selend );
      _im_context.set_surrounding( text, text.length, text.index_of_nth_char( cursor ) );
      return( true );
    }
    return( false );
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_delete_surrounding( int offset, int nchars ) {
    if( items.in_edit_mode() ) {
      int cursor, selstart, selend;
      var item = items.get_active_text();
      item.get_cursor_info( out cursor, out selstart, out selend );
      var startpos = cursor - offset;
      var endpos   = startpos + nchars;
      item.delete_range( startpos, endpos, undo_text );
      return( true );
    }
    return( false );
  }

  /* Returns the scaled value */
  private double scale_value( double value ) {
    return( value / scale_factor );
  }

  /* Handles keypress events */
  private bool on_keypress( EventKey e ) {

    /* If the character is printable, pass the value through the input method filter */
    if( e.str.get_char( 0 ).isprint() ) {
      _im_context.filter_keypress( e );

    /* Otherwise, allow the canvas item handler to deal with it immediately */
    } else if( items.key_pressed( e.keyval, e.state ) ) {
      _im_context.reset();
      queue_draw();
    }

    return( false );

  }

  /* Handles a mouse cursor button press event */
  private bool on_press( EventButton e ) {

    var x           = scale_value( e.x );
    var y           = scale_value( e.y );
    var press_count = (e.type == EventType.BUTTON_PRESS) ? 1 :
                      (e.type == EventType.DOUBLE_BUTTON_PRESS) ? 2 : 3;

    grab_focus();

    if( image.cropping ) {
      if( image.cursor_pressed( x, y, e.state, press_count ) ) {
        queue_draw();
      }
    } else if( items.cursor_pressed( x, y, e.state, press_count ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Handles a mouse cursor motion event */
  private bool on_motion( EventMotion e ) {

    var x = scale_value( e.x );
    var y = scale_value( e.y );

    if( image.cropping ) {
      if( image.cursor_moved( x, y, e.state ) ) {
        queue_draw();
      }
    } else if( items.cursor_moved( x, y, e.state ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Handles a mouse cursor button release event */
  private bool on_release( EventButton e ) {

    var x = scale_value( e.x );
    var y = scale_value( e.y );

    if( image.cropping ) {
      if( image.cursor_released( x, y, e.state ) ) {
        queue_draw();
      }
    } else if( items.cursor_released( x, y, e.state ) ) {
      queue_draw();
    }

    return( false );

  }

  /* Draws all of the items in the canvas */
  private bool on_draw( Context ctx ) {
    image.draw( ctx );
    items.draw( ctx );
    return( false );
  }

}



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
using Gdk;
using Cairo;

public class Canvas : DrawingArea {

  public const double zoom_max  = 4.0;
  public const double zoom_min  = 0.25;
  public const double zoom_step = 0.25;

  private ImageSurface?  _surface = null;
  private IMMulticontext _im_context;
  private double         _last_x = 0;
  private double         _last_y = 0;
  private ModifierType   _state;

  public MainWindow     win          { get; private set; }
  public Editor         editor       { get; private set; }
  public double         sfactor      { get; set; default = 1.0; }
  public CanvasImage    image        { get; private set; }
  public CanvasItems    items        { get; private set; }
  public UndoBuffer     undo_buffer  { get; private set; }
  public UndoTextBuffer undo_text    { get; private set; }
  public double         zoom_factor  { get; set; default = 1.0; }

  public signal void image_loaded();
  public signal void zoom_changed( double zoom_factor );

  /* Constructor */
  public Canvas( MainWindow win, Editor editor ) {

    this.win    = win;
    this.editor = editor;

    /* Create the canvas image */
    image = new CanvasImage( this );

    /* Create the canvas items */
    items = new CanvasItems( this );
    items.text_item_edit_changed.connect( edit_mode_changed );

    /* Create the undo buffers */
    undo_buffer = new UndoBuffer( this );
    undo_text   = new UndoTextBuffer( this );

    /* Make sure the drawing area can receive keyboard focus */
    can_focus = true;
    focusable = true;
    set_draw_func( on_draw );

    var key_controller = new EventControllerKey();
    var pri_btn_controller = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    var sec_btn_controller = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    var motion_controller = new EventControllerMotion();
    var focus_controller = new EventControllerFocus();

    add_controller( key_controller );
    add_controller( pri_btn_controller );
    add_controller( sec_btn_controller );
    add_controller( motion_controller );
    add_controller( focus_controller );

    key_controller.key_pressed.connect( on_keypress );
    key_controller.key_released.connect( on_keyrelease );
    key_controller.modifiers.connect( on_modifier_change );

    pri_btn_controller.pressed.connect( on_primary_press );
    pri_btn_controller.released.connect( on_primary_release );

    sec_btn_controller.pressed.connect( on_secondary_press );

    motion_controller.motion.connect( on_motion );

    focus_controller.enter.connect(() => {
      stdout.printf( "Canvas received focus, contains: %s, is: %s\n", focus_controller.contains_focus.to_string(), focus_controller.is_focus.to_string() );
    });
    focus_controller.leave.connect(() => {
      stdout.printf( "Canvas lost focus, contains: %s, is: %s\n", focus_controller.contains_focus.to_string(), focus_controller.is_focus.to_string() );
    });

    /* Make sure that we us the IMMulticontext input method when editing text only */
    /* TODO
    _im_context = new IMMulticontext();
    _im_context.set_client_window( this.get_window() );
    _im_context.set_use_preedit( false );
    _im_context.commit.connect( handle_im_commit );
    _im_context.retrieve_surrounding.connect( handle_im_retrieve_surrounding );
    _im_context.delete_surrounding.connect( handle_im_delete_surrounding );
    */

  }

  /* Returns true if the surface image has been set */
  public bool is_surface_set() {
    return( _surface != null );
  }

  /* Sets the cursor from the given name */
  public void set_cursor_from_name( string name ) {
    var cursor = new Cursor.from_name( name, null );
    set_cursor( cursor );
  }

  /* Opens a new image and displays it in the drawing area */
  public bool open_image( string filename ) {

    try {
      var buf = new Pixbuf.from_file( filename );
      image.set_image( buf );
      CanvasItemSequence.reset();
      queue_draw();
      image_loaded();
      grab_focus();
    } catch( Error e ) {
      return( false );
    }

    return( true );

  }

  /* Undoes the last change */
  public void do_undo() {
    if( items.in_edit_mode() && undo_text.undoable() ) {
      undo_text.undo();
    } else {
      undo_buffer.undo();
    }
    grab_focus();
  }

  /* Redoes the last change */
  public void do_redo() {
    if( items.in_edit_mode() ) {
      undo_text.redo();
    } else {
      undo_buffer.redo();
    }
    grab_focus();
  }

  /* Copies the selected item to the clipboard */
  public void do_copy() {
    var item = items.get_selected_item();
    if( item != null ) {
      items.do_copy( item );
    }
  }

  /* Cuts the selected item to the clipboard */
  public void do_cut() {
    var item = items.get_selected_item();
    if( item != null ) {
      items.do_cut( item );
      queue_draw();
    }
  }

  /* Performs actual paste operation */
  private void do_paste( Pixbuf buf ) {
    image.set_image( buf );
    CanvasItemSequence.reset();
    queue_draw();
    image_loaded();
    grab_focus();
  }

  /* Returns true if the image paste operation should be cancelled */
  private void confirm_paste( Pixbuf buf ) {

    if( items.items_exist() ) {

      var dialog = new Granite.MessageDialog.with_image_from_icon_name(
        _( "Annotate new image?" ),
        _( "Pasting a new image to annotate will destroy the current annotation." ),
        "dialog-warning",
        ButtonsType.YES_NO
      );

      dialog.set_transient_for( win );
      dialog.set_default_response( ResponseType.CANCEL );
      dialog.set_title( "" );

      dialog.response.connect((id) => {
        if( id == ResponseType.ACCEPT ) {
          do_paste( buf );
        }
        dialog.destroy();
      });

      dialog.show();

    }

  }

  /* Pastes an image from the given pixbuf to the canvas */
  public void paste_image( Pixbuf buf, bool confirm ) {
    if( !confirm ) {
      do_paste( buf );
    } else {
      confirm_paste( buf );
    }
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

  /* Returns the scaled x-value */
  private double scale_x( double value ) {
    return( value / (image.width_scale * zoom_factor) );
  }

  /* Returns the scaled y-value */
  private double scale_y( double value ) {
    return( value / (image.height_scale * zoom_factor) );
  }

  /* Handles the emoji insertion process for the given text item */
  public void insert_emoji() {
    if( items.in_edit_mode() ) {
      /* TODO - This should be possible but research will be required
      var overlay = (Overlay)get_parent();
      var entry   = new Entry();
      var text    = items.get_active_text();
      int x, ytop, ybot;
      text.get_cursor_pos( out x, out ytop, out ybot );
      entry.margin_start = x;
      entry.margin_top   = ytop + ((ybot - ytop) / 2);
      entry.changed.connect(() => {
        text.insert( entry.text, undo_text );
        queue_draw();
        entry.unparent();
        grab_focus();
      });
      overlay.add_overlay( entry );
      var emoji_chooser = new EmojiChooer();
      emoji_chooser.set_parent( entry );
      emoji_chooser.emoji_picked((str) => {
        entry.kk
      });
      emoji_chooser.popup();
      */
    }
  }

  /* Handles keypress events */
  private bool on_keypress( uint keyval, uint keycode, ModifierType state ) {

    var c = (unichar)keyval;

    stdout.printf( "In on_keypress, keyval: %u\n", keyval );

    /* If the character is printable, pass the value through the input method filter */
    if( items.in_edit_mode() && c.isprint() && false ) {
      stdout.printf( "HERE A\n" );
      return( false );
      // TODO - Not sure how to deal with IM contexts
      // _im_context.filter_keypress( e );

    /* If we are cropping the image, pass key presses to the image */
    } else if( image.cropping ) {
      stdout.printf( "HERE B\n" );
      if( image.key_pressed( keyval, keycode, state ) ) {
        queue_draw();
      }

    /* Otherwise, allow the canvas item handler to deal with it immediately */
    } else if( items.key_pressed( keyval, keycode, state ) ) {
      _im_context.reset();
      queue_draw();
    }

    return( true );

  }

  /* Handles keyrelease events */
  private void on_keyrelease( uint keyval, uint keycode, ModifierType state ) {

    if( !image.cropping ) {
      if( items.key_released( keyval, state ) ) {
        _im_context.reset();
        queue_draw();
      }
    }

  }

  /* Called whenever the modifier state changes */
  private bool on_modifier_change( ModifierType state ) {
    _state = state;
    return( true );
  }

  /* Displays the contextual menu (if any) for the currently selected item */
  public void show_contextual_menu() {
    if( !image.cropping ) {
      items.show_contextual_menu( _last_x, _last_y );
    }
  }

  /* Handles a primary mouse button press event */
  private void on_primary_press( int n_press, double ex, double ey ) {

    var x = scale_x( ex );
    var y = scale_y( ey );

    var retval = grab_focus();
    stdout.printf( "Grabbing focus, retval: %s, sensitive: %s, can_focus: %s, focusable: %s\n", retval.to_string(), sensitive.to_string(), can_focus.to_string(), focusable.to_string() );
    if( image.cropping ) {
      if( image.cursor_pressed( x, y, _state, n_press ) ) {
        queue_draw();
      }
    } else if( items.cursor_pressed( x, y, _state, n_press ) ) {
      queue_draw();
    }

  }

  /* Handles a secondary mouse button press event */
  private void on_secondary_press( int n_press, double ex, double ey ) {
    show_contextual_menu();
  }

  /* Handles a mouse cursor motion event */
  private void on_motion( double ex, double ey ) {

    var x = scale_x( ex );
    var y = scale_y( ey );

    _last_x = x;
    _last_y = y;

    if( image.cropping ) {
      if( image.cursor_moved( x, y, _state ) ) {
        queue_draw();
      }
    } else if( items.cursor_moved( x, y, _state ) ) {
      queue_draw();
    }

  }

  /* Handles a mouse cursor button release event */
  private void on_primary_release( int n_press, double ex, double ey ) {

    var x = scale_x( ex );
    var y = scale_y( ey );

    if( image.cropping ) {
      if( image.cursor_released( x, y, _state ) ) {
        queue_draw();
      }
    } else if( items.cursor_released( x, y, _state ) ) {
      queue_draw();
    }

  }

  /****************************************************************************/
  //  ZOOM CONTROLS
  /****************************************************************************/

  /* Sets the zoom level to a specific value */
  public void zoom_set( double value ) {
    zoom_factor = value;
    queue_draw();
    zoom_adjust();
    zoom_changed( zoom_factor );
  }

  /* Zooms the canvas in by the zoom_step */
  public void zoom_in() {
    zoom_set( ((zoom_factor + zoom_step) > zoom_max) ? zoom_max : (zoom_factor + zoom_step) );
  }

  /* Zooms the canvas out by the zoom_step */
  public void zoom_out() {
    zoom_set( ((zoom_factor - zoom_step) < zoom_min) ? zoom_min : (zoom_factor - zoom_step) );
  }

  /* Zooms the image to the actual size */
  public void zoom_actual() {
    zoom_set( 1.0 );
  }

  /* Zooms the image to fit into the window */
  public void zoom_fit() {

    int win_width, win_height;
    editor.get_win_size( out win_width, out win_height );

    var img_width  = (double)image.info.width;
    var img_height = (double)image.info.height;
    var dw         = Math.fabs( win_width  - img_width );
    var dh         = Math.fabs( win_height - img_height );

    zoom_set( (dw < dh) ? (win_height / img_height) : (win_width / img_width) );

  }

  private void zoom_adjust() {
    set_size_request( (int)(image.info.width * zoom_factor), (int)(image.info.height * zoom_factor) );
  }

  /* Performs canvas resizing, if the user modified the margin, we will need to move the items around */
  public void resize( CanvasImageInfo old_info, CanvasImageInfo new_info ) {

    /* Calculate the scaling factors */
    var old_xscale = 1 / (old_info.pixbuf_rect.width  / image.pixbuf.width);
    var old_yscale = 1 / (old_info.pixbuf_rect.height / image.pixbuf.height);
    var new_xscale = 1 / (new_info.pixbuf_rect.width  / image.pixbuf.width);
    var new_yscale = 1 / (new_info.pixbuf_rect.height / image.pixbuf.height);

    /* Move all of the canvas Items according to the difference in margin */
    var diffx = (new_info.left_margin() * new_xscale) - (old_info.left_margin() * old_xscale);
    var diffy = (new_info.top_margin()  * new_yscale) - (old_info.top_margin()  * old_yscale);

    /* Adjust all of the elements if the image moved horizontally or vertically */
    if( (diffx != 0) || (diffy != 0) ) {
      items.adjust_items( diffx, diffy, false );
    }

    /* Resize the canvas itself */
    set_size_request( new_info.width, new_info.height );

  }

  /****************************************************************************/
  //  DRAWING FUNCTIONS
  /****************************************************************************/

  /* Draws all of the items in the canvas with the given zoom factor */
  public void draw_all( Context ctx ) {
    image.draw( ctx );
    items.draw( ctx );
  }

  /* Draws all of the items in the canvas */
  private void on_draw( DrawingArea da, Context ctx, int width, int height ) {
    ctx.scale( zoom_factor, zoom_factor );
    draw_all( ctx );
  }

}



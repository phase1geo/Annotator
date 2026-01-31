/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Annotator)
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

public enum PickMode {
  NONE,
  CLIPBOARD,
  COLOR;

  //-------------------------------------------------------------
  // Returns true if enabled
  public bool enabled() {
    return( this != NONE );
  }

}

public class CanvasImage {

  private const int selector_size   = 10;
  private const int crop_selectors  = 8;  // TODO - Set to 9 to enable rotation
  private const int pick_size       = 5;  // Specifies the width/height of the color picker box in pixels (should be an odd number)
  private const int pick_pixel_size = 16; // Specifies the width/height of each pixel box in the color picker (should be an even number)

  private double selector_width {
    get {
      return( selector_size / width_scale );
    }
  }
  private double selector_height {
    get {
      return( selector_size / height_scale );
    }
  }
  private Cursor[] _sel_cursors = new Cursor[9];

  private Canvas        _canvas;
  private Pixbuf?       _buf             = null;  // Currently displayed pixbuf
  private int           _crop_index      = -2;
  private double        _last_x          = 0;
  private double        _last_y          = 0;
  private double        _angle           = 0;
  private bool          _control_set     = false;
  private PickMode      _pick_mode       = PickMode.NONE;
  private RGBA          _pick_color      = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
  private int           _pick_adjust_row = (pick_size / 2);
  private int           _pick_adjust_col = (pick_size / 2);
  private int[]         _pick_offset     = new int[pick_size];
  private double        _pick_x          = 0.0;
  private double        _pick_y          = 0.0;

  public Pixbuf?          pixbuf        { get; private set; default = null; }  // Original pixbuf of image
  public bool             cropping      { get; private set; default = false; }
  public CanvasRect       crop_rect     { get; private set; default = new CanvasRect(); }
  public CanvasImageInfo? info          { get; private set; default = null; }
  public double           width_scale   { get; private set; default = 1.0; }
  public double           height_scale  { get; private set; default = 1.0; }
  public Exports          exports       { get; private set; }
  public bool             picking       {
    get {
      return( _pick_mode.enabled() );
    }
  }

  public signal void crop_started();
  public signal void crop_ended();
  public signal void image_changed();
  public signal void color_picked( RGBA color );

  //-------------------------------------------------------------
  // Constructor
  public CanvasImage( Canvas canvas ) {

    _canvas = canvas;
    exports = new Exports( canvas );

    _sel_cursors[0] = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[1] = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[3] = new Cursor.from_name( "se-resize", null );
    _sel_cursors[4] = new Cursor.from_name( "n-resize", null );
    _sel_cursors[5] = new Cursor.from_name( "s-resize", null );
    _sel_cursors[6] = new Cursor.from_name( "w-resize", null );
    _sel_cursors[7] = new Cursor.from_name( "e-resize", null );
    _sel_cursors[8] = new Cursor.from_name( "col-resize", null );

    for( int i=0; i<pick_size; i++ ) {
      _pick_offset[i] = ((pick_size * pick_pixel_size) / 2) - (i * pick_pixel_size);
    }

  }

  //-------------------------------------------------------------
  // Returns true if the surface image has been set.
  public bool is_surface_set() {
    return( _buf != null );
  }

  //-------------------------------------------------------------
  // Returns a surface which contains the given rectangle area of the base image.
  public Pixbuf get_pixbuf_for_rect( CanvasRect rect ) {
    var buf_rect = new CanvasRect.from_coords( 0, 0, _buf.width, _buf.height );
    rect.intersection( rect, buf_rect );
    var sub = new Pixbuf.subpixbuf( _buf, (int)rect.x, (int)rect.y, (int)rect.width, (int)rect.height );
    return( sub );
  }

  //-------------------------------------------------------------
  // Changes the stored image to the given pixbuf and performs other related tasks.
  public void change_image( Pixbuf buf, string? undo_name = _( "change image" ) ) {

    if( cropping ) {
      cancel_crop();
    }

    if( (undo_name != null) && (_buf != null) ) {
      _canvas.undo_buffer.add_item( new UndoImageChange( undo_name, _buf, buf ) );
    }

    pixbuf = buf.copy();
    _buf   = buf.copy();
    _canvas.set_size_request( _buf.width, _buf.height );
    _angle = 0;

    // Create the image information
    info = new CanvasImageInfo( _buf );

    // Indicate that the image changed to anyone listening
    image_changed();

  }

  //-------------------------------------------------------------
  // Pastes an image from the given pixbuf to the canvas.
  public void set_image( Pixbuf buf, string? undo_name = _( "change image" ) ) {

    var items_removed = _canvas.items.items_exist();

    // Delete the canvas items
    _canvas.items.clear();

    // Update the image
    change_image( buf, undo_name );

    // If we removed items, clear the undo buffer
    if( items_removed ) {
      _canvas.undo_buffer.clear();
    }

  }

  //-------------------------------------------------------------
  // Resizes the current image.
  public void resize_image() {

    var dialog = new Resizer( _canvas, info );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var old_info = new CanvasImageInfo.from_info( info );
        var new_info = dialog.get_image_info();
        _canvas.undo_buffer.add_item( new UndoImageResize( old_info, new_info ) );
        do_resize( old_info, new_info );
      }
      dialog.close();
    });

    dialog.show();

  }

  //-------------------------------------------------------------
  // This is the function that performs the actual resize.
  public void do_resize( CanvasImageInfo old_info, CanvasImageInfo new_info ) {

    // Copy the new info into our info
    info.copy( new_info );

    // Create a new buffer with the added margin
    var sbuf = pixbuf.scale_simple( (int)info.pixbuf_rect.width, (int)info.pixbuf_rect.height, InterpType.BILINEAR );
    _buf = new Pixbuf( pixbuf.colorspace, pixbuf.has_alpha, pixbuf.bits_per_sample, info.width, info.height );
    _buf.fill( (uint32)0xffffffff );
    sbuf.copy_area( 0, 0, (int)info.pixbuf_rect.width, (int)info.pixbuf_rect.height, _buf, (int)info.pixbuf_rect.x, (int)info.pixbuf_rect.y );

    // Calculate the scaling factors
    width_scale  = info.pixbuf_rect.width  / pixbuf.width;
    height_scale = info.pixbuf_rect.height / pixbuf.height;

    // Resize the canvas
    _canvas.resize( old_info, new_info );

  }

  //-------------------------------------------------------------
  // KEY EVENT HANDLER
  //-------------------------------------------------------------

  public void focus_leave() {
    _control_set = false;
  }

  //-------------------------------------------------------------
  // Handles a keypress event when cropping is enabled.
  public bool key_pressed( uint keyval, uint keycode, ModifierType state ) {

    // Handle a press of the control key
    if( (keyval == Key.Control_L) || (keyval == Key.Control_R) ) {
      _control_set = true;
      if( _pick_mode.enabled() ) {
        _pick_x = _last_x;
        _pick_y = _last_y;
        return( true );
      }
      return( false );
    }

    if( _pick_mode.enabled() ) {

      switch( keyval ) {
        case Key.Return :
          return( complete_pick_mode( false ) );
        case Key.Escape :
          return( complete_pick_mode( true ) );
        case Key.Right :
          if( _pick_adjust_row < (pick_size - 1) ) {
            _pick_adjust_row++;
            return( true );
          }
          break;
        case Key.Left :
          if( _pick_adjust_row > 0 ) {
            _pick_adjust_row--;
            return( true );
          }
          break;
        case Key.Up :
          if( _pick_adjust_col > 0 ) {
            _pick_adjust_col--;
            return( true );
          }
          break;
        case Key.Down :
          if( _pick_adjust_col < (pick_size - 1) ) {
            _pick_adjust_col++;
            return( true );
          }
          break;
      }

    } else {

      switch( keyval ) {
        case Key.Return :
          return( end_crop() );
        case Key.Escape :
          return( cancel_crop() );
        case Key.Right :
          if( ((int)_angle + 1) < 180 ) {
            var box = new CanvasRect.from_rect( crop_rect );
            _angle += 1;
            adjust_box_on_angle( ref box );
            _canvas.queue_draw();
          }
          break;
        case Key.Left :
          if( ((int)_angle - 1) > 0 ) {
            var box = new CanvasRect.from_rect( crop_rect );
            _angle -= 1;
            adjust_box_on_angle( ref box );
            _canvas.queue_draw();
          }
          break;
      }

    }

    return( false );

  }

  //-------------------------------------------------------------
  // Handles a key release event when cropping is enabled.
  public bool key_released( uint keyval, uint keycode, ModifierType state ) {
    if( (keyval == Key.Control_L) || (keyval == Key.Control_R) ) {
      _control_set = false;
    }
    return( false );
  }

  //-------------------------------------------------------------
  // MOUSE EVENT HANDLER
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Handles a cursor press event.
  public bool cursor_pressed( double x, double y, int press_count ) {

    var rect = new CanvasRect();

    _last_x     = x;
    _last_y     = y;
    _crop_index = -2;

    if( _pick_mode.enabled() ) {

    } else if( cropping ) {
      for( int i=0; i<crop_selectors; i++ ) {
        selector_bbox( i, rect );
        if( rect.contains( x, y ) ) {
          _crop_index = i;
          return( true );
        }
      }
      if( crop_rect.contains( x, y ) ) {
        _crop_index = -1;
        _canvas.set_cursor_from_name( "grabbing" );
      } else {
        cancel_crop();
      }
    }

    return( false );

  }

  private void adjust_box_on_angle( ref CanvasRect box ) {

    var new_info = new CanvasImageInfo.with_rotation( _buf.width, _buf.height, _angle );

    _canvas.resize( info, new_info );

    info.copy( new_info );

  }

  //-------------------------------------------------------------
  // Returns true if the current cursor lies within a color picker
  // pixel box.  Sets the pick_adjust_row/col to the current values.
  private bool check_in_pick_box() {

    var size   = (pick_size * pick_pixel_size);
    var pick_x = _pick_x - _pick_offset[0];
    var pick_y = _pick_y - _pick_offset[0];

    if( (pick_x <= _last_x) && (_last_x < (pick_x + size)) && (pick_y <= _last_y) && (_last_y < (pick_y + size)) ) {
      _pick_adjust_row = (int)((_last_x - pick_x) / pick_pixel_size);
      _pick_adjust_col = (int)((_last_y - pick_y) / pick_pixel_size);
      return( true );
    }

    return( false );

  }
  
  //-------------------------------------------------------------
  // Handles a cursor motion event.
  public bool cursor_moved( double x, double y ) {

    var diffx = x - _last_x;
    var diffy = y - _last_y;
    var box   = new CanvasRect.from_rect( crop_rect );
    int angle = 0;

    _last_x = x;
    _last_y = y;

    // If we are picking a color, queue the draw
    if( _pick_mode.enabled() ) {
      return( !_control_set || check_in_pick_box() );
    }

    // If we clicked into the crop rectangle, move the rectangle
    if( _crop_index == -1 ) {
      box.x += diffx;
      box.y += diffy;
      if( (box.x >= 0) &&
          (box.y >= 0) &&
          ((box.x + box.width)  <= (info.width  / width_scale)) &&
          ((box.y + box.height) <= (info.height / height_scale)) ) {
        crop_rect.copy( box );
        return( true );
      }

    // If we are dragging a selector box, handle the move and resize
    } else if( _crop_index >= 0 ) {
      switch( _crop_index ) {
        case 0  :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
        case 1  :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
        case 2  :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
        case 3  :                                    box.width += diffx;  box.height += diffy;  break;
        case 4  :                   box.y += diffy;                       box.height -= diffy;  break;
        case 5  :                                                         box.height += diffy;  break;
        case 6  :  box.x += diffx;                   box.width -= diffx;                        break;
        case 7  :                                    box.width += diffx;                        break;
        case 8  :
          angle = (int)(x - (info.width / 2));
          if( !_control_set || ((angle % 15) == 0) || (angle < -180) || (angle > 180) ) {
            _angle = (angle < -180) ? -180 :
                     (angle >  180) ?  180 : angle;
            adjust_box_on_angle( ref box );
          } else {
            return( false );
          }
          break;
        default :  assert_not_reached();
      }
      if( (box.x >= 0) &&
          (box.y >= 0) &&
          (box.width  >= (selector_width  * 3)) &&
          (box.height >= (selector_height * 3)) &&
          ((box.x + box.width)  <= (info.width  / width_scale)) &&
          ((box.y + box.height) <= (info.height / height_scale)) ) {
        crop_rect.copy( box );
        return( true );
      }

    // If we are hovering over a crop selector, change the cursor
    } else {
      var rect = new CanvasRect();
      for( int i=0; i<crop_selectors; i++ ) {
        selector_bbox( i, rect );
        if( rect.contains( x, y ) ) {
          _canvas.set_cursor( _sel_cursors[i] );
          return( false );
        }
      }
      _canvas.set_cursor( null );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // If we are in color picking mode, finish it.
  private bool complete_pick_mode( bool cancel ) {

    // Handle the pick mode, if set and we are not cancelling
    if( !cancel ) {
      switch( _pick_mode ) {
        case PickMode.CLIPBOARD : { 
            var color_str = Utils.color_to_string( _pick_color );
            AnnotatorClipboard.copy_text( color_str );
            _canvas.win.notification( _( "Color copied to clipboard" ), color_str );
            break;
          }
        case PickMode.COLOR :
          color_picked( _pick_color );
          break;
        default :  return( false );
      }
    }

    _pick_mode = PickMode.NONE;

    return( true );

  }

  //-------------------------------------------------------------
  // Handles a cursor release event.
  public bool cursor_released( double x, double y ) {

    _crop_index = -2;
    _canvas.set_cursor( null );

    return( complete_pick_mode( false ) );

  }

  //-------------------------------------------------------------
  // CROP HANDLING CODE
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Start the cropping function.
  public void start_crop() {
    int width, height;
    cropping = true;
    // crop_rect.copy_coords( 0, 0, (width / width_scale), (height / height_scale) );
    crop_rect.copy_coords( 0, 0, info.width, info.height );
    crop_started();
  }

  //-------------------------------------------------------------
  // Cancels the crop operation.
  public bool cancel_crop() {
    cropping = false;
    _canvas.queue_draw();
    crop_ended();
    return( true );
  }

  //-------------------------------------------------------------
  // Completes the cropping operation.
  public bool end_crop() {
    cropping = false;
    var buf = new Pixbuf.subpixbuf( _buf, (int)crop_rect.x, (int)crop_rect.y, (int)crop_rect.width, (int)crop_rect.height );
    change_image( buf, _( "image crop" ) );
    _canvas.items.adjust_items( (0 - crop_rect.x), (0 - crop_rect.y), false );
    _canvas.queue_draw();
    crop_ended();
    return( true );
  }

  //-------------------------------------------------------------
  // COLOR PICKER
  //-------------------------------------------------------------

  public void pick_color( bool to_clipboard ) {

    _pick_mode = to_clipboard ? PickMode.CLIPBOARD : PickMode.COLOR;

    // Select the middle-most row and column
    _pick_adjust_row = (pick_size / 2);
    _pick_adjust_col = (pick_size / 2);

    // Make sure that the canvas has the keyboard focus to handle keypresses
    _canvas.grab_focus();

  }

  //-------------------------------------------------------------
  // EXPORTING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Make sure that everything is cleared from the image.
  private void clean_image() {
    cropping = false;
    _canvas.items.clear_selection();
    _canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Exports to the given image type.
  public void export_image( string type, string filename ) {
    clean_image();
    var export = exports.get_by_name( type );
    export.export( filename, _buf );
  }

  //-------------------------------------------------------------
  // Exports the image to the clipboard.
  public void export_clipboard() {
    clean_image();
    exports.clipboard.export( _buf );
  }

  //-------------------------------------------------------------
  // Exports the image to the printer.
  public void export_print() {
    clean_image();
    exports.printer.export( _buf );
  }

  //-------------------------------------------------------------
  // SAVE/LOAD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Saves the contents of this canvas image to XML format.
  public Xml.Node* save( string image_dir, int compression ) {

    Xml.Node* node    = new Xml.Node( null, "image" );
    string[]  options = { "compression" };
    string[]  values  = { compression.to_string() };
    var       fname   = GLib.Path.build_filename( image_dir, "background.png" );

    try {
      _buf.savev( fname, "png", options, values );
      node->set_prop( "filename", "background.png" );
    } catch( GLib.Error e ) {
      critical( e.message );
    }

    node->set_prop( "angle", _angle.to_string() );

    node->add_child( info.save() );

    return( node );

  }

  //-------------------------------------------------------------
  // Load the contents of this canvas image from XML format.
  public bool load( Xml.Node* node, string image_dir ) {

    var loaded = false;

    var fname = node->get_prop( "filename" );
    if( fname != null ) {
      loaded = _canvas.editor.open_image( GLib.Path.build_filename( image_dir, fname ) ); 
    }

    var a = node->get_prop( "angle" );
    if( a != null ) {
      _angle = double.parse( a );
      // TBD - We will probably want to handle the angle change in the canvas.
    }

    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "image-info") ) {
        if( info == null ) {
          info = new CanvasImageInfo.from_xml( it );
        }
        var old_info = new CanvasImageInfo.from_info( info );
        var new_info = new CanvasImageInfo.from_xml( it );
        do_resize( old_info, new_info );
      }
    }

    return( loaded );

  }

  //-------------------------------------------------------------
  // DRAWING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Calculates the box for the given selector.
  private void selector_bbox( int index, CanvasRect rect ) {

    switch( index ) {
      case 0 :  // UL
      case 1 :  // UR
      case 2 :  // LL
      case 3 :  // LR
        rect.x = ((index & 1) == 0) ? crop_rect.x1() : (crop_rect.x2() - selector_size);
        rect.y = ((index & 2) == 0) ? crop_rect.y1() : (crop_rect.y2() - selector_size);
        break;
      case 4 :  // TOP
      case 5 :  // BOTTOM
        rect.x = crop_rect.mid_x() - (selector_size / 2);
        rect.y = (index == 4) ? crop_rect.y1() : (crop_rect.y2() - selector_size);
        break;
      case 6 :  // LEFT
      case 7 :  // RIGHT
        rect.x = (index == 6) ? crop_rect.x1() : (crop_rect.x2() - selector_size);
        rect.y = crop_rect.mid_y() - (selector_size / 2);
        break;
      case 8 :  // ROTATE
        rect.x = ((info.width / 2) - (selector_size / 2)) + (int)_angle;
        rect.y = 20;
        break;
    }

    rect.width  = selector_size;
    rect.height = selector_size;

  }

  //-------------------------------------------------------------
  // Draw the image being annotated.
  private void draw_image( Context ctx ) {

    cairo_set_source_pixbuf( ctx, _buf, info.pixbuf_rect.x, info.pixbuf_rect.y );
    ctx.paint();

  }

  //-------------------------------------------------------------
  // Draws the drop_outline.
  private void draw_crop_outline( Context ctx ) {

    var black = Utils.color_from_string( "black" );

    Utils.set_context_color_with_alpha( ctx, black, 0.5 );

    ctx.rectangle( crop_rect.x1(), crop_rect.y1(), crop_rect.width, crop_rect.height );
    ctx.stroke();

    ctx.rectangle( 0, 0, crop_rect.x1(), info.height );
    ctx.fill();

    ctx.rectangle( crop_rect.x1(), 0, crop_rect.width, crop_rect.y1() );
    ctx.fill();

    ctx.rectangle( crop_rect.x1(), crop_rect.y2(), crop_rect.width, (info.height - crop_rect.y2()) );
    ctx.fill();

    ctx.rectangle( crop_rect.x2(), 0, (info.width - crop_rect.x2()), info.height );
    ctx.fill();

  }

  //-------------------------------------------------------------
  // Draws the thirds dividers when cropping.
  private void draw_crop_dividers( Context ctx ) {

    var third_width  = crop_rect.width  / 3;
    var third_height = crop_rect.height / 3;
    var black = Utils.color_from_string( "black" );

    Utils.set_context_color_with_alpha( ctx, black, 0.5 );
    ctx.set_line_width( 1 );

    // Draw vertical lines
    ctx.move_to( (crop_rect.x1() + third_width), crop_rect.y1() );
    ctx.line_to( (crop_rect.x1() + third_width), crop_rect.y2() );
    ctx.stroke();

    ctx.move_to( (crop_rect.x2() - third_width), crop_rect.y1() );
    ctx.line_to( (crop_rect.x2() - third_width), crop_rect.y2() );
    ctx.stroke();

    // Draw horizontal lines
    ctx.move_to( crop_rect.x1(), (crop_rect.y1() + third_height) );
    ctx.line_to( crop_rect.x2(), (crop_rect.y1() + third_height) );
    ctx.stroke();

    ctx.move_to( crop_rect.x1(), (crop_rect.y2() - third_height) );
    ctx.line_to( crop_rect.x2(), (crop_rect.y2() - third_height) );
    ctx.stroke();

  }

  //-------------------------------------------------------------
  // Draws the cropping selectors.
  private void draw_crop_selectors( Context ctx ) {

    var blue   = Utils.color_from_string( "light blue" );
    var black  = Utils.color_from_string( "black" );
    var rect   = new CanvasRect();

    for( int i=0; i<8; i++ ) {

      selector_bbox( i, rect );

      Utils.set_context_color( ctx, blue );
      ctx.rectangle( rect.x, rect.y, rect.width, rect.height );
      ctx.fill_preserve();

      Utils.set_context_color( ctx, black );
      ctx.set_line_width( 1 );
      ctx.stroke();

    }

  }

  //-------------------------------------------------------------
  // Draws the rotation selector.
  private void draw_rotate_selector( Context ctx ) {

    var yellow = Utils.color_from_string( "yellow" );
    var black  = Utils.color_from_string( "black" );
    var rect   = new CanvasRect();

    selector_bbox( 8, rect );

    Utils.set_context_color( ctx, yellow );
    ctx.rectangle( rect.x, rect.y, rect.width, rect.height );
    ctx.fill_preserve();

    Utils.set_context_color( ctx, black );
    ctx.set_line_width( 1 );
    ctx.stroke();

  }

  //-------------------------------------------------------------
  // Returns the color value at the given pixel location within the
  // image buffer.
  private RGBA get_color_at( Pixbuf buf, int x, int y ) {

    var  start = (y * buf.rowstride) + (x * buf.n_channels);
    RGBA color = { (float)(buf.get_pixels()[start+0] / 255.0),  // red
                   (float)(buf.get_pixels()[start+1] / 255.0),  // green
                   (float)(buf.get_pixels()[start+2] / 255.0),  // green
                   (float)1.0
    };

    return( color );

  }

  //-------------------------------------------------------------
  // Draws the color picker on the canvas.
  public void draw_pick_mode( Context ctx ) {

    if( _pick_mode.enabled() ) {

      var pick_x = _control_set ? _pick_x : _last_x;
      var pick_y = _control_set ? _pick_y : _last_y;
      var mid    = (pick_size / 2);

      // If we are too close to the border, just return
      if( (pick_x < mid) || (pick_y < mid) || ((pick_x + mid) >= _buf.width) || ((pick_y + mid) >= _buf.height) ) {
        return;
      }

      // Get the color at the last motion location
      var buf    = new Pixbuf.subpixbuf( _buf, (int)(pick_x - mid), (int)(pick_y - mid), pick_size, pick_size );
      var black  = Utils.color_from_string( "black" );
      var size   = pick_size * pick_pixel_size;
      var box_offset = 20;
      var no_change  = size + (box_offset * 2);
      var box_x  = (pick_x < ((_buf.width  / 2) - (no_change / 2))) ? (pick_x + box_offset) :
                   (pick_x > ((_buf.width  / 2) + (no_change / 2))) ? (pick_x - (box_offset + size)) :
                   (_buf.width / 2) - (size / 2);
      var box_y  = (pick_y < ((_buf.height / 2) - (no_change / 2))) ? (pick_y + box_offset) :
                   (pick_y > ((_buf.height / 2) + (no_change / 2))) ? (pick_y - (box_offset + size)) :
                   (_buf.height / 2) - (size / 2);

      Utils.set_context_color( ctx, black );
      ctx.rectangle( (box_x - 1), (box_y - 1), (size + 2), (size + 2) );
      ctx.fill();

      for( int i=0; i<(pick_size * pick_size); i++ ) {

        var x     = i % pick_size;
        var y     = i / pick_size;
        var color = get_color_at( buf, x, y );

        Utils.set_context_color( ctx, color );
        ctx.rectangle( (box_x + (x * pick_pixel_size)), (box_y + (y * pick_pixel_size)), pick_pixel_size, pick_pixel_size );
        ctx.fill();

      }

      // Get the pixel color
      _pick_color = get_color_at( buf, _pick_adjust_row, _pick_adjust_col );

      // Draw a border around the selected color pixel box
      Utils.set_context_color( ctx, Granite.contrasting_foreground_color( _pick_color ) );
      ctx.set_line_width( 2 );
      ctx.rectangle( (box_x + (_pick_adjust_row * pick_pixel_size)), (box_y + (_pick_adjust_col * pick_pixel_size)), pick_pixel_size, pick_pixel_size );
      ctx.stroke();

    }

  }

  //-------------------------------------------------------------
  // Draw the cropping area if we are in that mode.
  private void draw_cropping( Context ctx ) {
    if( !cropping ) return;
    draw_crop_outline( ctx );
    draw_crop_dividers( ctx );
    draw_crop_selectors( ctx );
    // TODO - draw_rotate_selector( ctx );
  }

  //-------------------------------------------------------------
  // Draws the image.
  public void draw( Context ctx ) {
    var w = info.width;
    var h = info.height;
    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( _angle * (Math.PI / 180.0) );
    ctx.translate( (w * -0.5), (h * -0.5) );
    draw_image( ctx );
    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( (-1 * _angle) * (Math.PI / 180.0) );
    ctx.translate( (w * -0.5), (h * -0.5) );
    draw_cropping( ctx );
    ctx.scale( width_scale, height_scale );
    ctx.rectangle( 0, 0, info.width, info.height );
    ctx.stroke();
  }

}



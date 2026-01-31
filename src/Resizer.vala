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

public enum ResizerValueFormat {
  PIXELS,
  PERCENT,
  NUM;

  public string label() {
    switch( this ) {
      case PIXELS  :  return( "px" );
      case PERCENT :  return( "%" );
      default      :  assert_not_reached();
    }
  }

  public int pixels( int base_value, int value ) {
    switch( this ) {
      case PIXELS  :  return( value );
      case PERCENT :  return( (int)(base_value * (value / 100.0)) );
      default      :  assert_not_reached();
    }
  }

  public static ResizerValueFormat parse( string value ) {
    switch( value ) {
      case "px" :  return( PIXELS );
      case "%"  :  return( PERCENT );
      default   :  return( PIXELS );
    }
  }
}

public class ResizerMargin {

  private CheckButton _btn;
  private Entry       _entry;
  private MenuButton  _mb;

  private const GLib.ActionEntry[] action_entries = {
    { "action_format", action_format, "s" },
  };

  public int value {
    get {
      return( _btn.active ? int.parse( _entry.text ) : 0 );
    }
    set {
      _entry.text = value.to_string();
    }
  }
  public ResizerValueFormat format {
    get {
      return( ResizerValueFormat.parse( _mb.label ) );
    }
    set {
      _mb.label = value.label();
    }
  }

  public signal void changed();

  public ResizerMargin( Grid grid, int row, string label, int value, ResizerValueFormat fmt ) {

    _btn = new CheckButton.with_label( label ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      active        = (value > 0)
    };
    _btn.toggled.connect(() => {
      _entry.set_sensitive( _btn.active );
      _mb.set_sensitive( _btn.active );
      if( _btn.active ) {
        _entry.grab_focus();
      }
      changed();
    });

    var focus = new EventControllerFocus();
    _entry = new Entry() {
      text          = value.to_string(),
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      width_chars   = 5,
      sensitive     = _btn.active
    };
    _entry.add_controller( focus );
    _entry.activate.connect(() => {
      changed();
    });
    focus.leave.connect(() => {
      changed();
    });

    var menu = new GLib.Menu();
    _mb = new MenuButton() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      label         = fmt.label(),
      menu_model    = menu,
      sensitive     = _btn.active
    };

    for( int i=0; i<ResizerValueFormat.NUM; i++ ) {
      var f  = (ResizerValueFormat)i;
      menu.append( f.label(), "resize_margin.action_format('%s')".printf( f.label() ) );
    }

    grid.attach( _btn,   0, row );
    grid.attach( _entry, 1, row );
    grid.attach( _mb,    2, row );

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    grid.insert_action_group( "resize_margin", actions );

  }

  //-------------------------------------------------------------
  // Performs resize format change
  private void action_format( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _mb.label = variant.get_string();
      _entry.grab_focus();
      _entry.select_region( 0, -1 );
      changed();
    }
  }

}

public class Resizer : Dialog {

  private Canvas               _canvas;
  private CanvasImageInfo      _info;
  private string               _lock_prevent = "changes-prevent-symbolic";
  private string               _lock_allow   = "changes-allow-symbolic";
  private Entry                _width;
  private Entry                _height;
  private ToggleButton         _lock;
  private MenuButton           _format;
  private Label                _size;
  private Array<ResizerMargin> _margins;
  private Image                _preview;

  private const GLib.ActionEntry[] action_entries = {
    { "action_resize", action_resize, "s" },
  };

  //-------------------------------------------------------------
  // Constructor
  public Resizer( Canvas canvas, CanvasImageInfo info ) {

    _canvas = canvas;

    // Setup dialog window
    title         = _( "Resize Image" );
    transient_for = _canvas.win;
    modal         = true;
    destroy_with_parent = true;
    add_buttons(
      _( "Cancel" ), ResponseType.REJECT,
      _( "Resize" ), ResponseType.ACCEPT
    );

    _info    = new CanvasImageInfo.from_info( info );
    _margins = new Array<ResizerMargin>();

    var size    = create_size();
    var margins = create_margins();
    var preview = create_preview();

    var grid = new Grid() {
      hexpand = true,
      vexpand = true
    };
    grid.attach( size,    0, 0 );
    grid.attach( margins, 0, 1 );
    grid.attach( preview, 1, 0, 1, 2 );

    var box = get_content_area();
    box.append( grid );

    update_preview();

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "resizer", actions );

  }

  //-------------------------------------------------------------
  // Returns the resize dimensions and border space
  public CanvasImageInfo get_image_info() {

    var width  = int.parse( _width.text );
    var height = int.parse( _height.text );

    switch( ResizerValueFormat.parse( _format.label ) ) {
      case ResizerValueFormat.PERCENT :
        width  = (int)((_info.pixbuf_rect.width  * width)  / 100.0);
        height = (int)((_info.pixbuf_rect.height * height) / 100.0);
        break;
    }

    var top    = _margins.index( 0 ).format.pixels( height, _margins.index( 0 ).value );
    var right  = _margins.index( 1 ).format.pixels( width,  _margins.index( 1 ).value );
    var bottom = _margins.index( 2 ).format.pixels( height, _margins.index( 2 ).value );
    var left   = _margins.index( 3 ).format.pixels( width,  _margins.index( 3 ).value );

    return( new CanvasImageInfo.from_resizer( width, height, top, right, bottom, left ) );

  }

  //-------------------------------------------------------------
  // Commits the current width value to the rest of the UI
  private void commit_width() {

    if( _lock.active ) {
      var fmt = ResizerValueFormat.parse( _format.label );
      if( fmt == ResizerValueFormat.PIXELS ) {
        var h = (int)(double.parse( _width.text ) / _info.get_proportion());
        _height.text = h.to_string();
      } else {
        _height.text = _width.text;
      }
    }

    update_preview();

  }

  //-------------------------------------------------------------
  // Commits the current height value to the rest of the UI
  private void commit_height() {

    if( _lock.active ) {
      var fmt = ResizerValueFormat.parse( _format.label );
      if( fmt == ResizerValueFormat.PIXELS ) {
        var w = (int)(_info.get_proportion() * double.parse( _height.text ));
        _width.text = w.to_string();
      } else {
        _width.text = _height.text;
      }
    }

    update_preview();

  }

  //-------------------------------------------------------------
  // Performs resize
  private void action_resize( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      _format.label = variant.get_string();
      _width.grab_focus();
      _width.select_region( 0, -1 );
      format_changed();
    }
  }

  //-------------------------------------------------------------
  // Create the sizing options
  private Widget create_size() {

    var wlbl = new Label( _( "Width:" ) ) {
      halign = Align.START,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var width_focus = new EventControllerFocus();
    _width = new Entry() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      text          = ((int)_info.pixbuf_rect.width).to_string(),
      width_chars   = 5,
      input_purpose = InputPurpose.DIGITS
    };
    _width.add_controller( width_focus );
    _width.activate.connect( commit_width );
    width_focus.leave.connect( commit_width );

    var hlbl = new Label( _( "Height:" ) ) {
      halign        = Align.START,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var height_focus = new EventControllerFocus();
    _height = new Entry() {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      text          = ((int)_info.pixbuf_rect.height).to_string(),
      width_chars   = 5,
      input_purpose = InputPurpose.DIGITS
    };
    _height.add_controller( height_focus );
    _height.activate.connect( commit_height );
    height_focus.leave.connect( commit_height );

    // Create the proportion control
    _lock = new ToggleButton() {
      icon_name    = _lock_prevent,
      tooltip_text = _( "Scale proportionally" ),
      active       = true
    };
    _lock.clicked.connect(() => {
      _lock.icon_name = _lock.active ? _lock_prevent : _lock_allow;
      _width.grab_focus();
      _width.select_region( 0, -1 );
    });

    var lock_box = new Box( Orientation.VERTICAL, 0 ) {
      margin_start = 10,
      valign       = Align.CENTER
    };
    lock_box.append( _lock );

    var dflt_format = ResizerValueFormat.PIXELS;
    var menu = new GLib.Menu();
    _format = new MenuButton() {
      label      = dflt_format.label(),
      menu_model = menu
    };

    for( int i=0; i<ResizerValueFormat.NUM; i++ ) {
      var f  = (ResizerValueFormat)i;
      menu.append( f.label(), "resizer.action_resize('%s')".printf( f.label() ) );
    }

    var format_box = new Box( Orientation.VERTICAL, 0 ) {
      margin_start = 10,
      margin_end   = 10,
      valign       = Align.CENTER
    };
    format_box.append( _format );

    var grid = new Grid();
    grid.attach( wlbl,       0, 0 );
    grid.attach( _width,     1, 0 );
    grid.attach( hlbl,       0, 1 );
    grid.attach( _height,    1, 1 );
    grid.attach( lock_box,   2, 0, 1, 2 );
    grid.attach( format_box, 3, 0, 1, 2 );

    var lbl   = new Label( Utils.make_title( _( "Image Size" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget  = lbl,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      child         = grid
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Called whenever the format value changes, adjusts the height
  // and width values, respectively.
  private void format_changed() {

    var orig_width  = _info.pixbuf_rect.width;
    var orig_height = _info.pixbuf_rect.height;
    var format      = ResizerValueFormat.parse( _format.label );
    var width       = int.parse( _width.text );
    var height      = int.parse( _height.text );

    switch( format ) {
      case ResizerValueFormat.PIXELS :
        _width.text  = ((orig_width  * width)  / 100.0).to_string();
        _height.text = ((orig_height * height) / 100.0).to_string();
        break;
      case ResizerValueFormat.PERCENT :
        _width.text  = (((double)orig_width  / width)  * 100).to_string();
        _height.text = (((double)orig_height / height) * 100).to_string();
        break;
    }

  }

  private Widget create_margins() {

    string[] labels = { _( "Top" ), _( "Right" ), _( "Bottom" ), _( "Left" ) };
    int[]    values = { _info.top_margin(), _info.right_margin(), _info.bottom_margin(), _info.left_margin() };

    var grid = new Grid();

    for( int i=0; i<4; i++ ) {
      var margin = new ResizerMargin( grid, i, labels[i], values[i], ResizerValueFormat.PIXELS );
      margin.changed.connect( update_preview );
      _margins.append_val( margin );
    }

    var lbl = new Label( Utils.make_title( _( "Margins" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget  = lbl,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      child         = grid
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Create the preview panel
  private Widget create_preview() {

    _preview = new Image() {
      valign        = Align.START,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    _preview.set_size_request( 200, 200 );

    _size = new Label( "" ) {
      valign        = Align.END,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _preview );
    box.append( _size );

    var lbl = new Label( Utils.make_title( _( "Preview" ) ) ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget  = lbl,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      child         = box
    };

    return( frame );

  }

  //-------------------------------------------------------------
  // Draw image in the proper location at the correct position
  private void update_preview() {

    var current  = get_image_info();
    var snapshot = new Gtk.Snapshot();
    var rect     = Graphene.Rect.alloc();
    rect.init( 0, 0, (float)200, (float)200 );
    var ctx      = snapshot.append_cairo( rect );

    // Update the resulting image size
    _size.label = _( "%d x %d pixels" ).printf( current.width, current.height );

    // Create a background color
    var scale = 200.0 / current.largest_side();
    ctx.scale( scale, scale );

    Utils.set_context_color( ctx, Utils.color_from_string( "white" ) );
    ctx.rectangle( 0, 0, current.width, current.height );
    ctx.fill_preserve();

    Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );
    ctx.set_line_width( 1 );
    ctx.stroke();

    var buf = _canvas.image.pixbuf.scale_simple( (int)current.pixbuf_rect.width, (int)current.pixbuf_rect.height, InterpType.BILINEAR );
    cairo_set_source_pixbuf( ctx, buf, current.pixbuf_rect.x, current.pixbuf_rect.y );
    ctx.paint();

    // Update the surface
    _preview.paintable = snapshot.free_to_paintable( null );

  }

}


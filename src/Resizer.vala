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

    _btn = new CheckButton.with_label( label );
    _btn.margin = 5;
    _btn.toggled.connect(() => {
      _entry.set_sensitive( _btn.active );
      _mb.set_sensitive( _btn.active );
      changed();
    });

    _entry = new Entry();
    _entry.text   = "200";
    _entry.margin = 5;
    _entry.width_chars = 5;
    _entry.set_sensitive( false );
    _entry.activate.connect(() => {
      changed();
    });

    _mb = new MenuButton();
    _mb.margin = 5;
    _mb.label = fmt.label();
    _mb.popup = new Gtk.Menu();
    _mb.set_sensitive( false );

    for( int i=0; i<ResizerValueFormat.NUM; i++ ) {
      var f  = (ResizerValueFormat)i;
      var mi = new Gtk.MenuItem.with_label( f.label() );
      mi.activate.connect(() => {
        _mb.label = f.label();
        changed();
      });
      _mb.popup.add( mi );
    }
    _mb.popup.show_all();

    grid.attach( _btn,   0, row );
    grid.attach( _entry, 1, row );
    grid.attach( _mb,    2, row );

    this.value  = value;
    this.format = fmt;

  }

}

public class Resizer {

  private CanvasImage          _image;
  private Image                _lock_prevent = new Image.from_icon_name( "changes-prevent-symbolic", IconSize.SMALL_TOOLBAR );
  private Image                _lock_allow   = new Image.from_icon_name( "changes-allow-symbolic",   IconSize.SMALL_TOOLBAR );
  private Entry                _width;
  private Entry                _height;
  private ToggleButton         _lock;
  private Label                _size;
  private Array<ResizerMargin> _margins;
  private DrawingArea          _preview;

  /* Constructor */
  public Resizer( CanvasImage image ) {

    _image   = image;
    _margins = new Array<ResizerMargin>();

  }

  /* Creates the resizer dialog and returns it */
  public Dialog make_dialog( Window parent ) {

    var dialog = new Dialog.with_buttons( _( "Resize Image" ), parent, (DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT),
        _( "Cancel" ), ResponseType.REJECT,
        _( "Resize" ), ResponseType.ACCEPT
      );

    var size    = create_size();
    var margins = create_margins();
    var preview = create_preview();

    var grid = new Grid();
    grid.attach( size,    0, 0 );
    grid.attach( margins, 0, 1 );
    grid.attach( preview, 1, 0, 1, 2 );

    var box = dialog.get_content_area();
    box.pack_start( grid, true, true );
    box.show_all();

    return( dialog );

  }

  /* Returns the resize dimensions and border space */
  public void get_dimensions( out int total_width, out int total_height, CanvasRect image_rect ) {

    var width  = int.parse( _width.text );
    var height = int.parse( _height.text );
    var top    = _margins.index( 0 ).format.pixels( height, _margins.index( 0 ).value );
    var right  = _margins.index( 1 ).format.pixels( width,  _margins.index( 1 ).value );
    var bottom = _margins.index( 2 ).format.pixels( height, _margins.index( 2 ).value );
    var left   = _margins.index( 3 ).format.pixels( width,  _margins.index( 3 ).value );

    total_width  = left + width  + right;
    total_height = top  + height + bottom;

    image_rect.copy_coords( left, top, width, height );

  }

  /* Create the sizing options */
  private Widget create_size() {

    int width, height;
    _image.get_dimensions( out width, out height );

    double proportion = (double)width / height;

    var wlbl = new Label( _( "Width:" ) );
    wlbl.margin = 5;
    wlbl.halign = Align.START;

    _width = new Entry();
    _width.margin        = 5;
    _width.text          = width.to_string();
    _width.width_chars   = 5;
    _width.input_purpose = InputPurpose.DIGITS;
    _width.activate.connect(() => {
      if( _lock.active ) {
        var h = (int)(double.parse( _width.text ) / proportion);
        _height.text = h.to_string();
      }
      update_preview();
    });

    var hlbl = new Label( _( "Height:" ) );
    hlbl.margin = 5;
    hlbl.halign = Align.START;

    _height = new Entry();
    _height.margin        = 5;
    _height.text          = height.to_string();
    _height.width_chars   = 5;
    _height.input_purpose = InputPurpose.DIGITS;
    _height.activate.connect(() => {
      if( _lock.active ) {
        var w = (int)(proportion * double.parse( _height.text ));
        _width.text = w.to_string();
      }
      update_preview();
    });

    /* Create the proportion control */
    _lock = new ToggleButton();
    _lock.set_tooltip_text( _( "Scale proportionally" ) );
    _lock.image  = _lock_prevent;
    _lock.active = true;
    _lock.clicked.connect(() => {
      _lock.image = _lock.active ? _lock_prevent : _lock_allow;
    });

    var lock_box = new Box( Orientation.VERTICAL, 0 );
    lock_box.margin_left = 10;
    lock_box.valign = Align.CENTER;
    lock_box.pack_start( _lock, false, false );

    var grid = new Grid();
    grid.attach( wlbl,     0, 0 );
    grid.attach( _width,   1, 0 );
    grid.attach( hlbl,     0, 1 );
    grid.attach( _height,  1, 1 );
    grid.attach( lock_box, 2, 0, 1, 2 );

    var frame = new Frame( null );
    var lbl   = new Label( Utils.make_title( _( "Image Size" ) ) );
    lbl.use_markup     = true;
    frame.label_widget = lbl;
    frame.margin       = 5;
    frame.add( grid );

    return( frame );

  }

  private Widget create_margins() {

    string[] labels = { _( "Top" ), _( "Right" ), _( "Bottom" ), _( "Left" ) };

    var grid = new Grid();

    for( int i=0; i<4; i++ ) {

      var margin = new ResizerMargin( grid, i, labels[i], 0, ResizerValueFormat.PIXELS );
      margin.changed.connect( update_preview );

      _margins.append_val( margin );

    }

    var frame = new Frame( null );
    var lbl   = new Label( Utils.make_title( _( "Margins" ) ) );
    lbl.use_markup     = true;
    frame.label_widget = lbl;
    frame.margin       = 5;
    frame.add( grid );

    return( frame );

  }

  /* Create the preview panel */
  private Widget create_preview() {

    _preview = new DrawingArea();
    _preview.margin = 5;
    _preview.set_size_request( 200, 200 );
    _preview.get_style_context().add_class( "preview" );
    _preview.draw.connect( on_draw );

    _size = new Label( "" );
    _size.halign = Align.END;
    _size.margin = 5;

    var box = new Box( Orientation.VERTICAL, 0 );
    box.pack_start( _preview, false, false );
    box.pack_end(   _size,    false, false );
    box.show_all();

    var frame = new Frame( null );
    var lbl   = new Label( Utils.make_title( _( "Preview" ) ) );
    lbl.use_markup     = true;
    frame.label_widget = lbl;
    frame.margin       = 5;
    frame.add( box );

    return( frame );

  }

  // The bounds of the preview box will be 200 px (height and width)
  private void update_preview() {
    stdout.printf( "In update_preview\n" );
    _preview.queue_draw();
  }

  /* Draw image in the proper location at the correct position */
  private bool on_draw( Context ctx ) {

    Idle.add(() => {

      int total_width, total_height;
      var image_rect = new CanvasRect();
      get_dimensions( out total_width, out total_height, image_rect );

      /* Update the resulting image size */
      _size.label = _( "%d x %d pixels" ).printf( total_width, total_height );

      /* Create a background color */
      _preview.get_style_context().render_background( ctx, 0, 0, 200, 200 );

      var scale = 200.0 / ((total_width < total_height) ? total_height : total_width);
      ctx.scale( scale, scale );

      Utils.set_context_color( ctx, Utils.color_from_string( "blue" ) );
      ctx.rectangle( image_rect.x, image_rect.y, image_rect.width, image_rect.height );
      ctx.fill();

      return( false );

    });

    return( false );

  }

}



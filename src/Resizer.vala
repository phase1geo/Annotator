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

  public ResizerMargin( Grid grid, int row, string label, int value, ResizerValueFormat fmt ) {

    _btn = new CheckButton.with_label( label );
    _btn.margin = 5;
    _btn.toggled.connect(() => {
      _entry.set_sensitive( _btn.active );
      _mb.set_sensitive( _btn.active );
    });

    _entry = new Entry();
    _entry.margin = 5;
    _entry.width_chars = 5;
    _entry.set_sensitive( false );

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
  private Array<ResizerMargin> _margins;

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

    var box = dialog.get_content_area();
    create_size( box );
    create_margins( box );
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
  private void create_size( Box box ) {

    int width, height;
    _image.get_dimensions( out width, out height );

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
        _height.text = _width.text;
      }
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
        _width.text = _height.text;
      }
    });

    _lock = new ToggleButton();
    _lock.image = _lock_prevent;
    _lock.clicked.connect(() => {
      if( _lock.active ) {
        _lock.image = _lock_prevent;
      } else {
        _lock.image = _lock_allow;
      }
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
    lbl.use_markup = true;
    frame.label_widget = lbl;
    frame.margin_top = 10;
    frame.add( grid );

    box.pack_start( frame, false, true );

  }

  private void create_margins( Box box ) {

    var grid = new Grid();

    _margins.append_val( new ResizerMargin( grid, 0, _( "Top" ),    0, ResizerValueFormat.PIXELS ) );
    _margins.append_val( new ResizerMargin( grid, 1, _( "Right" ),  0, ResizerValueFormat.PIXELS ) );
    _margins.append_val( new ResizerMargin( grid, 2, _( "Bottom" ), 0, ResizerValueFormat.PIXELS ) );
    _margins.append_val( new ResizerMargin( grid, 3, _( "Left" ),   0, ResizerValueFormat.PIXELS ) );

    var frame = new Frame( null );
    var lbl   = new Label( Utils.make_title( _( "Margins" ) ) );
    lbl.use_markup = true;
    frame.label_widget = lbl;
    frame.margin_top = 10;
    frame.add( grid );

    box.pack_start( frame, false, true );

  }

}



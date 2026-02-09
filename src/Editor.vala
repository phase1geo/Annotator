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

public class Editor : Box {

  private string         _filename;
  private ScrolledWindow _sw;

  public Canvas canvas { get; private set; }

  public string filename {
    get {
      return( _filename );
    }
  }

  public signal void image_loaded();

  //-------------------------------------------------------------
  // Constructor
  public Editor( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0, can_focus: true );

    // Create the canvas
    canvas = new Canvas( win, this ) {
      halign = Align.CENTER,
      valign = Align.CENTER
    };
    canvas.image_loaded.connect(() => {
      image_loaded();
    });

    _sw = new ScrolledWindow() {
      halign             = Align.FILL,
      valign             = Align.FILL,
      hexpand            = true,
      vexpand            = true,
      min_content_width  = 600,
      min_content_height = 400,
      vscrollbar_policy  = PolicyType.AUTOMATIC,
      hscrollbar_policy  = PolicyType.AUTOMATIC,
      child = canvas
    };
    ((Viewport)_sw.child).scroll_to_focus = false;
    _sw.get_style_context().add_class( Granite.STYLE_CLASS_CHECKERBOARD );

    // Create the toolbar
    var toolbar = new CanvasToolbar( canvas ) {
      halign = Align.CENTER,
      hexpand = true
    };
    canvas.image.crop_started.connect(() => {
      _sw.vscrollbar_policy = PolicyType.EXTERNAL;
      _sw.hscrollbar_policy = PolicyType.EXTERNAL;
    });
    canvas.image.crop_ended.connect(() => {
      toolbar.crop_ended();
      _sw.vscrollbar_policy = PolicyType.AUTOMATIC;
      _sw.hscrollbar_policy = PolicyType.AUTOMATIC;
    });
    canvas.image.color_picked.connect((color) => {
      toolbar.set_color( color );
    });

    var sep = new Separator( Orientation.HORIZONTAL ) {
      halign = Align.FILL,
      hexpand = true
    };

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign        = Align.FILL,
      hexpand       = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    box.append( toolbar );

    // Pack the box
    append( box );
    append( sep );
    append( _sw );

  }

  //-------------------------------------------------------------
  // Opens the given image.
  public bool open_image( string filename ) {
    _filename = filename;
    return( canvas.open_image( filename ) );
  }

  //-------------------------------------------------------------
  // Pastes the given image pixbuf to the canvas.
  public void paste_image( Gdk.Pixbuf buf, bool confirm ) {
    canvas.paste_image( buf, confirm );
  }

  //-------------------------------------------------------------
  // Pastes the given text to the canvas.
  public void paste_text( string txt ) {
    canvas.paste_text( txt );
  }

  //-------------------------------------------------------------
  // Pastes the given text as canvas items.
  public void paste_items( string items ) {
    canvas.items.deserialize_for_paste( items );
  }

  //-------------------------------------------------------------
  // Returns true if the image has been successfully set.
  public bool is_image_set() {
    return( canvas.is_surface_set() );
  }

  //-------------------------------------------------------------
  // Returns the width and height to size the current image so
  // that it fits in the window.
  public void get_win_size( out int width, out int height ) {
    width  = _sw.get_allocated_width();
    height = _sw.get_allocated_height();
  }

  //-------------------------------------------------------------
  // Returns the current scroll offsets.
  public void get_scroll_offsets( out double x, out double y ) {
    x = _sw.hadjustment.value;
    y = _sw.vadjustment.value;
  }

  //-------------------------------------------------------------
  // Sets the scroll offsets, clamping to valid ranges.
  public void set_scroll_offsets( double x, double y ) {
    var hadj = _sw.hadjustment;
    var vadj = _sw.vadjustment;
    hadj.value = clamp_adjustment( hadj, x );
    vadj.value = clamp_adjustment( vadj, y );
  }

  private double clamp_adjustment( Adjustment adj, double value ) {
    var min = adj.lower;
    var max = adj.upper - adj.page_size;
    if( max < min ) {
      max = min;
    }
    if( value < min ) {
      return( min );
    } else if( value > max ) {
      return( max );
    }
    return( value );
  }

  //-------------------------------------------------------------
  // Returns the width and height of the overlay area of the canvas.
  public CanvasRect get_displayed_rect() {
    var x = (int)_sw.hadjustment.value;
    var y = (int)_sw.vadjustment.value;
    var w = (canvas.image.info.width  < _sw.get_allocated_width())  ? canvas.image.info.width  : _sw.get_allocated_width();
    var h = (canvas.image.info.height < _sw.get_allocated_height()) ? canvas.image.info.height : _sw.get_allocated_height();
    return( new CanvasRect.from_coords( x, y, w, h ) );
  }

}

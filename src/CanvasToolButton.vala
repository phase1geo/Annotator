/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

public enum CanvasTool {
  SELECTOR,
  ARROW,
  SHAPE,
  STICKER,
  IMAGE,
  SEQUENCE,
  PENCIL,
  TEXT,
  MAGNIFIER,
  BLUR,
  CROP,
  NUM;

  //-------------------------------------------------------------
  // Returns true if this tool needs to display border options.
  public bool has_border() {
    return( (this == ARROW)    ||
            (this == SHAPE)    ||
            (this == STICKER)  ||
            (this == IMAGE)    ||
            (this == SEQUENCE) ||
            (this == PENCIL)   ||
            (this == TEXT)     ||
            (this == MAGNIFIER) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool needs to display background options.
  public bool has_background() {
    return( (this == ARROW)    ||
            (this == SHAPE)    ||
            (this == SEQUENCE) ||
            (this == TEXT) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool needs to display font options.
  public bool has_font() {
    return( (this == SEQUENCE) ||
            (this == TEXT) );
  }

  //-------------------------------------------------------------
  // Returns the CanvasItemType associated with this tool
  public CanvasItemType canvas_item_type() {
    switch( this ) {
      case SELECTOR  :  return( CanvasItemType.NONE );
      case ARROW     :  return( CanvasItemType.ARROW );
      case SHAPE     :  return( CanvasItemType.RECT_FILL );  // TBD
      case STICKER   :  return( CanvasItemType.STICKER );
      case IMAGE     :  return( CanvasItemType.IMAGE );
      case SEQUENCE  :  return( CanvasItemType.SEQUENCE );
      case PENCIL    :  return( CanvasItemType.PENCIL );
      case TEXT      :  return( CanvasItemType.TEXT );
      case MAGNIFIER :  return( CanvasItemType.MAGNIFIER );
      case BLUR      :  return( CanvasItemType.BLUR );
      case CROP      :  return( CanvasItemType.NONE );
      default        :  assert_not_reached();
    }
  }

}

public class CanvasToolButton : ToggleButton {

  private bool _ignore  = false;

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolButton( CanvasToolbar toolbar, CanvasTool tool, Popover? popover = null ) {

    Object( has_frame: false, active: false );

    if( popover != null ) {
      popover.set_parent( this );
    }

    toggled.connect(() => {
      if( !_ignore ) {
        if( active ) {
          if( popover != null ) {
            popover.popup();
          }
        } else {
          if( popover != null ) {
            popover.popdown();
          }
        }
        toolbar.selected( tool );
      }
    });

    toolbar.selected.connect((t) => {
      _ignore = true;
      if( t == tool ) {
        active = true;
      } else {
        active = false;
        if( popover != null ) {
          popover.popdown();
        }
      }
      _ignore = false;
    });

    // Create options popover
    var options = create_options( tool );

  }

  //-------------------------------------------------------------
  // Adds the options for this tool button.  We will 
  private Popover create_options( CanvasTool tool ) {

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    if( tool.has_border() ) {
      box.append( create_border_options() );
    }

    if( tool.has_background() ) {
      box.append( create_background_options() );
    }

    if( tool.has_font() ) {
      box.append( create_font_options() );
    }

    var options = new Popover() {
      child = box
    };
    options.set_parent( this );

    return( options );

  }

  private Box create_border_options() {

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

  private Box create_background_options() {

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

  private Box create_font_options() {

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates and returns the options for color.
  private Box create_color_option() {

    var lbl = new Label( _( "Color" ) );

    var color = new ColorChooserWidget() {
      // rgba = _canvas.items.props.color
    };
    color.notify.connect((p) => {
      // _canvas.items.props.color = _color_chooser.rgba;
      // mb.child = make_color_icon();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );

    return( box );

  }

}

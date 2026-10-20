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
            (this == PENCIL)   ||
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
      case SHAPE     :  return( CanvasItemType.RECT );
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

  private Canvas _canvas;
  private bool   _ignore  = false;

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolButton( CanvasToolbar toolbar, CanvasTool tool, Popover? popover = null ) {

    Object( has_frame: false, active: false );

    _canvas = toolbar.canvas;

    if( popover != null ) {
      popover.set_parent( this );
    }

    var left = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    add_controller( left );
    left.pressed.connect((n_press, x, y) => {
      if( !_ignore && active ) {
        if( popover != null ) {
          if( popover.get_mapped() ) {
            popover.popdown();
          } else {
            popover.popup();
          }
        }
      }
      toolbar.selected( tool );
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

    // Make sure that the options popover is displayed and hidden on right-click
    var right = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    add_controller( right );
    right.pressed.connect((n_press, x, y) => {
      Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
      options.pointing_to = rect;
      if( options.get_mapped() ) {
        options.popdown();
      } else {
        options.popup();
      }
    });

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
      child    = box,
      position = PositionType.BOTTOM
    };
    options.set_parent( this );

    return( options );

  }

  //-------------------------------------------------------------
  // Adds the border options to this tool menu.
  private Box create_border_options() {

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the background color options to this tool menu.
  private Box create_background_options() {

    var lbl = new Label( _( "Color" ) );

    var dialog = new ColorDialog() {
      modal = true,
      title = _( "Choose Color" ),
      with_alpha = true
    };

    var color = new ColorDialogButton( dialog ) {
      rgba = _canvas.items.props.color
    };
    color.notify["rgba"].connect(() => {
      _canvas.items.props.color = color.get_rgba();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( lbl );
    box.append( color );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the font options to this tool menu.
  private Box create_font_options() {

    var lbl = new Label( _( "Font" ) );

    var dialog = new FontDialog() {
      modal = true,
      title = _( "Select Font" )
    };

    var font = new FontDialogButton( dialog ) {
      use_font = true
    };

    font.notify["font-desc"].connect(() => {
      _canvas.items.props.font = font.font_desc;
    });

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( lbl );
    box.append( font );

    return( box );

  }

}

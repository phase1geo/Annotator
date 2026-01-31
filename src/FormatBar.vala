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

public class FormatBar : Gtk.Popover {

  private Canvas       _canvas;
  private Button       _copy;
  private Button       _cut;
  private ToggleButton _bold;
  private ToggleButton _italics;
  private ToggleButton _underline;
  private ToggleButton _strike;
  private ToggleButton _code;
  private ToggleButton _super;
  private ToggleButton _sub;
  private MenuButton   _header;
  private ColorPicker  _hilite;
  private ColorPicker  _color;
  private bool         _ignore_active = false;
  private Button       _clear;

  private const GLib.ActionEntry[] action_entries = {
    { "action_header", action_header, "i" },
  };

  //-------------------------------------------------------------
  // Construct the formatting bar
  public FormatBar( Canvas canvas ) {

    _canvas = canvas;

    autohide = false;
    set_parent( canvas );

    var box = new Box( Orientation.HORIZONTAL, 0 );

    _copy = new Button.from_icon_name( "edit-copy-symbolic" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Copy" ), "<Control>c" )
    };
    _copy.clicked.connect( handle_copy );

    _cut = new Button.from_icon_name( "edit-cut-symbolic" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Cut" ), "<Control>x" )
    };
    _cut.clicked.connect( handle_cut );

    _bold = new ToggleButton() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Bold" ), "<Control>b" )
    };
    add_markup( _bold, " <b>B</b> " );
    _bold.toggled.connect( handle_bold );

    _italics = new ToggleButton() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Italic" ), "<Control>i" )
    };
    add_markup( _italics, " <i>I</i> " );
    _italics.toggled.connect( handle_italics );

    _underline = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Underline" )
    };
    add_markup( _underline, " <u>U</u> " );
    _underline.toggled.connect( handle_underline );

    _strike = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Strikethrough" )
    };
    add_markup( _strike, " <s>S</s> " );
    _strike.toggled.connect( handle_strikethru );

    _code = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Code Block" )
    };
    add_markup( _code, "{ }" );
    _code.toggled.connect( handle_code );

    _super = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Superscript" )
    };
    add_markup( _super, "A<sup>x</sup>" );
    _super.toggled.connect( handle_superscript );

    _sub = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Subscript" )
    };
    add_markup( _sub, "A<sub>x</sub>" );
    _sub.toggled.connect( handle_subscript );

    var header_menu = new GLib.Menu();
    _header = new MenuButton() {
      has_frame = false,
      tooltip_text = _( "Header" ),
      menu_model = header_menu
    };
    add_markup_mb( _header, "H<i>x</i>" );

    for( int i=0; i<7; i++ ) {
      var label = (i == 0) ? _( "None" ) : "<H%d>".printf( i );
      header_menu.append( label, "formatbar.action_header(%d)".printf( i ) );
    }

    _hilite = new ColorPicker( Utils.color_from_string( _canvas.items.hilite_color ), ColorPickerType.HCOLOR );
    _hilite.set_toggle_tooltip( _( "Apply Highlight Color" ) );
    _hilite.set_select_tooltip( _( "Change Highlight Color" ) );
    _hilite.color_changed.connect( handle_hilite );

    _color = new ColorPicker( Utils.color_from_string( _canvas.items.font_color ), ColorPickerType.FCOLOR );
    _color.set_toggle_tooltip( _( "Apply Font Color" ) );
    _color.set_select_tooltip( _( "Change Font Color" ) );
    _color.color_changed.connect( handle_color );

    _clear = new Button.from_icon_name( "edit-clear-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Clear all formatting" )
    };
    _clear.clicked.connect( handle_clear );

    var box_a = new Box( Orientation.HORIZONTAL, 2 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      homogeneous   = true
    };
    box_a.append( _copy );
    box_a.append( _cut );

    var box_b = new Box( Orientation.HORIZONTAL, 2 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      homogeneous   = true
    };
    box_b.append( _bold );
    box_b.append( _italics );
    box_b.append( _underline );
    box_b.append( _strike );

    var box_c = new Box( Orientation.HORIZONTAL, 2 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      homogeneous   = true
    };
    box_c.append( _code );
    box_c.append( _header );

    var box_d = new Box( Orientation.HORIZONTAL, 2 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      homogeneous   = true
    };
    box_d.append( _super );
    box_d.append( _sub );

    var box_e = new Box( Orientation.HORIZONTAL, 2 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      homogeneous   = true
    };
    box_e.append( _hilite );
    box_e.append( _color );

    box.append( box_a );
    box.append( new Separator( Orientation.VERTICAL ) );
    box.append( box_b );
    box.append( new Separator( Orientation.VERTICAL ) );
    box.append( box_c );
    box.append( new Separator( Orientation.VERTICAL ) );
    box.append( box_d );
    box.append( new Separator( Orientation.VERTICAL ) );
    box.append( box_e );
    box.append( new Separator( Orientation.VERTICAL ) );
    box.append( _clear );

    child = box;

    initialize();

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "formatbar", actions );

  }

  private void add_markup( Button btn, string markup ) {
    var lbl = new Label( "<span size=\"large\">" + markup + "</span>" ) {
      use_markup = true
    };
    btn.child = lbl;
  }

  private void add_markup_mb( MenuButton btn, string markup ) {
    var lbl = new Label( "<span size=\"large\">" + markup + "</span>" ) {
      use_markup = true
    };
    btn.child = lbl;
  }

  private void format_text( FormatTag tag, string? extra=null ) {
    var text = _canvas.items.get_active_text();
    text.add_tag( tag, extra, _canvas.undo_text );
    _canvas.queue_draw();
    _canvas.grab_focus();
  }

  private void unformat_text( FormatTag tag ) {
    var text = _canvas.items.get_active_text();
    text.remove_tag( tag, _canvas.undo_text );
    _canvas.queue_draw();
    _canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard
  private void handle_copy() {
    // TBD - _canvas.do_copy();
    popdown();
  }

  //-------------------------------------------------------------
  // Cuts the selected text to the clipboard
  private void handle_cut() {
    // TBD - _canvas.do_cut();
    popdown();
  }

  //-------------------------------------------------------------
  // Toggles the bold status of the currently selected text
  private void handle_bold() {
    if( !_ignore_active ) {
      if( _bold.active ) {
        format_text( FormatTag.BOLD );
      } else {
        unformat_text( FormatTag.BOLD );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the italics status of the currently selected text
  private void handle_italics() {
    if( !_ignore_active ) {
      if( _italics.active ) {
        format_text( FormatTag.ITALICS );
      } else {
        unformat_text( FormatTag.ITALICS );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the underline status of the currently selected text
  private void handle_underline() {
    if( !_ignore_active ) {
      if( _underline.active ) {
        format_text( FormatTag.UNDERLINE );
      } else {
        unformat_text( FormatTag.UNDERLINE );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the strikethru status of the currently selected text
  private void handle_strikethru() {
    if( !_ignore_active ) {
      if( _strike.active ) {
        format_text( FormatTag.STRIKETHRU );
      } else {
        unformat_text( FormatTag.STRIKETHRU );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the code status of the currently selected text
  private void handle_code() {
    if( !_ignore_active ) {
      if( _code.active ) {
        format_text( FormatTag.CODE );
      } else {
        unformat_text( FormatTag.CODE );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the superscript status of the currently selected text
  private void handle_superscript() {
    if( !_ignore_active ) {
      if( _super.active ) {
        format_text( FormatTag.SUPER );
      } else {
        unformat_text( FormatTag.SUPER );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the superscript status of the currently selected text
  private void handle_subscript() {
    if( !_ignore_active ) {
      if( _sub.active ) {
        format_text( FormatTag.SUB );
      } else {
        unformat_text( FormatTag.SUB );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the header status of the currently selected text
  private void action_header( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var level = variant.get_int32();
      if( !_ignore_active ) {
        if( level > 0 ) {
          format_text( FormatTag.HEADER, level.to_string() );
        } else {
          unformat_text( FormatTag.HEADER );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the highlight status of the currently selected text
  private void handle_hilite( RGBA? rgba ) {
    if( !_ignore_active ) {
      if( rgba != null ) {
        _canvas.items.hilite_color = Utils.color_to_string( rgba );
        format_text( FormatTag.HILITE, _canvas.items.hilite_color );
      } else {
        unformat_text( FormatTag.HILITE );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the foreground color of the currently selected text
  private void handle_color( RGBA? rgba ) {
    if( !_ignore_active ) {
      if( rgba != null ) {
        _canvas.items.font_color = Utils.color_to_string( rgba );
        format_text( FormatTag.COLOR, _canvas.items.font_color );
      } else {
        unformat_text( FormatTag.COLOR );
      }
    }
  }

  //-------------------------------------------------------------
  // Clears all tags from selected text
  private void handle_clear() {
    var text = _canvas.items.get_active_text();
    text.remove_all_tags( _canvas.undo_text );
    _ignore_active = true;
    _bold.set_active( false );
    _italics.set_active( false );
    _underline.set_active( false );
    _strike.set_active( false );
    _code.set_active( false );
    _super.set_active( false );
    _sub.set_active( false );
    _hilite.set_active( false );
    _color.set_active( false );
    // TODO - activate_header( 0 );
    _ignore_active = false;
    _canvas.queue_draw();
    _canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Sets the active status of the given toggle button
  private void set_toggle_button( CanvasItemText text, FormatTag tag, ToggleButton btn ) {
    btn.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  //-------------------------------------------------------------
  // Sets the active status of the given color picker
  private void set_color_picker( CanvasItemText text, FormatTag tag, ColorPicker cp ) {
    cp.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  //-------------------------------------------------------------
  // Updates the state of the format bar based on the state of the
  // current text.
  private void update_from_text( CanvasItemText? text ) {
    _ignore_active = true;
    set_toggle_button( text, FormatTag.BOLD,       _bold );
    set_toggle_button( text, FormatTag.ITALICS,    _italics );
    set_toggle_button( text, FormatTag.UNDERLINE,  _underline );
    set_toggle_button( text, FormatTag.STRIKETHRU, _strike );
    set_toggle_button( text, FormatTag.CODE,       _code );
    set_toggle_button( text, FormatTag.SUPER,      _super );
    set_toggle_button( text, FormatTag.SUB,        _sub );
    set_color_picker(  text, FormatTag.HILITE,     _hilite );
    set_color_picker(  text, FormatTag.COLOR,      _color );
    // TODO - set_header( text );
    _ignore_active = false;
  }

  //-------------------------------------------------------------
  // Updates the state of the format bar based on which tags are
  // applied at the current cursor position.
  public void initialize() {
    update_from_text( _canvas.items.get_active_text() );
  }

}

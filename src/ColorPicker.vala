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

public enum ColorPickerType {
  HCOLOR,
  FCOLOR;

  public string get_css_class() {
    switch( this ) {
      case HCOLOR :  return( "hcolor" );
      case FCOLOR :  return( "fcolor" );
      default     :  assert_not_reached();
    }
  }

  public void set_image( ToggleButton btn ) {
    switch( this ) {
      case HCOLOR :
        btn.icon_name = "format-text-highlight";
        btn.child     = null;
        break;
      case FCOLOR : {
        var lbl = new Label( "<span size=\"large\">A</span>" );
        lbl.use_markup = true;
        btn.child      = lbl;
        break;
      }
      default :  assert_not_reached();
    }
  }

}

public class ColorPicker : Box {

  private ColorPickerType    _type;
  private ToggleButton       _toggle;
  private ColorChooserWidget _chooser;
  private MenuButton         _select;
  private bool               _ignore_active;

  public signal void color_changed( RGBA? color );

  public ColorPicker( RGBA init_color, ColorPickerType type ) {

    _type = type;

    homogeneous = true;

    _toggle = new ToggleButton() {
      has_frame = false
    };
    _toggle.toggled.connect( handle_toggle );
    _toggle.get_style_context().add_class( type.get_css_class() );
    type.set_image( _toggle );

    _chooser = new ColorChooserWidget();
    _chooser.rgba = init_color;

    var btn_controller = new GestureClick();
    var overlay = new Overlay() {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10,
      child         = _chooser
    };
    overlay.add_controller( btn_controller );
    btn_controller.pressed.connect((n_press, x, y) => {
      handle_chooser();
    });

    _select = new MenuButton() {
      has_frame = false
    };
    _select.get_style_context().add_class( "color_chooser" );

    _select.popover = new Popover() {
      child = overlay
    };

    append( _toggle );
    append( _select );

    update_css( init_color );

  }

  public void set_toggle_tooltip( string tooltip ) {
    _toggle.set_tooltip_text( tooltip );
  }

  public void set_select_tooltip( string tooltip ) {
    _select.set_tooltip_text( tooltip );
  }

  public void set_active( bool active ) {
    _ignore_active = true;
    _toggle.active = active;
    _ignore_active = false;
  }

  private void update_css( RGBA rgba ) {
    var provider = new CssProvider();
    try {
      var color    = Utils.color_to_string( rgba );
      var css_data = ".%s { background: %s; }".printf( _type.get_css_class(), color );
      provider.load_from_data( css_data.data );
      StyleContext.add_provider_for_display(
        Display.get_default(),
        provider,
        STYLE_PROVIDER_PRIORITY_APPLICATION
      );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to update css: %s\n", e.message );
    }
  }

  private void handle_toggle() {
    if( !_ignore_active ) {
      if( _toggle.active ) {
        color_changed( _chooser.rgba );
      } else {
        color_changed( null );
      }
    }
  }

  private bool handle_chooser() {
    update_css( _chooser.rgba );
    set_active( true );
    color_changed( _chooser.rgba );
    _select.popover.popdown();
    return( true );
  }

}

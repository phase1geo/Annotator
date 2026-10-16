/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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
        var lbl = new Label( "<span size=\"large\">\u25c9</span>" ) {
          use_markup = true
        };
        btn.child = lbl;
        break;
      case FCOLOR : {
        var lbl = new Label( "<span size=\"large\">A</span>" ) {
          use_markup = true
        };
        btn.child = lbl;
        break;
      }
      default :  assert_not_reached();
    }
  }

}

public class ColorPicker : Box {

  private ColorPickerType _type;
  private ToggleButton    _toggle;
  private Button          _select;
  private bool            _ignore_active;
  private RGBA            _color;

  public signal void color_changed( RGBA? color );

  public ColorPicker( MainWindow win, RGBA init_color, ColorPickerType type ) {

    Object( orientation: Orientation.HORIZONTAL );

    _type  = type;
    _color = init_color.copy();

    homogeneous = true;

    _toggle = new ToggleButton() {
      has_frame = false
    };
    _toggle.add_css_class( type.get_css_class() );
    _toggle.toggled.connect( handle_toggle );
    type.set_image( _toggle );

    var chooser = new ColorDialog() {
      modal = true,
      with_alpha = true
    };

    _select = new Button.from_icon_name( "view-more-symbolic" ) {
      has_frame = false
    };
    _select.clicked.connect(() => {
      chooser.choose_rgba.begin( win, _color, null, (obj, res) => {
        try {
          var rgba = chooser.choose_rgba.end( res );
          if( rgba != null ) {
            _color.free();
            _color = rgba.copy();
            update_css( rgba );
            set_active( true );
            color_changed( rgba );
          }
        } catch( Error e ) {}
      });
    });

    append( _toggle );
    append( _select );

    add_css_class( Granite.STYLE_CLASS_LINKED );

    update_css( _color );

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
    var fg       = Granite.contrasting_foreground_color( rgba );
    var css_data = ".%s { background: %s; color: %s; }".printf( _type.get_css_class(), rgba.to_string(), fg.to_string() );
    provider.load_from_string( css_data );
    StyleContext.add_provider_for_display(
      Display.get_default(),
      provider,
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

  private void handle_toggle() {
    if( !_ignore_active ) {
      if( _toggle.active ) {
        color_changed( _color );
      } else {
        color_changed( null );
      }
    }
  }

}

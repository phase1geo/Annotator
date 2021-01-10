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
using Cairo;
using Pango;

public enum CanvasItemStrokeWidth {
  WIDTH1,
  WIDTH2,
  WIDTH3,
  WIDTH4,
  NUM;

  public int width() {
    switch( this ) {
      case WIDTH1 :  return( 6 );
      case WIDTH2 :  return( 10 );
      case WIDTH3 :  return( 14 );
      case WIDTH4 :  return( 18 );
      default     :  assert_not_reached();
    }
  }

  public string to_string() {
    switch( this ) {
      case WIDTH1 :  return( "width1" );
      case WIDTH2 :  return( "width2" );
      case WIDTH3 :  return( "width3" );
      case WIDTH4 :  return( "width4" );
      default     :  assert_not_reached();
    }
  }

  public static CanvasItemStrokeWidth parse( string value ) {
    switch( value ) {
      case "width1" :  return( WIDTH1 );
      case "width2" :  return( WIDTH2 );
      case "width3" :  return( WIDTH3 );
      case "width4" :  return( WIDTH4 );
      default       :  return( WIDTH1 );
    }
  }
}

public enum CanvasItemDashPattern {
  NONE,
  SHORT,
  LONG,
  NUM;

  /* Converts this value to a string */
  public string to_string() {
    switch( this ) {
      case NONE  :  return( "none" );
      case SHORT :  return( "short" );
      case LONG  :  return( "long" );
      default    :  assert_not_reached();
    }
  }

  /* Converts a string to this value type */
  public static CanvasItemDashPattern parse( string value ) {
    switch( value ) {
      case "none"  :  return( NONE );
      case "short" :  return( SHORT );
      case "long"  :  return( LONG );
      default      :  return( NONE );
    }
  }

  /* Sets the background dash pattern based on the current value */
  public void set_bg_pattern( Cairo.Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},      0 );  break;
      case SHORT :  ctx.set_dash( { 7, 3}, 0 );  break;
      case LONG  :  ctx.set_dash( {12, 8}, 0 );  break;
      default    :  assert_not_reached();
    }
  }

  /* Sets the foreground dash pattern based on the current value */
  public void set_fg_pattern( Cairo.Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},        0 );  break;
      case SHORT :  ctx.set_dash( { 5,  5}, -1 );  break;
      case LONG  :  ctx.set_dash( {10, 10}, -1 );  break;
      default    :  assert_not_reached();
    }
  }
}

/* Structure containing formatting properties used by canvas items */
public class CanvasItemProperties {

  private bool                  _use_settings = false;
  private RGBA                  _color        = Utils.color_from_string( "black" );
  private CanvasItemStrokeWidth _stroke_width = CanvasItemStrokeWidth.WIDTH1;
  private CanvasItemDashPattern _dash         = CanvasItemDashPattern.NONE;
  private int                   _blur_radius  = 10;
  private FontDescription       _font;

  public RGBA color {
    get {
      return( _color );
    }
    set {
      if( !_color.equal( value ) ) {
        _color = value;
        if( _use_settings ) {
          Annotator.settings.set_string( "item-color", Utils.color_to_string( _color ) );
        }
        changed();
      }
    }
  }
  public CanvasItemStrokeWidth stroke_width {
    get {
      return( _stroke_width );
    }
    set {
      if( _stroke_width != value ) {
        _stroke_width = value;
        if( _use_settings ) {
          Annotator.settings.set_string( "stroke-width", _stroke_width.to_string() );
        }
        changed();
      }
    }
  }
  public CanvasItemDashPattern dash {
    get {
      return( _dash );
    }
    set {
      if( _dash != value ) {
        _dash = value;
        if( _use_settings ) {
          Annotator.settings.set_string( "dash-pattern", dash.to_string() );
        }
        changed();
      }
    }
  }
  public int blur_radius {
    get {
      return( _blur_radius );
    }
    set {
      if( _blur_radius != value ) {
        _blur_radius = value;
        if( _use_settings ) {
          Annotator.settings.set_int( "blur-radius", _blur_radius );
        }
        changed();
      }
    }
  }
  public FontDescription font {
    get {
      return( _font );
    }
    set {
      if( !font.equal( value ) ) {
        _font = value.copy();
        if( _use_settings ) {
          Annotator.settings.set_string( "font", _font.to_string() );
        }
        changed();
      }
    }
  }

  public signal void changed();

  /* Default constructor */
  public CanvasItemProperties( bool use_settings = false ) {
    _use_settings = use_settings;
    if( _use_settings ) {
      _color        = Utils.color_from_string( Annotator.settings.get_string( "item-color" ) );
      _stroke_width = CanvasItemStrokeWidth.parse( Annotator.settings.get_string( "stroke-width" ) );
      _dash         = CanvasItemDashPattern.parse( Annotator.settings.get_string( "dash-pattern" ) );
      _blur_radius  = Annotator.settings.get_int( "blur-radius" );
      _font         = FontDescription.from_string( Annotator.settings.get_string( "font" ) );
    } else {
      _font = new FontDescription();
    }
  }

  /* Copies the properties to this class */
  public void copy( CanvasItemProperties props ) {
    _use_settings = props._use_settings;
    color         = props.color;
    stroke_width  = props.stroke_width;
    dash          = props.dash;
    blur_radius   = props.blur_radius;
    font          = props.font.copy();
  }

  /* Saves the contents of this properties class as XML */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "properties" );
    node->set_prop( "color",        Utils.color_to_string( color ) );
    node->set_prop( "stroke-width", stroke_width.to_string() );
    node->set_prop( "dash",         dash.to_string() );
    node->set_prop( "blur-radius",  blur_radius.to_string() );
    node->set_prop( "font",         font.to_string() );
    return( node );
  }

  /* Loads the contents of this properties class from XML */
  public void load( Xml.Node* node ) {
    var c = node->get_prop( "color" );
    if( c != null ) {
      color.parse( c );
    }
    var sw = node->get_prop( "stroke-width" );
    if( sw != null ) {
      stroke_width = CanvasItemStrokeWidth.parse( sw );
    }
    var d = node->get_prop( "dash" );
    if( d != null ) {
      dash = CanvasItemDashPattern.parse( d );
    }
    var br = node->get_prop( "blur-radius" );
    if( br != null ) {
      blur_radius = int.parse( br );
    }
    var f = node->get_prop( "font" );
    if( f != null ) {
      font = FontDescription.from_string( f );
    }
  }

}


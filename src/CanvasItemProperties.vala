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
using Pango;

public enum CanvasItemStrokeWidth {
  WIDTH0,
  WIDTH1,
  WIDTH2,
  WIDTH3,
  WIDTH4,
  NUM;

  public int width() {
    switch( this ) {
      case WIDTH0 :  return( 2 );
      case WIDTH1 :  return( 6 );
      case WIDTH2 :  return( 10 );
      case WIDTH3 :  return( 14 );
      case WIDTH4 :  return( 18 );
      default     :  assert_not_reached();
    }
  }

  public string to_string() {
    switch( this ) {
      case WIDTH0 :  return( "width0" );
      case WIDTH1 :  return( "width1" );
      case WIDTH2 :  return( "width2" );
      case WIDTH3 :  return( "width3" );
      case WIDTH4 :  return( "width4" );
      default     :  assert_not_reached();
    }
  }

  public static CanvasItemStrokeWidth parse( string value ) {
    switch( value ) {
      case "width0" :  return( WIDTH0 );
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

  //-------------------------------------------------------------
  // Converts this value to a string
  public string to_string() {
    switch( this ) {
      case NONE  :  return( "none" );
      case SHORT :  return( "short" );
      case LONG  :  return( "long" );
      default    :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Converts a string to this value type
  public static CanvasItemDashPattern parse( string value ) {
    switch( value ) {
      case "none"  :  return( NONE );
      case "short" :  return( SHORT );
      case "long"  :  return( LONG );
      default      :  return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Sets the background dash pattern based on the current value
  public void set_bg_pattern( Cairo.Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},      0 );  break;
      case SHORT :  ctx.set_dash( { 7, 3}, 0 );  break;
      case LONG  :  ctx.set_dash( {12, 8}, 0 );  break;
      default    :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Sets the foreground dash pattern based on the current value
  public void set_fg_pattern( Cairo.Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},        0 );  break;
      case SHORT :  ctx.set_dash( { 5,  5}, -1 );  break;
      case LONG  :  ctx.set_dash( {10, 10}, -1 );  break;
      default    :  assert_not_reached();
    }
  }
}

//-------------------------------------------------------------
// Structure containing formatting properties used by canvas items
public class CanvasItemProperties {

  private RGBA                  _color        = Utils.color_from_string( "red" );
  private bool                  _fill         = false;
  private double                _alpha        = 1.0;
  private bool                  _stroke       = true;
  private CanvasItemStrokeWidth _stroke_width = CanvasItemStrokeWidth.WIDTH1;
  private RGBA                  _stroke_color = Utils.color_from_string( "black" );
  private bool                  _outline      = true;
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
        changed();
      }
    }
  }
  public bool fill {
    get {
      return( _fill );
    }
    set {
      if( _fill != value ) {
        _fill = value;
        changed();
      }
    }
  }
  public double alpha {
    get {
      return( _alpha );
    }
    set {
      if( _alpha != value ) {
        _alpha = value;
        changed();
      }
    }
  }
  public bool stroke {
    get {
      return( _stroke );
    }
    set {
      if( _stroke != value ) {
        _stroke = value;
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
        changed();
      }
    }
  }
  public RGBA stroke_color {
    get {
      return( _stroke_color );
    }
    set {
      if( !_stroke_color.equal( value ) ) {
        _stroke_color = value;
        changed();
      }
    }
  }
  public bool outline {
    get {
      return( _outline );
    }
    set {
      if( _outline != value ) {
        _outline = value;
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
        changed();
      }
    }
  }

  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor
  public CanvasItemProperties() {
    _font = new FontDescription();
  }

  //-------------------------------------------------------------
  // Copies the properties to this class
  public void copy( CanvasItemProperties props ) {
    color         = props.color;
    fill          = props.fill;
    alpha         = props.alpha;
    stroke        = props.stroke;
    stroke_width  = props.stroke_width;
    stroke_color  = props.stroke_color;
    outline       = props.outline;
    dash          = props.dash;
    blur_radius   = props.blur_radius;
    font          = props.font.copy();
  }

  //-------------------------------------------------------------
  // Returns true if the given properties element matches values
  // with us
  public bool equals( CanvasItemProperties props ) {
    return(
      color.equal( props.color ) &&
      (fill == props.fill) &&
      (alpha == props.alpha) &&
      (stroke == props.stroke) &&
      (stroke_width == props.stroke_width) &&
      stroke_color.equal( props.stroke_color ) &&
      (outline == props.outline) &&
      (dash == props.dash) &&
      (blur_radius == props.blur_radius) &&
      font.equal( props.font)
    );
  }

  //-------------------------------------------------------------
  // Outputs the contents of the class for debugging purposes in
  // string format
  public string to_string() {
    return( "color: %s, fill: %s, alpha: %g, stroke: %s, stroke-width: %d, stroke-color: %s, dash: %s, outline: %s, blur: %d, font: %s\n".printf(
      Utils.color_to_string( color ), fill.to_string(), alpha,
      stroke.to_string(), stroke_width, Utils.color_to_string( stroke_color ),
      dash.to_string(), outline.to_string(),
      blur_radius, font.to_string() ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of this properties class as XML
  public Xml.Node* save( string name = "properties" ) {
    Xml.Node* node = new Xml.Node( null, name );
    node->set_prop( "color",        Utils.color_to_string( color ) );
    node->set_prop( "fill",         fill.to_string() );
    node->set_prop( "alpha",        alpha.to_string() );
    node->set_prop( "stroke",       stroke.to_string() );
    node->set_prop( "stroke-width", stroke_width.to_string() );
    node->set_prop( "stroke-color", Utils.color_to_string( stroke_color ) );
    node->set_prop( "show-outline", outline.to_string() );
    node->set_prop( "dash",         dash.to_string() );
    node->set_prop( "blur-radius",  blur_radius.to_string() );
    node->set_prop( "font",         font.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this properties class from XML
  public void load( Xml.Node* node ) {
    var c = node->get_prop( "color" );
    if( c != null ) {
      _color.parse( c );
    }
    var fe = node->get_prop( "fill" );
    if( fe != null ) {
      fill = bool.parse( fe );
    }
    var a = node->get_prop( "alpha" );
    if( a != null ) {
      alpha = double.parse( a );
    }
    var se = node->get_prop( "stroke" );
    if( se != null ) {
      stroke = bool.parse( se );
    }
    var sw = node->get_prop( "stroke-width" );
    if( sw != null ) {
      stroke_width = CanvasItemStrokeWidth.parse( sw );
    }
    var sc = node->get_prop( "stroke-color" );
    if( sc != null ) {
      _stroke_color.parse( sc );
    }
    var o = node->get_prop( "show-outline" );
    if( o != null ) {
      outline = bool.parse( o );
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


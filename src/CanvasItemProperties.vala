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
      default      :  assert_not_reached();
    }
  }

  /* Sets the background dash pattern based on the current value */
  public void set_bg_pattern( Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},      0 );  break;
      case SHORT :  ctx.set_dash( { 7, 3}, 0 );  break;
      case LONG  :  ctx.set_dash( {12, 8}, 0 );  break;
    }
  }

  /* Sets the foreground dash pattern based on the current value */
  public void set_fg_pattern( Context ctx ) {
    switch( this ) {
      case NONE  :  ctx.set_dash( {},        0 );  break;
      case SHORT :  ctx.set_dash( { 5,  5}, -1 );  break;
      case LONG  :  ctx.set_dash( {10, 10}, -1 );  break;
    }
  }
}

/* Structure containing formatting properties used by canvas items */
public class CanvasItemProperties {

  private RGBA                  _color        = Utils.color_from_string( "black" );
  private int                   _stroke_width = 4;
  private CanvasItemDashPattern _dash         = CanvasItemDashPattern.NONE;
  private int                   _blur_radius  = 10;

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
  public int stroke_width {
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

  public signal void changed();

  /* Default constructor */
  public CanvasItemProperties() {}

  /* Constructor */
  public CanvasItemProperties.initialize( RGBA c, int sw, CanvasItemDashPattern d, int br ) {
    color        = c;
    stroke_width = sw;
    dash         = d;
    blur_radius  = br;
  }

  /* Copies the properties to this class */
  public void copy( CanvasItemProperties props ) {
    color        = props.color;
    stroke_width = props.stroke_width;
    dash         = props.dash;
    blur_radius  = props.blur_radius;
  }

  /* Saves the contents of this properties class as XML */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "properties" );
    node->set_prop( "color",        Utils.color_to_string( color ) );
    node->set_prop( "stroke-width", stroke_width.to_string() );
    node->set_prop( "dash",         dash.to_string() );
    node->set_prop( "blur-radius",  blur_radius.to_string() );
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
      stroke_width = int.parse( sw );
    }
    var d = node->get_prop( "dash" );
    if( d != null ) {
      dash = CanvasItemDashPattern.parse( d );
    }
    var br = node->get_prop( "blur-radius" );
    if( br != null ) {
      blur_radius = int.parse( br );
    }
  }

}


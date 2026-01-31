/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Annotator)
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

public class ExportPNG : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportPNG( Canvas canvas ) {
    base( canvas, "png", _( "PNG" ), { ".png" } );
  }

  //-------------------------------------------------------------
  // Default constructor
  public override bool export( string filename, Pixbuf source ) {

    // Make sure that the filename is sane
    var fname = repair_filename( filename );

    // Create the drawing surface
    var format = get_bool( "transparency" ) ? Format.ARGB32 : Format.RGB24;
    var surface = new ImageSurface( format, source.width, source.height );
    var context = new Context( surface );
    canvas.draw_all( context );

    string[] option_keys   = {};
    string[] option_values = {};

    var value = get_scale( "compression" );
    option_keys += "compression";  option_values += value.to_string();

    try {
      var pixbuf = pixbuf_get_from_surface( surface, 0, 0, surface.get_width(), surface.get_height() );
      pixbuf.savev( fname, name, option_keys, option_values );
    } catch( Error e ) {
      stdout.printf( "Error writing %s: %s\n", name, e.message );
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Add the PNG settings
  public override void add_settings( Grid grid ) {
    add_setting_scale( "compression", grid, _( "Compression" ), null, 0, 9, 1, 5 );
    add_setting_bool( "transparency", grid, _( "Transparency"), null, false);
  }

  //-------------------------------------------------------------
  // Save the settings
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "compression", get_scale( "compression" ).to_string() );
    node->set_prop( "transparency", get_bool( "transparency" ).to_string() );
  }

  //-------------------------------------------------------------
  // Load the settings
  public override void load_settings( Xml.Node* node ) {

    var c = node->get_prop( "compression" );
    if( c != null ) {
      set_scale( "compression", int.parse( c ) );
    }

    var t = node->get_prop( "transparency" );
    if( t != null ) {
      set_bool( "transparency", bool.parse( t ) );
    }
  }

}

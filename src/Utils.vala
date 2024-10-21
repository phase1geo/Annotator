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

public class Utils {

  /* Creates the given directory (and all parent directories) with appropriate permissions */
  public static bool create_dir( string path ) {
    return( DirUtils.create_with_parents( path, 0755 ) == 0 );
  }

  /*
   Returns a regular expression useful for parsing clickable URLs.
  */
  public static string url_re() {
    string[] res = {
      "mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+",
      "[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*)",
      "file:///([^,\\/:*\\?\\<>\"\\|]+(/|\\\\){0,1})+"
    };
    return( "(" + string.joinv( "|",res ) + ")" );
  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  public static string color_to_string( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Returns the RGBA color for the given color value */
  public static RGBA color_from_string( string value ) {
    RGBA c = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
    c.parse( value );
    return( c );
  }

  /* Sets the context source color to the given color value */
  public static void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  public static void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /* Returns the red, green and blue color values that are needed by the Pango color attributes */
  public static void get_attribute_color( RGBA color, out uint16 red, out uint16 green, out uint16 blue ) {
    var maxval = 65535;
    red   = (uint16)(color.red   * maxval);
    green = (uint16)(color.green * maxval);
    blue  = (uint16)(color.blue  * maxval);
  }

  /* Returns true if the given coordinates are within the specified bounds */
  public static bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx < x) && (x < (bx + bw)) && (by < y) && (y < (by + bh)) );
  }

  /* Returns true if the given set of coordinates is within the given polygon */
  public static bool is_within_polygon( double x, double y, Array<CanvasPoint> points, int length = -1 ) {

    var corners   = (length == -1) ? (int)points.length : length;
    var j         = corners - 1;
    var odd_nodes = false;

    for( int i=0; i<corners; i++ ) {
      var pi = points.index( i );
      var pj = points.index( j );
      if( (((pi.y < y) && (pj.y >= y)) || ((pj.y < y) && (pi.y >= y))) && ((pi.x <= x) || (pj.x <= x)) ) {
        odd_nodes ^= ((pi.x + (y - pi.y) / (pj.y - pi.y) * (pj.x - pi.x)) < x);
      }
      j = i;
    }

    return( odd_nodes );

  }

  /*
   Returns true if the given point exists within the given ellipsis.
     where h = mid_x, k = mid_y, a = widest width, b = narrowest width
  */
  public static bool is_within_oval( double x, double y, double h, double k, double a, double b ) {
    var p = (Math.pow( (x - h), 2 ) / Math.pow( a, 2 )) + (Math.pow( (y - k), 2 ) / Math.pow( b, 2 ));
    return( p <= 1 );
  }

  /* Returns a string that is suitable to use as an inspector title */
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

  /* Returns a string that is used to display a tooltip with displayed accelerator */
  public static string tooltip_with_accel( string tooltip, string accel ) {
    string[] accels = {accel};
    return( Granite.markup_accel_tooltip( accels, tooltip ) );
  }

  /* Opens the given URL in the proper external default application */
  public static void open_url( string url ) {
    if( (url.substring( 0, 7 ) == "file://") || (url.get_char( 0 ) == '/') ) {
      var app = AppInfo.get_default_for_type( "inode/directory", true );
      var uris = new List<string>();
      uris.append( url );
      try {
        app.launch_uris( uris, null );
      } catch( GLib.Error e ) {
        stdout.printf( "error: %s\n", e.message );
      }
    } else {
      try {
        AppInfo.launch_default_for_uri( url, null );
      } catch( GLib.Error e ) {
        stdout.printf( "error: %s\n", e.message );
      }
    }
  }

  /* Returns the line height of the first line of the given pango layout */
  public static double get_line_height( Pango.Layout layout ) {
    int height;
    var line = layout.get_line_readonly( 0 );
    if( line == null ) {
      int width;
      layout.get_size( out width, out height );
    } else {
      Pango.Rectangle ink_rect, log_rect;
      line.get_extents( out ink_rect, out log_rect );
      height = log_rect.height;
    }
    return( height / Pango.SCALE );
  }

  /* Searches for the beginning or ending word */
  public static int find_word( string str, int cursor, bool wordstart ) {
    try {
      MatchInfo match_info;
      var substr = wordstart ? str.substring( 0, cursor ) : str.substring( cursor );
      var re = new Regex( wordstart ? ".*(\\W\\w|[\\w\\s][^\\w\\s])" : "(\\w\\W|[^\\w\\s][\\w\\s])" );
      if( re.match( substr, 0, out match_info ) ) {
        int start_pos, end_pos;
        match_info.fetch_pos( 1, out start_pos, out end_pos );
        return( wordstart ? (start_pos + 1) : (cursor + start_pos + 1) );
      }
    } catch( RegexError e ) {}
    return( -1 );
  }

  /* Returns true if the given string is a valid URL */
  public static bool is_url( string str ) {
    return( Regex.match_simple( url_re(), str ) );
  }

  public static void set_chooser_folder( FileChooser chooser ) {
    var dir_path = Annotator.settings.get_string( "last-directory" );
    if( dir_path != "" ) {
      try {
        var dir = File.new_for_path( dir_path );
        chooser.set_current_folder( dir );
      } catch( Error e ) {}
    }
  }

  public static void store_chooser_folder( string file ) {
    var dir = GLib.Path.get_dirname( file );
    Annotator.settings.set_string( "last-directory", dir );
  }

  /* Returns the child widget at the given index of the parent widget (or null if one does not exist) */
  public static Widget? get_child_at_index( Widget parent, int index ) {
    var child = parent.get_first_child();
    while( (child != null) && (index-- > 0) ) {
      child = child.get_next_sibling();
    }
    return( child );
  }

  /* Creates a menu item for a popover */
  public static Button make_menu_item( string label ) {
    var lbl = new Label( label ) {
      xalign = (float)0
    };
    var btn = new Button() {
      halign = Align.FILL,
      has_frame = false,
      child = lbl
    };
    return( btn );
  }

  /* Creates a pixbuf from a Cairo surface */
  public static Gdk.Pixbuf? surface_to_pixbuf( Cairo.Surface surface ) {

    FileIOStream iostream;

    try {
      var tmp = File.new_tmp( null, out iostream );
      surface.write_to_png( tmp.get_path() );
      var pixbuf = new Pixbuf.from_file( tmp.get_path() );
      return( pixbuf );
    } catch( Error e ) {
      return( null );
    }

  }

  /* Creates a pixbuf from a Texture */
  public static Gdk.Pixbuf? texture_to_pixbuf( Gdk.Texture texture ) {

    FileIOStream iostream;

    try {
      var tmp = File.new_tmp( null, out iostream );
      texture.save_to_png( tmp.get_path() );
      var pixbuf = new Pixbuf.from_file( tmp.get_path() );
      return( pixbuf );
    } catch( Error e ) {
      return( null );
    }

  }

  /*
   Returns true if the following key was found to be pressed (regardless of
   keyboard layout).
  */
  public static bool has_key( uint[] kvs, uint key ) {
    foreach( uint kv in kvs ) {
      if( kv == key ) return( true );
    }
    return( false );
  }

  public static string read_stream( InputStream stream ) {
    var str = "";
    var dis = new DataInputStream( stream );
    try {
      do {
        var line = dis.read_line();
        if( line != null ) {
          str += line + "\n";
        }
      } while( dis.get_available() > 0 );
    } catch( IOError e ) {
      return( "" );
    }
    return( str );
  }

  //-------------------------------------------------------------
  // Creates a temporary filename.
  public static string? create_temp_filename( string extension ) {
    try {
      string filename = "";
      var fd = FileUtils.open_tmp( "annotator_XXXXXX.%s".printf( extension ), out filename );
      FileUtils.close( fd );
      return( filename );
    } catch( FileError e ) {}
    return( null );
  }

}

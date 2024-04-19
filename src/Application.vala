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
using GLib;

public class Annotator : Gtk.Application {

  private static bool       show_version  = false;
  private        MainWindow appwin;

  public  static GLib.Settings settings;
  public  static bool          use_clipboard     = false;
  public  static bool          take_screenshot   = false;
  public  static bool          std_input         = false;
  public  static string        version           = "2.0.0";

  public Annotator () {

    Object( application_id: "com.github.phase1geo.annotator", flags: ApplicationFlags.HANDLES_OPEN );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* First method called in the startup process */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.annotator" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_for_display( Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/annotator/images" );

    /* Create the main window */
    appwin = new MainWindow( this );

    /* Attempt to paste from the clipboard */
    if( std_input ) {
      if( !appwin.handle_standard_input() ) {
        stderr.printf( _( "\nERROR:  Unable to read image from standard input\n" ) );
        Process.exit( 1 );
      }
    } else if( use_clipboard ) {
      if( !appwin.do_paste_image() ) {
        stderr.printf( _( "\nERROR:  Image does not exist on the clipboard\n" ) );
        Process.exit( 1 );
      }
    } else if( take_screenshot ) {
      appwin.do_screenshot();
    }

    /* Handle any changes to the position of the window */
    /*
     * TODO
    appwin.configure_event.connect(() => {
      int root_x, root_y;
      int size_w, size_h;
      appwin.get_position( out root_x, out root_y );
      appwin.get_size( out size_w, out size_h );
      settings.set_int( "window-x", root_x );
      settings.set_int( "window-y", root_y );
      settings.set_int( "window-w", size_w );
      settings.set_int( "window-h", size_h );
      return( false );
    });
    */

  }

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      appwin.notification( _( "Opening file" ), file );
      appwin.open_file( file );
    }
  }

  /* Called if we have no files to open */
  protected override void activate() {
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- Annotator Options" );
    var options = new OptionEntry[5];

    /* Create the command-line options */
    options[0] = {"version",        0,   0, OptionArg.NONE, ref show_version,    _( "Display version number." ), null};
    options[1] = {"use-clipboard",  0,   0, OptionArg.NONE, ref use_clipboard,   _( "Annotate clipboard image." ), null};
    options[2] = {"screenshot",     0,   0, OptionArg.NONE, ref take_screenshot, _( "Take and annotate a screenshot." ), null};
    options[3] = {"standard-input", 'i', 0, OptionArg.NONE, ref std_input,       _( "Uses image data from standard input" ), null};
    options[4] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( "\nERROR: %s\n\n", e.message );
      stdout.printf( "    Run '%s --help' to see valid options\n\n", args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( version + "\n" );
      Process.exit( 0 );
    }

  }

  /* Creates the home directory and returns it */
  public static string get_home_dir() {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "annotator" );
    Utils.create_dir( dir );
    return( dir );
  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {

    var app = new Annotator();
    app.parse_arguments( ref args );

    return( app.run( args ) );

  }

}

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

public class Annotator : Granite.Application {

  private static bool       show_version  = false;
  private        MainWindow appwin;

  public  static GLib.Settings settings;
  public  static bool          use_clipboard     = false;
  public  static CaptureType   screenshot_type   = CaptureType.NONE;
  public  static int           screenshot_delay  = 0;
  public  static bool          screenshot_incwin = false;
  public  static string        version           = "1.2.0";

  public Annotator () {

    Object( application_id: "com.github.phase1geo.annotator", flags: ApplicationFlags.HANDLES_OPEN );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* First method called in the startup process */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.annotator" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_default();
    default_theme.add_resource_path( "/com/github/phase1geo/annotator/images" );

    /* Create the main window */
    appwin = new MainWindow( this );

    /* Attempt to paste from the clipboard */
    if( use_clipboard ) {
      appwin.do_paste();
    } else if( screenshot_type != CaptureType.NONE ) {
      appwin.do_screenshot( screenshot_type, true, screenshot_delay, screenshot_incwin );
    }

    /* Handle any changes to the position of the window */
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

  }

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    hold();
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      appwin.notification( _( "Opening file" ), file );
      appwin.open_file( file );
    }
    Gtk.main();
    release();
  }

  /* Called if we have no files to open */
  protected override void activate() {
    hold();
    Gtk.main();
    release();
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context     = new OptionContext( "- Annotator Options" );
    var options     = new OptionEntry[6];
    var screenshot  = "";
    string[] sshots = {};

    for( int i=0; i<CaptureType.NUM; i++ ) {
      var type = (CaptureType)i;
      sshots += type.to_string();
    }

    var sshot_type = "(" + string.joinv( "|", sshots ) + ")";

    /* Create the command-line options */
    options[0] = {"version",                 0, 0, OptionArg.NONE,   ref show_version,      _( "Display version number." ), null};
    options[1] = {"use-clipboard",           0, 0, OptionArg.NONE,   ref use_clipboard,     _( "Annotate clipboard image." ), null};
    options[2] = {"screenshot",              0, 0, OptionArg.STRING, ref screenshot,        _( "Take and annotate a screenshot." ), sshot_type};
    options[3] = {"screenshot-delay",        0, 0, OptionArg.INT,    ref screenshot_delay,  _( "Delay (in seconds) before screenshot capture occurs.  Only valid when --screenshot is set.  Default is 0." ), "INT"};
    options[4] = {"screenshot-include-win",  0, 0, OptionArg.NONE,   ref screenshot_incwin, _( "Include Annotator window in screenshot.  Only valid when --screenshot is set." ), null};
    options[5] = {null};

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

    /* Convert and check the screenshot option */
    if( screenshot != "" ) {
      screenshot_type = CaptureType.parse( screenshot );
      if( screenshot_type == CaptureType.NONE ) {
        stdout.printf( "\nERROR: --screenshot=%s is not a supported type\n\n", screenshot );
        stdout.printf( "    Run '%s --help to see valid options\n\n", args[0] );
        Process.exit( 1 );
      }
    }

  }

  /* Creates the home directory and returns it */
  public static string get_home_dir() {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "annotator" );
    DirUtils.create_with_parents( dir, 0775 );
    return( dir );
  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {

    var app = new Annotator();
    app.parse_arguments( ref args );

    return( app.run( args ) );

  }

}

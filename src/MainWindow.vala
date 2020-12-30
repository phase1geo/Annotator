/*
* Copyright (c) 2020 (https://github.com/phase1geo/Annotator)
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
using Gee;

public class MainWindow : ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private HeaderBar  _header;
  private FontButton _font;
  private Canvas     _canvas;
  private Button     _open_btn;
  private Box        _box;
  private Editor?    _editor = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_open",       do_open },
    { "action_save",       do_save },
    { "action_quit",       do_quit },
    { "action_undo",       do_undo },
    { "action_redo",       do_redo }
  };

  /* Constructor */
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/annotator/css/style.css" );
    StyleContext.add_provider_for_screen( Gdk.Screen.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    _box = new Box( Orientation.HORIZONTAL, 0 );

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    /* Position the window size and position */
    position_window();

    /* Create the header */
    create_header();

    add( _box );
    show_all();

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Handle the application closing */
    destroy.connect( Gtk.main_quit );

  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {
    app.set_accels_for_action( "win.action_open",       { "<Control>o" } );
    app.set_accels_for_action( "win.action_save",       { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",       { "<Control>q" } );
    app.set_accels_for_action( "win.action_undo",       { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",       { "<Control><Shift>z" } );
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var lookup = SettingsSchemaSource.get_default().lookup( DESKTOP_SCHEMA, false );
    if( lookup != null ) {
      var desktop_settings = new GLib.Settings( DESKTOP_SCHEMA );
      change_dark_mode( desktop_settings.get_boolean( DARK_KEY ) );
      desktop_settings.changed.connect(() => {
        change_dark_mode( desktop_settings.get_boolean( DARK_KEY ) );
      });
    }
  }

  /* Sets the dark mode to the preferred scheme */
  private void change_dark_mode( bool dark ) {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = dark;
    }
  }

  /* Positions the window based on the settings */
  private void position_window() {

    var window_x = Annotator.settings.get_int( "window-x" );
    var window_y = Annotator.settings.get_int( "window-y" );
    var window_w = Annotator.settings.get_int( "window-w" );
    var window_h = Annotator.settings.get_int( "window-h" );

    /* Set the main window data */
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    set_border_width( 2 );

  }

  /* Create the header bar */
  private void create_header() {

    _header = new HeaderBar();
    _header.set_show_close_button( true );

    _open_btn = new Button.from_icon_name( "document-open", IconSize.LARGE_TOOLBAR );
    _open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open Image" ), "<Control>o" ) );
    _open_btn.clicked.connect( do_open );
    _header.pack_start( _open_btn );

    /*
    _save_btn = new Button.from_icon_name( "document-save", IconSize.LARGE_TOOLBAR );
    _save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File" ), "<Control>s" ) );
    _save_btn.clicked.connect( do_save );
    _header.pack_start( _save_btn );

    _paste_btn = new Button.from_icon_name( "edit-paste", IconSize.LARGE_TOOLBAR );
    _paste_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Paste Over" ), "<Shift><Control>v" ) );
    _paste_btn.clicked.connect( do_paste_over );
    _header.pack_start( _paste_btn );

    _copy_btn = new Button.from_icon_name( "edit-copy", IconSize.LARGE_TOOLBAR );
    _copy_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Copy All" ), "<Shift><Control>c" ) );
    _copy_btn.clicked.connect( do_copy_all );
    _header.pack_start( _copy_btn );

    _undo_btn = new Button.from_icon_name( "edit-undo", IconSize.LARGE_TOOLBAR );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( "edit-redo", IconSize.LARGE_TOOLBAR );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );
    */

    set_titlebar( _header );
    set_title( _( "Annotator" ) );

  }

  /* Create font selection box */
  private Box create_font_selection() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Font:" ) );

    _font = new FontButton();
    _font.show_style = false;
    _font.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    _font.font_set.connect(() => {
      var name = _font.get_font_family().get_name();
      var size = _font.get_font_size() / Pango.SCALE;
      // TBD - _editor.change_name_font( name, size );
      Annotator.settings.set_string( "default-font-family", name );
      Annotator.settings.set_int( "default-font-size", size );
    });

    /* Set the font button defaults */
    var fd = _font.get_font_desc();
    fd.set_family( Annotator.settings.get_string( "default-font-family" ) );
    fd.set_size( Annotator.settings.get_int( "default-font-size" ) * Pango.SCALE );
    _font.set_font_desc( fd );

    box.pack_start( lbl,   false, false, 10 );
    box.pack_end(   _font, false, false, 10 );

    return( box );

  }

  private void do_open() {

    /* Get the file to open from the user */
    var dialog   = new FileChooserNative( _( "Open Image File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );
    Utils.set_chooser_folder( dialog );

    /* Create file filters */
    var filter = new FileFilter();
    filter.set_filter_name( "PNG" );
    filter.add_pattern( "*.png" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      var filename = dialog.get_filename();
      _editor = new Editor( this, filename );
      _box.pack_start( _editor, true, true, 0 );
      _box.show_all();
      Utils.store_chooser_folder( filename );
    }

  }

  private void do_save() {

    /* TBD */

  }

  /* Quits the application */
  private void do_quit() {
    destroy();
  }

  /* Performs an undo operation */
  private void do_undo() {
    /* TBD
    _editor.undo_buffer.undo();
    _editor.grab_focus();
    */
  }

  /* Performs a redo operation */
  private void do_redo() {
    /* TBD
    _editor.undo_buffer.redo();
    _editor.grab_focus();
    */
  }

  /* Generate a notification */
  public void notification( string title, string msg, NotificationPriority priority = NotificationPriority.NORMAL ) {
    GLib.Application? app = null;
    @get( "application", ref app );
    if( app != null ) {
      var notification = new Notification( title );
      notification.set_body( msg );
      notification.set_priority( priority );
      app.send_notification( "com.github.phase1geo.minder", notification );
    }
  }

}


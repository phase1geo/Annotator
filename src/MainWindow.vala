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
using Gee;

public class MainWindow : Gtk.ApplicationWindow {

  private FontButton        _font;
  private Button            _open_btn;
  private Button            _screenshot_btn;
  private Button            _undo_btn;
  private Button            _redo_btn;
  private MenuButton        _pref_btn;
  private MenuButton        _export_btn;
  private MenuButton        _zoom_btn;
  private ZoomWidget        _zoom;
  private Box               _box;
  private Editor            _editor;
  private Stack             _stack;
  private SList<FileFilter> _image_filters;
  private StickerSet        _sticker_set;

  private const GLib.ActionEntry[] action_entries = {
    { "action_open",            do_open },
    { "action_screenshot",      do_screenshot },
    { "action_save",            do_save },
    { "action_quit",            do_quit },
    { "action_undo",            do_undo },
    { "action_redo",            do_redo },
    { "action_copy",            do_copy },
    { "action_cut",             do_cut },
    { "action_paste",           do_paste },
    { "action_zoom_in",         do_zoom_in },
    { "action_zoom_out",        do_zoom_out },
    { "action_zoom_actual",     do_zoom_actual },
    { "action_zoom_fit",        do_zoom_fit },
    { "action_shortcuts",       do_shortcuts },
    { "action_contextual_menu", do_contextual_menu },
    { "action_print",           do_print },
    { "action_emoji",           do_emoji }
  };

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

  public Editor editor {
    get {
      return( _editor );
    }
  }
  public StickerSet sticker_set {
    get {
      return( _sticker_set );
    }
  }
  public SList<FileFilter> image_filters {
    get {
      return( _image_filters );
    }
  }

  /* Constructor */
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/annotator/css/style.css" );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    var box = new Box( Orientation.HORIZONTAL, 0 );

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    can_focus = true;

    /* Create the sticker set */
    _sticker_set = new StickerSet();

    /* Create editor */
    create_editor( box );

    /* Create the header */
    create_header();

    child = box;
    show();

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Gather the image filters */
    gather_image_filters();

    /* Load the exports */
    _editor.canvas.image.exports.load();

    close_request.connect(() => {
      save_window_size();
      return( false );
    });

    /* Set the window size based on saved settings */
    set_window_size();

  }

  /* Returns the name of the icon to use for a headerbar icon */
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {
    app.set_accels_for_action( "win.action_open",            { "<Control>o" } );
    app.set_accels_for_action( "win.action_screenshot",      { "<Control>t" } );
    app.set_accels_for_action( "win.action_save",            { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",            { "<Control>q" } );
    app.set_accels_for_action( "win.action_undo",            { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",            { "<Control><Shift>z" } );
    app.set_accels_for_action( "win.action_copy",            { "<Control>c" } );
    app.set_accels_for_action( "win.action_cut",             { "<Control>x" } );
    app.set_accels_for_action( "win.action_paste",           { "<Control>v" } );
    app.set_accels_for_action( "win.action_zoom_in",         { "<Control>plus" } );
    app.set_accels_for_action( "win.action_zoom_in",         { "<Control>equal" } );
    app.set_accels_for_action( "win.action_zoom_out",        { "<Control>minus" } );
    app.set_accels_for_action( "win.action_zoom_actual",     { "<Control>0" } );
    app.set_accels_for_action( "win.action_zoom_fit",        { "<Control>1" } );
    app.set_accels_for_action( "win.action_shortcuts",       { "<Control>question" } );
    app.set_accels_for_action( "win.action_contextual_menu", { "<Shift>F10", "Menu" } );
    app.set_accels_for_action( "win.action_print",           { "<Control>p" } );
    app.set_accels_for_action( "win.action_emoji",           { "<Control>slash" } );
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var granite_settings = Granite.Settings.get_default();
    var gtk_settings     = Gtk.Settings.get_default();
    gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    granite_settings.notify["prefers-color-scheme"].connect (() => {
      gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    });
  }

  /* Create the header bar */
  private void create_header() {

    var header = new HeaderBar() {
      show_title_buttons = true,
      title_widget = new Gtk.Label( _( "Annotator" ) )
    };
    set_titlebar( header );

    _open_btn = new Button.from_icon_name( get_icon_name( "document-open" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Open Image" ), "<Control>o" )
    };
    _open_btn.clicked.connect( do_open );
    header.pack_start( _open_btn );

    _screenshot_btn = new Button.from_icon_name( get_icon_name( "insert-image" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Take Screeshot" ), "<Control>t" )
    };
    _screenshot_btn.clicked.connect( do_screenshot );
    header.pack_start( _screenshot_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ),
      sensitive = false
    };
    _undo_btn.clicked.connect( do_undo );
    header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ),
      sensitive = false
    };
    _redo_btn.clicked.connect( do_redo );
    header.pack_start( _redo_btn );

    _pref_btn = create_preferences();
    header.pack_end( _pref_btn );

    _export_btn = create_exports();
    header.pack_end( _export_btn );

    _zoom_btn = create_zoom();
    header.pack_end( _zoom_btn );

  }

  private MenuButton create_preferences() {

    var pref_btn = new MenuButton() {
      has_frame    = false,
      child        = new Image.from_icon_name( get_icon_name( "open-menu" ) ),
      tooltip_text = _( "Properties" ),
      popover      = new Popover()
    };

    var box = new Box( Orientation.VERTICAL, 0 );

    var shortcuts = new Button.with_label( _( "Shortcuts Cheatsheet" ) ) {
      has_frame = false
    };
    shortcuts.clicked.connect(() => {
      do_shortcuts();
      pref_btn.popover.popdown();
    });

    box.append( shortcuts );

    pref_btn.popover.child = box;

    return( pref_btn );

  }

  /* Create the exports menubutton and associated menu */
  private MenuButton create_exports() {

    var box = new Box( Orientation.VERTICAL, 0 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var popover = new Popover() {
      autohide = true,
      child    = box
    };

    /* Add the export UI */
    var export_ui = new Exporter( this );
    box.append( export_ui );

    /* Copy to clipboard option */
    var clip_btn = Utils.make_menu_item( _( "Copy To Clipboard" ) );
    clip_btn.clicked.connect(() => {
      _editor.canvas.image.export_clipboard();
      popover.popdown();
    });
    box.append( clip_btn );

    /* Print option */
    var print_btn = Utils.make_menu_item( _( "Print…" ) );
    print_btn.clicked.connect(() => {
      do_print();
      popover.popdown();
    });
    box.append( print_btn );

    var export_btn = new MenuButton() {
      has_frame    = false,
      child        = new Image.from_icon_name( (on_elementary ? "document-export" : "document-send-symbolic") ),
      sensitive    = false,
      tooltip_text = _( "Export Image" ),
      popover      = popover
    };

    return( export_btn );

  }

  /* Creates the zoom menu */
  private MenuButton create_zoom() {

    var box = new Box( Orientation.VERTICAL, 0 );

    var popover = new Popover() {
      autohide = true,
      child = box
    };

    /* Add the button */
    var zoom_btn = new MenuButton() {
      has_frame    = false,
      icon_name    = get_icon_name( "zoom-fit-best" ),
      tooltip_text = _( "Zoom (%d%%)" ).printf( 100 ),
      sensitive    = false,
      popover      = popover
    };

    _zoom = new ZoomWidget( (int)(_editor.canvas.zoom_min * 100), (int)(_editor.canvas.zoom_max * 100), (int)(_editor.canvas.zoom_step * 100) ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    _zoom.zoom_changed.connect((factor) => {
      _editor.canvas.zoom_set( factor );
    });

    var zoom_fit = new Button.with_label( _( "Zoom to Fit Window" ) ) {
      has_frame = false,
      action_name = "win.action_zoom_fit"
    };

    box.append( _zoom );
    box.append( zoom_fit );

    zoom_btn.popover.child = box;

    return( zoom_btn );

  }

  private void create_editor( Box box ) {

    /* Create the welcome screen */
    var welcome = new Granite.Placeholder( _( "Welcome to Annotator" ) ) {
      description = _( "Let's get started annotating an image" )
    };

    var open = welcome.append_button( new ThemedIcon( "document-open" ), _( "Open Image From File" ), _( "Open a PNG, JPEG, TIFF or BMP file" ) );
    open.clicked.connect( do_open );

    var paste = welcome.append_button( new ThemedIcon( "edit-paste" ), _( "Paste Image From Clipboard" ), _( "Open an image from the clipboard" ) );
    paste.clicked.connect( do_paste );

    var screenshot = welcome.append_button( new ThemedIcon( "insert-image" ), _( "Take A Screenshot" ), _( "Open an image from a screenshot" ) );
    screenshot.clicked.connect( do_screenshot );

    /* Initialize the clipboard */
    AnnotatorClipboard.get_clipboard().changed.connect(() => {
      paste.sensitive = AnnotatorClipboard.image_pasteable();
    });

    /* Create the editor */
    _editor = new Editor( this );
    _editor.image_loaded.connect(() => {
      _stack.visible_child_name = "editor";
    });
    _editor.canvas.undo_buffer.buffer_changed.connect( do_undo_changed );
    _editor.canvas.undo_text.buffer_changed.connect( do_undo_changed );
    _editor.canvas.zoom_changed.connect( do_zoom_changed );

    /* Add the elements to the stack */
    _stack = new Stack() {
      transition_type = StackTransitionType.NONE
    };
    _stack.add_named( welcome, "welcome" );
    _stack.add_named( _editor,  "editor" );

    box.append( _stack );

    _stack.visible_child_name = "welcome";

  }

  /* Create font selection box */
  private Box create_font_selection() {

    var box = new Box( Orientation.HORIZONTAL, 10 );
    var lbl = new Label( _( "Font:" ) ) {
      halign = Align.START
    };

    _font = new FontButton() {
      halign  = Align.END,
      hexpand = true
    };
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

    box.append( lbl );
    box.append( _font );

    return( box );

  }

  /* Creates a list of image filters that can be used in the open dialog */
  private void gather_image_filters() {

    _image_filters = new SList<FileFilter>();

    string[] patterns = {};

    foreach( Gdk.PixbufFormat format in Gdk.Pixbuf.get_formats() ) {
      var filter = new FileFilter();
      filter.set_filter_name( format.get_description() + "  (" + format.get_name() + ")" );
      foreach( string ext in format.get_extensions() ) {
        var pattern = "*" + ext;
        filter.add_pattern( pattern );
        patterns += pattern;
      }
      _image_filters.append( filter );
    }

    /* Add the 'all image formats' filter first */
    var filter = new FileFilter();
    filter.set_filter_name( _( "All Image Formats  (*)" ) );
    foreach( string pattern in patterns ) {
      filter.add_pattern( pattern );
    }
    _image_filters.prepend( filter );

  }

  /* Opens an image file for loading */
  private void do_open() {

    /* Get the file to open from the user */
    var dialog = new FileChooserNative( _( "Open Image File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );
    Utils.set_chooser_folder( dialog );

    /* Create file filters for each supported format */
    foreach( FileFilter filter in _image_filters ) {
      dialog.add_filter( filter );
    }

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var filename = dialog.get_file().get_path();
        open_file( filename );
        Utils.store_chooser_folder( filename );
      }
      dialog.destroy();
    });

    dialog.show();

  }

  /*
   Opens the given image file in the canvas and displays the canvas if the
   image is successfully read and displayed.
  */
  public void open_file( string filename ) {
    _editor.open_image( filename );
    _zoom_btn.set_sensitive( true );
    _export_btn.set_sensitive( true );
  }

  /* Parses image data from standard output to use as pixbuf */
  public bool handle_standard_input() {
    var max_size  = Annotator.settings.get_int( "maximum-image-size" ) * (1 << 20);
    var buf       = new uint8[max_size];
    var read_size = stdin.read( buf );
    if( read_size > 0 ) {
      var stream = new MemoryInputStream.from_data( buf, GLib.free );
      try {
        var pixbuf = new Gdk.Pixbuf.from_stream( stream );
        _editor.paste_image( pixbuf, true );
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
        return( true );
      } catch( Error e ) {}
    }
    return( false );
  }

  /* Copies the relevant part of the currently selected item (if it exists) */
  public void do_copy() {
    _editor.canvas.do_copy();
  }

  /* Cuts the relevant part of the currently selected item (if it exists) */
  public void do_cut() {
    _editor.canvas.do_cut();
  }

  /* Pastes text or images to the editor */
  public void do_paste() {
    AnnotatorClipboard.paste( _editor );
    _zoom_btn.set_sensitive( true );
    _export_btn.set_sensitive( true );
  }

  public void do_screenshot() {

    var portal = new Xdp.Portal();
    var parent = Xdp.parent_new_gtk( this );

    hide();

    try {
      portal.take_screenshot.begin( parent, Xdp.ScreenshotFlags.INTERACTIVE, null, (obj, res) => {
        var screenshot = portal.take_screenshot.end( res );
        var file       = File.new_for_uri( screenshot );
        _editor.open_image( file.get_path() );
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
        show();
      });
    } catch( Error e ) {
      stderr.printf( "ERROR: %s\n", e.message );
      show();
    }

  }

  private void do_save() {

    /* TBD */

  }

  /* Save the window size to settings */
  private void save_window_size() {
    Annotator.settings.set_int( "window-w", get_width() );
    Annotator.settings.set_int( "window-h", get_height() );
  }

  /* Restore window size from settings */
  private void set_window_size() {
    var size_w = Annotator.settings.get_int( "window-w" );
    var size_h = Annotator.settings.get_int( "window-h" );
    set_default_size( size_w, size_h );
  }

  /* Quits the application */
  private void do_quit() {
    save_window_size();
    destroy();
  }

  /* Performs an undo operation */
  private void do_undo() {
    _editor.canvas.do_undo();
  }

  /* Performs a redo operation */
  private void do_redo() {
    _editor.canvas.do_redo();
  }

  /* Zooms in by one */
  private void do_zoom_in() {
    _editor.canvas.zoom_in();
  }

  /* Zooms out by one */
  private void do_zoom_out() {
    _editor.canvas.zoom_out();
  }

  /* Zooms to 1:1 */
  private void do_zoom_actual() {
    _editor.canvas.zoom_actual();
  }

  /* Zooms in/out to fit image to window width */
  private void do_zoom_fit() {
    _editor.canvas.zoom_fit();
  }

  /* Displays the keyboard shortcuts cheatsheet */
  private void do_shortcuts() {

    var builder = new Builder.from_resource( "/com/github/phase1geo/annotator/shortcuts/shortcuts.ui" );
    var win     = builder.get_object( "shortcuts" ) as ShortcutsWindow;

    win.transient_for = this;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( _editor.canvas.items.in_edit_mode() ) {
      win.section_name = "text-editing";
    } else if( _editor.canvas.items.is_item_selected() ) {
      win.section_name = "items";
    } else {
      win.section_name = "general";
    }

    win.show();

  }

  /* Displays the contextual menu for the item under the cursor */
  private void do_contextual_menu() {
    _editor.canvas.show_contextual_menu();
  }

  /* Performs an image export */
  public void do_export( string type, string filename ) {
    _editor.canvas.image.export_image( type, filename );
  }

  /* Prints the current image */
  private void do_print() {
    _editor.canvas.image.export_print();
  }

  private void do_emoji() {
    _editor.canvas.insert_emoji();
  }

  /* Called whenever the undo buffer changes */
  private void do_undo_changed( UndoBuffer buffer ) {
    _undo_btn.set_sensitive( buffer.undoable() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buffer.undo_tooltip(), "<Control>z" ) );
    _redo_btn.set_sensitive( buffer.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buffer.redo_tooltip(), "<Control><Shift>z" ) );
  }

  /* Called whenever the zoom value changes */
  private void do_zoom_changed( double zoom_factor ) {
    _zoom.value = (int)(zoom_factor * 100);
    _zoom_btn.set_tooltip_text( _( "Zoom (%d%%)" ).printf( (int)_zoom.value ) );
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


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

  private Granite.Placeholder _welcome;
  private FontButton          _font;
  private Button              _open_btn;
  private Button              _screenshot_btn;
  private Button              _undo_btn;
  private Button              _redo_btn;
  private MenuButton          _pref_btn;
  private MenuButton          _export_btn;
  private MenuButton          _zoom_btn;
  private ZoomWidget          _zoom;
  private Box                 _box;
  private Editor              _editor;
  private Stack               _stack;
  private SList<FileFilter>   _image_filters;
  private StickerSet          _sticker_set;

  private const GLib.ActionEntry[] action_entries = {
    { "action_open",              do_open },
    { "action_screenshot",           action_screenshot },
    { "action_screenshot_nonportal", action_screenshot_nonportal, "i" },
    { "action_save",              do_save },
    { "action_quit",              do_quit },
    { "action_undo",              do_undo },
    { "action_redo",              do_redo },
    { "action_copy",              do_copy },
    { "action_cut",               do_cut },
    { "action_paste",             do_paste },
    { "action_zoom_in",           do_zoom_in },
    { "action_zoom_out",          do_zoom_out },
    { "action_zoom_actual",       do_zoom_actual },
    { "action_zoom_fit",          do_zoom_fit },
    { "action_shortcuts",         do_shortcuts },
    { "action_contextual_menu",   do_contextual_menu },
    { "action_copy_to_clipboard", do_copy_to_clipboard },
    { "action_print",             do_print },
    { "action_emoji",             do_emoji }
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

  public signal void theme_changed( bool dark );

  /* Constructor */
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/annotator/css/style.css" );
    StyleContext.add_provider_for_display( get_display(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    var box = new Box( Orientation.HORIZONTAL, 0 );

    can_focus = true;

    /* Create the sticker set */
    _sticker_set = new StickerSet();

    /* Create editor */
    create_editor( box );

    /* Create the header */
    create_header();

    child = box;

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

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
    update_dark_mode( granite_settings );
    granite_settings.notify["prefers-color-scheme"].connect (() => {
      update_dark_mode( granite_settings );
    });
  }

  /* Updates the current dark mode setting in the UI */
  private void update_dark_mode( Granite.Settings granite_settings ) {
    var gtk_settings = Gtk.Settings.get_default();
    gtk_settings.gtk_application_prefer_dark_theme = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    theme_changed( gtk_settings.gtk_application_prefer_dark_theme );
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
      tooltip_markup = Utils.tooltip_with_accel( _( "Take Screenshot" ), "<Control>t" )
    };
    _screenshot_btn.clicked.connect(() => {
      do_screenshot( _screenshot_btn );
    });
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

    var menu = new GLib.Menu();
    menu.append( _( "Shortcuts Cheatsheet…" ), "win.action_shortcuts" );

    var pref_btn = new MenuButton() {
      has_frame    = !on_elementary,
      child        = new Image.from_icon_name( get_icon_name( "open-menu" ) ),
      tooltip_text = _( "Properties" ),
      menu_model   = menu
    };

    return( pref_btn );

  }

  //-------------------------------------------------------------
  // Create the exports menubutton and associated menu.
  private MenuButton create_exports() {

    /* Add the export UI */
    var export_ui = new Exporter( this );
    var export_mi = new GLib.MenuItem( null, null );
    export_mi.set_attribute( "custom", "s", "export" );

    var export_menu = new GLib.Menu();
    export_menu.append_item( export_mi );

    var other_menu = new GLib.Menu();
    other_menu.append( _( "Copy To Clipboard" ), "win.action_copy_to_clipboard" );
    other_menu.append( _( "Print…" ), "win.action_print" );

    var menu = new GLib.Menu();
    menu.append_section( null, export_menu );
    menu.append_section( null, other_menu );

    var popover = new PopoverMenu.from_model( menu ) {
      cascade_popdown = false
    };
    popover.add_child( export_ui, "export" );

    export_ui.export_started.connect(() => {
      popover.popdown();
    });

    var export_btn = new MenuButton() {
      has_frame    = !on_elementary,
      child        = new Image.from_icon_name( (on_elementary ? "document-export" : "document-send-symbolic") ),
      sensitive    = false,
      tooltip_text = _( "Export Image" ),
      popover      = popover
    };

    return( export_btn );

  }

  //-------------------------------------------------------------
  // Creates the zoom menu.
  private MenuButton create_zoom() {

    _zoom = new ZoomWidget( (int)(_editor.canvas.zoom_min * 100), (int)(_editor.canvas.zoom_max * 100), (int)(_editor.canvas.zoom_step * 100) ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };

    _zoom.zoom_changed.connect((factor) => {
      _editor.canvas.zoom_set( factor );
    });

    var zoom_mi = new GLib.MenuItem( null, null );
    zoom_mi.set_attribute( "custom", "s", "zoom" );

    var menu = new GLib.Menu();
    menu.append_item( zoom_mi );
    menu.append( _( "Zoom to Fit Window" ), "win.action_zoom_fit" );

    var zoom_popover = new PopoverMenu.from_model( menu );
    zoom_popover.add_child( _zoom, "zoom" );

    /* Add the button */
    var zoom_btn = new MenuButton() {
      icon_name    = get_icon_name( "zoom-fit-best" ),
      tooltip_text = _( "Zoom (%d%%)" ).printf( 100 ),
      sensitive    = false,
      popover      = zoom_popover
    };

    return( zoom_btn );

  }

  private void create_editor( Box box ) {

    /* Create the welcome screen */
    _welcome = new Granite.Placeholder( _( "Welcome to Annotator" ) ) {
      vexpand = true,
      description = _( "Let's get started annotating an image" )
    };

    var welcome_box = new Box( Orientation.VERTICAL, 0 ) {
      halign = Align.FILL,
      valign = Align.FILL
    };
    welcome_box.append( _welcome );

    var drop = new DropTarget( typeof(GLib.File), Gdk.DragAction.COPY );
    welcome_box.add_controller( drop );

    drop.drop.connect((val, x, y) => {
      var file = (val as GLib.File);
      if( file != null ) {
        uint8[] contents = {};
        try {
          if( file.load_contents( null, out contents, null ) &&
              GLib.ContentType.guess( null, contents, null ).contains( "image" ) ) {
            open_file( file.get_path() );
            return( true );
          }
        } catch( Error e ) {}
      }
      return( false );
    });

    var open = _welcome.append_button( new ThemedIcon( "document-open" ), _( "Open Image From File" ), _( "Open a PNG, JPEG, TIFF, BMP or Annotator file" ) );
    open.clicked.connect( do_open );

    var paste = _welcome.append_button( new ThemedIcon( "edit-paste" ), _( "Paste Image From Clipboard" ), _( "Open an image from the clipboard" ) );
    paste.clicked.connect( do_paste );

    var screenshot = _welcome.append_button( new ThemedIcon( "insert-image" ), _( "Take A Screenshot" ), _( "Open an image from a screenshot" ) );
    screenshot.clicked.connect(() => {
      do_screenshot( screenshot );
    });

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
    _stack.add_named( welcome_box, "welcome" );
    _stack.add_named( _editor,     "editor" );

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

    var afilter = new FileFilter();
    afilter.set_filter_name( _( "Annotator" ) );
    afilter.add_pattern( "*.annotator" );
    patterns += "*.annotator";
    _image_filters.append( afilter );

    /* Add the 'all image formats' filter first */
    var filter = new FileFilter();
    filter.set_filter_name( _( "All Loadable Formats" ) );
    foreach( string pattern in patterns ) {
      filter.add_pattern( pattern );
    }
    _image_filters.prepend( filter );

  }

  /* Opens an image file for loading */
  private void do_open() {

    _welcome.sensitive = false;

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
      } else {
        _welcome.sensitive = true;
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
    var opened = false;
    if( filename.has_suffix( ".annotator" ) ) {
      var export = (_editor.canvas.image.exports.get_by_name( "annotator" ) as ExportEditable);
      if( export != null ) {
        opened = export.import( filename );
      }
    } else {
      opened = _editor.open_image( filename );
    }
    if( opened ) {
      _zoom_btn.set_sensitive( true );
      _export_btn.set_sensitive( true );
    }
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

  /* Pastes clipboard contents to the editor.  This may also paste only images, if specified. */
  private bool do_paste_internal( bool image_only ) {
    if( AnnotatorClipboard.paste( _editor, image_only ) ) {
      _welcome.sensitive = false;
      _zoom_btn.set_sensitive( true );
      _export_btn.set_sensitive( true );
      return( true );
    }
    return( false );
  }

  /* Pastes text, images or items to the editor */
  public void do_paste() {
    do_paste_internal( false );
  }

  /* Pasts only an image from the clipboard to the editor */
  public bool do_paste_image() {
    return( do_paste_internal( true ) );
  }

  //-------------------------------------------------------------
  // Main procedure that initiates a screenshot.  If the backend
  // indicates that it can handle taking the screenshot, use the
  // backend to perform the screenshot; otherwise, use the portal.
  public void do_screenshot( Widget? parent ) {
    /*
    if( ScreenshotBackend.can_do_screenshots() ) {
      if( parent == null ) {
        do_screenshot_nonportal( CaptureType.SCREEN );
      } else {
        show_screenshot_popover( parent );
      }
    } else {
    */
      do_screenshot_portal();
    /*
    }
    */
  }

  //-------------------------------------------------------------
  // Returns the capture mode as determined by the user
  private void show_screenshot_popover( Widget parent ) {

    var shot_menu = new GLib.Menu();

    for( int i=0; i<CaptureType.NUM; i++ ) {
      var mode = (CaptureType)i;
      shot_menu.append( mode.label(), "win.action_screenshot_nonportal(%d)".printf( i ) );
    }

    var opt_menu = new GLib.Menu();

    var delay_item = new GLib.MenuItem( null, null );
    delay_item.set_attribute( "custom", "s", "delay" );
    opt_menu.append_item( delay_item );

    var delay = new Label( _( "Delay (in seconds)" ) + ":" ) {
      halign  = Align.START,
      hexpand = true
    };
    var delay_sb = new SpinButton.with_range( 0, 6, 1 ) {
      halign = Align.END,
      valign = Align.CENTER
    };
    delay_sb.value = Annotator.settings.get_int( "screenshot-delay" );
    delay_sb.value_changed.connect(() => {
      Annotator.settings.set_int( "screenshot-delay", (int)delay_sb.value );
    });

    var dbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start = 10,
      margin_end   = 10
    };
    dbox.append( delay );
    dbox.append( delay_sb );

    var include_item = new GLib.MenuItem( null, null );
    include_item.set_attribute( "custom", "s", "include" );
    opt_menu.append_item( include_item );

    var include = new Label( _( "Include Annotator window" ) + ":" ) {
      halign  = Align.START,
      hexpand = true
    };
    var include_sw = new Switch() {
      halign = Align.END,
      valign = Align.CENTER,
      active = Annotator.settings.get_boolean( "screenshot-include-win" )
    };
    include_sw.notify["active"].connect((value) => {
      Annotator.settings.set_boolean( "screenshot-include-win", include_sw.active );
    });

    var ibox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_top   = 10,
      margin_start = 10,
      margin_end   = 10
    };
    ibox.append( include );
    ibox.append( include_sw );

    var menu = new GLib.Menu();
    menu.append_section( null, shot_menu );
    menu.append_section( null, opt_menu );

    var popover = new PopoverMenu.from_model( menu ) {
      position = PositionType.BOTTOM
    };
    popover.set_parent( parent );
    popover.add_child( dbox, "delay" );
    popover.add_child( ibox, "include" );
    popover.popup();

  }

  private void action_screenshot() {
    do_screenshot( _screenshot_btn );
  }

  private void action_screenshot_nonportal( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var mode = (CaptureType)variant.get_int32();
      do_screenshot_nonportal( mode );
    }
  }

  public void do_screenshot_nonportal( CaptureType capture_mode ) {

    /* If we aren't capturing anything, end now */
    if( capture_mode == CaptureType.NONE ) return;

    var backend = new ScreenshotBackend();
    var delay   = Annotator.settings.get_int( "screenshot-delay" );
    var include = Annotator.settings.get_boolean( "screenshot-include-win" );

    /* Hide the application */
    if( !include ) {
      hide();
    }

    backend.capture.begin (capture_mode, delay, false, false /* redact */, (obj, res) => {
      Gdk.Pixbuf? pixbuf = null;
      try {
        pixbuf = backend.capture.end (res);
      } catch (GLib.IOError.CANCELLED e) {
        // TBD
      } catch (Error e) {
        // TBD
      }
      if (pixbuf != null) {
        _editor.paste_image( pixbuf, false );
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
      }
      if( !include ) {
        show();
      }
    });

  }

  //-------------------------------------------------------------
  // Generate a screenshot using the screenshot portal.
  /*
  private void do_screenshot_portal() {

    _welcome.sensitive = false;

    var portal = new Xdp.Portal();
    var parent = Xdp.parent_new_gtk( this );

    hide();

    portal.take_screenshot.begin( parent, Xdp.ScreenshotFlags.INTERACTIVE, null, (obj, res) => {
      try {
        var screenshot = portal.take_screenshot.end( res );
        var file       = File.new_for_uri( screenshot );
        _editor.open_image( file.get_path() );
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
        show();
      } catch( Error e ) {
        _welcome.sensitive = true;
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
        show();
      }
    });

  }
  */

  private async void do_screenshot_portal() {
    _welcome.sensitive = false;
    try {

      var bus = Bus.get_sync (BusType.SESSION);

      var proxy = new DBusProxy.sync (
                bus,
                DBusProxyFlags.NONE,
                null,
                "org.freedesktop.portal.Desktop",
                "/org/freedesktop/portal/desktop",
                "org.freedesktop.portal.Screenshot",
                null
      );

      VariantDict options = new VariantDict( new Variant( "a{sv}" ) );
      options.insert_value ("interactive", new Variant.boolean (true));

      Variant dict_variant = options.end ();
      Variant tuple_variant = new Variant ("(s@a{sv})", "interactive", dict_variant);

      Variant result = yield proxy.call(
        "Screenshot",
        tuple_variant,
        DBusCallFlags.NONE,
        -1,
        null
      );

      // Result is (o) → handle path
      ObjectPath handle;
      result.get ("(o)", out handle);

      bus.signal_subscribe(
        "org.freedesktop.portal.Desktop",
        "org.freedesktop.portal.Request",
        "Response",
        handle,
        null,
        DBusSignalFlags.NONE,
        handle_screenshot_callback
      );

    } catch (Error e) {
      warning ("Screenshot failed: %s", e.message);
    }

  }

  private void handle_screenshot_callback(
    DBusConnection connection,
    string? sender_name,
    string object_path,
    string interface_name,
    string signal_name,
    Variant parameters
  ) {

    uint response;
    Variant dict;

    parameters.get ("(u@a{sv})", out response, out dict);

    stdout.printf( "In handle_screenshot_callback, response: %u\n", response );

    if (response != 0) {
      print ("Screenshot cancelled\n");
      _welcome.sensitive = true;
      _zoom_btn.set_sensitive( true );
      _export_btn.set_sensitive( true );
      show();
    } else {
      string uri;
      if (dict.lookup ("uri", "s", out uri)) {
        var file = File.new_for_uri( uri );
        _editor.open_image( file.get_path() );
        _zoom_btn.set_sensitive( true );
        _export_btn.set_sensitive( true );
        show();
      } else {
        stdout.printf( "Bad\n" );
      }
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

  //-------------------------------------------------------------
  // Copies the annotated image to the clipboard.
  private void do_copy_to_clipboard() {
    _editor.canvas.image.export_clipboard();
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


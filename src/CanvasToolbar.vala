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
using Gee;

public class CanvasToolbar : Box {

  private const int margin = 5;

  private Canvas              _canvas;
  private ToggleButton        _crop_btn;
  private Array<CheckButton>  _width_btns;
  private Array<CheckButton>  _dash_btns;
  private ColorDialogButton   _color_chooser;
  private ColorDialogButton   _stroke_color_chooser;
  private Switch              _asw;
  private Revealer            _areveal;
  private Scale               _ascale;
  private int                 _current_shape;
  private HashMap<CanvasItemCategory,CurrentItem> _current_item;
  private bool                _ignore = false;
  private CanvasTool          _current = CanvasTool.SELECTOR;
  private ToolProperties      _props;

  public signal void selected( CanvasTool selected );

  public Canvas canvas {
    get {
      return( _canvas );
    }
  }
  public CanvasTool current {
    get {
      return( _current );
    }
    set {
      if( _current != value ) {
        selected( value );
      }
    }
  }
  public ToolProperties props {
    get {
      return( _props );
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolbar( Canvas canvas ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5 );

    _canvas       = canvas;
    _current_item = new HashMap<CanvasItemCategory,CurrentItem>();

    // Create properties
    _props = new ToolProperties();

    // Create current items
    _current_item.set( CanvasItemCategory.ARROW, new CurrentItem.with_canvas_item( CanvasItemType.ARROW ) );
    _current_item.set( CanvasItemCategory.SHAPE, new CurrentItem.with_canvas_item( CanvasItemType.RECT ) );

    create_selector();
    create_shapes( CanvasItemCategory.ARROW, _( "More Arrows" ), _( "Custom Arrows" ) );
    create_shapes( CanvasItemCategory.SHAPE, _( "More Shapes" ), _( "Custom Shapes" ) );
    create_sticker();
    create_image();
    create_sequence();
    create_pencil();
    create_text();
    create_magnifier();
    create_blur();
    create_separator();
    create_crop();
    create_resize();
    create_dropper();
    create_separator();
    create_drag_label();

    // Select the Selector tool by default
    selected( CanvasTool.SELECTOR );

  }

  //-------------------------------------------------------------
  // Creates the selection tool
  private void create_selector() {

    var granite_settings = Granite.Settings.get_default();
    var dark_mode        = granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

    var button = new CanvasToolButton( this, CanvasTool.SELECTOR ) {
      halign       = Align.START,
      icon_name    = "selection-symbolic",
      tooltip_text = _( "Selection Tool" )
    };

    // If the selection changes, update the toolbar
    /* TBD
    _canvas.items.selection_changed.connect((item) => {
      button.set_props( item.itype, item.props );
    });
    */

    append( button );

  }

  //-------------------------------------------------------------
  // Creates the shape toolbar item
  private void create_shapes( CanvasItemCategory category, string mb_tooltip, string custom_label ) {

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var fb = new FlowBox() {
      orientation = Orientation.HORIZONTAL,
      min_children_per_line = 4,
      max_children_per_line = 4
    };

    var popover = new Popover() {
      child = box
    };

    var btn = new CanvasToolButton( this, ((category == CanvasItemCategory.ARROW) ? CanvasTool.ARROW : CanvasTool.SHAPE), popover ) {
      child = _current_item.get( category ).get_image( _canvas.win )
    };

    /*
    btn.clicked.connect(() => {
      _current_item.get( category ).add_item( _canvas.items );
    });
    */

    for( int i=0; i<CanvasItemType.NUM; i++ ) {
      var shape_type = (CanvasItemType)i;
      if( shape_type.category() == category ) {
        var b = new Button() {
          icon_name     = shape_type.icon_name(),
          has_frame     = false,
          margin_start  = 5,
          margin_end    = 5,
          margin_top    = 5,
          margin_bottom = 5,
          tooltip_markup = shape_type.tooltip(),
        };
        b.clicked.connect(() => {
          _current_item.get( category ).canvas_item( shape_type );
          // _current_item.get( category ).add_item( _canvas.items );
          btn.child = _current_item.get( category ).get_image( _canvas.win );
          popover.popdown();
        });
        fb.append( b );
      }
    }

    box.append( fb );
    _canvas.items.custom_items.create_menu( _canvas.win, category, popover, box, custom_label, 4 );
    _canvas.items.custom_items.item_selected.connect((cat, item) => {
      if( cat == category ) {
        _current_item.get( cat ).custom_item( item );
        _current_item.get( cat ).add_item( _canvas.items );
        btn.child = _current_item.get( cat ).get_image( _canvas.win );
        popover.popdown();
      }
    });

    append( btn );

    // If the system dark mode changes, hide the popover
    _canvas.win.theme_changed.connect((dark_mode) => {
      popover.hide();
    });

  }

  //-------------------------------------------------------------
  // Creates the sticker toolbar item
  private void create_sticker() {

    var popover = new Popover();

    var btn = new CanvasToolButton( this, CanvasTool.STICKER, popover ) {
      icon_name = "sticker-symbolic",
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = box
    };
    sw.set_size_request( 400, 400 );

    create_sticker_set( box, popover );

    popover.child = sw;

    append( btn );

  }

  //-------------------------------------------------------------
  // Creates the rest of the UI from the stickers XML file that
  // is stored in a gresource
  private void create_sticker_set( Box box, Popover popover ) {

    var sticker_set = _canvas.win.sticker_set;

    var categories = sticker_set.get_categories();
    for( int i=0; i<categories.length; i++ ) {
      var category = create_sticker_category( box, categories.index( i ) );
      var icons    = sticker_set.get_category_icons( categories.index( i ) );
      for( int j=0; j<icons.length; j++ ) {
        var icon = icons.index( j );
        create_sticker_image( category, icon, popover );
      }
    }

  }

  //-------------------------------------------------------------
  // Creates the expander flowbox for the given category name and
  // adds it to the sidebar
  private FlowBox create_sticker_category( Box box, string name ) {

    // Create the flowbox which will contain the stickers
    var fbox = new FlowBox() {
      homogeneous = true,
      selection_mode = SelectionMode.NONE,
      min_children_per_line = 4,
      max_children_per_line = 4
    };

    // Create expander
    var exp = new Expander( Utils.make_title( name ) ) {
      margin_start = 20,
      margin_end   = 20,
      margin_top   = 20,
      use_markup   = true,
      expanded     = true,
      child        = fbox
    };

    box.append( exp );

    return( fbox );

  }

  //-------------------------------------------------------------
  // Creates the image from the given name and adds it to the
  // flow box
  private void create_sticker_image( FlowBox box, StickerInfo info, Popover popover ) {

    var buf     = StickerSet.make_pixbuf( info.resource );
    var texture = Gdk.Texture.for_pixbuf( buf );
    var picture = new Picture.for_paintable( texture ) {
      can_shrink = false
    };

    var btn = new Button() {
      has_frame    = false,
      tooltip_text = info.tooltip,
      child        = picture
    };
    btn.clicked.connect((e) => {
      _canvas.items.add_sticker( info.resource );
      popover.popdown();
    });

    box.append( btn );

  }

  //-------------------------------------------------------------
  // Add an image button
  private void create_image() {

    var btn = new CanvasToolButton( this, CanvasTool.IMAGE ) {
      has_frame    = false,
      icon_name    = "insert-image-symbolic",
      margin_start = margin,
      margin_end   = margin
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the sequence button
  private void create_sequence() {

    var btn = new CanvasToolButton( this, CanvasTool.SEQUENCE ) {
      icon_name = "sequence-symbolic",
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Starts a drawing operation with the pencil tool
  private void create_pencil() {

    var btn = new CanvasToolButton( this, CanvasTool.PENCIL ) {
      icon_name = "edit-symbolic",
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the text insertion button
  private void create_text() {

    var btn = new CanvasToolButton( this, CanvasTool.TEXT ) {
      icon_name = "insert-text-symbolic",
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the magnifier button
  private void create_magnifier() {

    var magnifier = CanvasItemType.MAGNIFIER;

    var btn = new CanvasToolButton( this, CanvasTool.MAGNIFIER ) {
      has_frame      = false,
      icon_name      = "magnifier-symbolic",
      tooltip_markup = magnifier.tooltip(),
      margin_start   = margin,
      margin_end     = margin
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Create the blur button
  private void create_blur() {

    var blur = CanvasItemType.BLUR;

    var btn = new CanvasToolButton( this, CanvasTool.BLUR ) {
      icon_name      = "blur-symbolic",
      tooltip_markup = blur.tooltip()
    };

    append( btn );

  }

  //-------------------------------------------------------------
  // Create the crop button
  private void create_crop() {

    _crop_btn = new ToggleButton() {
      icon_name    = "image-crop-symbolic",
      has_frame    = false,
      tooltip_text = _( "Crop Image" ),
      margin_start = margin,
      margin_end   = margin
    };

    _crop_btn.toggled.connect(() => {
      if( !_ignore ) {
        if( !_crop_btn.active ) {
          _canvas.image.cancel_crop();
        } else {
          _canvas.items.clear_selection();
          _canvas.image.start_crop();
        }
        _canvas.items.clear_selection();
        _canvas.queue_draw();
        _canvas.grab_focus();
      }
    });

    append( _crop_btn );

  }

  //-------------------------------------------------------------
  // Create the image resizer button
  private void create_resize() {

    var btn = new Button.from_icon_name( "view-fullscreen-symbolic" ) {
      has_frame    = false,
      tooltip_text = _( "Resize Image" ),
      margin_start = margin,
      margin_end   = margin
    };

    btn.clicked.connect(() => {
      _canvas.items.clear_selection();
      _canvas.image.resize_image();
      _canvas.queue_draw();
      _canvas.grab_focus();
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Creates the color picker
  private void create_dropper() {

    var btn = new Button.from_icon_name( "eyedropper-symbolic" ) {
      has_frame    = false,
      tooltip_text = _( "Pick Color To Clipboard" ),
      margin_start = margin,
      margin_end   = margin
    };
    btn.clicked.connect(() => {
      _canvas.image.pick_color( true );
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Creates a label that we can drag an image from. 
  private void create_drag_label() {

    var drag_label = new Label( "PNG" ) {
      tooltip_text = _( "Drag PNG Image" ),
      margin_start = 20
    };

    var motion = new EventControllerMotion();
    drag_label.add_controller( motion );

    motion.enter.connect((x, y) => {
      var cursor = new Gdk.Cursor.from_name( "grab", null );
      drag_label.set_cursor( cursor );
    });

    motion.leave.connect(() => {
      drag_label.set_cursor( null );
    });

    var click = new GestureClick();
    drag_label.add_controller( click );

    click.pressed.connect((x, y) => {
      var cursor = new Gdk.Cursor.from_name( "grabbing", null );
      drag_label.set_cursor( cursor );
    });

    click.released.connect(() => {
      var cursor = new Gdk.Cursor.from_name( "grab", null );
      drag_label.set_cursor( cursor );
    });

    var drag = new DragSource() {
      actions = Gdk.DragAction.MOVE
    };
    drag_label.add_controller( drag );

    drag.prepare.connect((d) => {
      var val = Value( typeof(GLib.File) );
      var fname = Utils.create_temp_filename( "png" );
      _canvas.win.editor.canvas.image.export_image( "png", fname );
      val = File.new_for_path( fname );
      var cp = new Gdk.ContentProvider.for_value( val );
      return( cp );
    });

    drag.drag_end.connect((d, delete_data) => {
      if( !delete_data ) {
        try {
          var val      = Value( typeof(GLib.File) );
          var provider = d.get_content();
          if( provider.get_value( ref val ) ) {
            var file = (GLib.File)val;
            FileUtils.remove( file.get_path() );
          }
        } catch( Error e ) {}
      }
    });

    append( drag_label );

  }

  private Image make_color_icon() {

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)30, (float)24 );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the image
    var stroke = Granite.contrasting_foreground_color( _canvas.items.props.color );
    Utils.set_context_color_with_alpha( ctx, _canvas.items.props.color, _canvas.items.props.alpha );
    ctx.rectangle( 0, 0, 30, 24 );
    ctx.fill_preserve();

    Utils.set_context_color_with_alpha( ctx, stroke, 0.5 );
    ctx.stroke();

    var image = new Image.from_paintable( snapshot.free_to_paintable( null ) );

    return( image );

  }

  //-------------------------------------------------------------
  // Returns true if the current mode is dark mode
  private bool is_dark_mode() {

    var settings = Gtk.Settings.get_default();
    if( settings != null ) {
      return( settings.gtk_application_prefer_dark_theme );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Creates the width icon
  private Gdk.Paintable make_width_icon( int width, int stroke_width ) {

    var height = stroke_width;

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)width, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the stroke
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( stroke_width );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( snapshot.free_to_paintable( null ) );

    /*
    var image = new Picture.for_paintable( snapshot.free_to_paintable( null ) ) {
      halign      = Align.START,
      hexpand     = true,
      content_fit = ContentFit.SCALE_DOWN,
      can_shrink  = false
    };

    return( image );
    */

  }

  //-------------------------------------------------------------
  // Creates the dash icon
  private Gdk.Paintable make_dash_icon( int width, CanvasItemDashPattern dash ) {

    var height = 5;

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)width, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the image
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( height );
    dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( snapshot.free_to_paintable( null ) );

    /*
    var image = new Picture.for_paintable( snapshot.free_to_paintable( null ) ) {
      halign      = Align.START,
      hexpand     = true,
      content_fit = ContentFit.SCALE_DOWN,
      can_shrink  = false
    };

    return( image );
    */

  }

  //-------------------------------------------------------------
  // Generates an image with a stroke matching the current canvas
  // item.
  private Image make_stroke_icon() {

    var width   = 50;
    var height  = _canvas.items.props.stroke_width.width();

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)50, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the image
    Utils.set_context_color( ctx, _canvas.items.props.stroke_color );
    ctx.set_line_width( height );
    _canvas.items.props.dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    var image = new Image.from_paintable( snapshot.free_to_paintable( null ) );

    return( image );

  }

  //-------------------------------------------------------------
  // Adds a separator to the toolbar
  private void create_separator() {

    var sep = new Separator( Orientation.VERTICAL ) {
      margin_start = 5,
      margin_end   = 5
    };

    append( sep );

  }

  //-------------------------------------------------------------
  // Called when the canvas image crop ends
  public void crop_ended() {
    _crop_btn.active = false;
  }

  //-------------------------------------------------------------
  // Displays the custom menu for the specified item category type
  // relative to the given widget.
  /*
  private void show_custom_menu( Widget w, CanvasItemCategory category ) {

    var fb = new FlowBox();
    fb.orientation = Orientation.HORIZONTAL;
    fb.min_children_per_line = 4;
    fb.max_children_per_line = 4;

    var popover = new Popover( w );
    _canvas.items.custom_items.populate_menu( category, null, popover, fb );

    if( fb.get_children().length() > 0 ) {
      popover.add( fb );
      Utils.show_popover( popover );
    }

  }
  */

}


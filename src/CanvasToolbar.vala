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
  private HashMap<CanvasItemCategory,CurrentItem> _current_item;
  private bool                _ignore = false;
  private CanvasTool          _current = CanvasTool.SELECTOR;
  private int                 _current_shape;

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
        _current = value;
        selected( value );
      }
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolbar( Canvas canvas ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5 );

    _canvas       = canvas;
    _current_item = new HashMap<CanvasItemCategory,CurrentItem>();

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

    var button = new CanvasToolButton( this, CanvasTool.SELECTOR ) {
      halign       = Align.START,
      icon_name    = "selection-symbolic",
      tooltip_text = _( "Selection Tool" )
    };

    button.notify["active"].connect(() => {
      if( button.active ) {
        current = CanvasTool.SELECTOR;
      }
    });

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

    var tool = (category == CanvasItemCategory.ARROW) ? CanvasTool.ARROW : CanvasTool.SHAPE;
    var btn = new CanvasToolButton( this, tool, popover ) {
      child = _current_item.get( category ).get_image( _canvas.win )
    };

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = tool;
      }
    });

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

    var btn = new CanvasToolButton( this, CanvasTool.STICKER ) {
      icon_name = "sticker-symbolic",
    };

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.STICKER;
      }
    });

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

    /*
    btn.clicked.connect((e) => {
      _canvas.items.add_sticker( info.resource );
      popover.popdown();
    });
    */

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

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.IMAGE;
      }
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the sequence button
  private void create_sequence() {

    var btn = new CanvasToolButton( this, CanvasTool.SEQUENCE ) {
      icon_name = "sequence-symbolic",
    };

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.SEQUENCE;
      }
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Starts a drawing operation with the pencil tool
  private void create_pencil() {

    var btn = new CanvasToolButton( this, CanvasTool.PENCIL ) {
      icon_name = "edit-symbolic",
    };

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.PENCIL;
      }
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the text insertion button
  private void create_text() {

    var btn = new CanvasToolButton( this, CanvasTool.TEXT ) {
      icon_name = "insert-text-symbolic",
    };

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.TEXT;
      }
    });

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

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.MAGNIFIER;
      }
    });

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

    btn.notify["active"].connect(() => {
      if( btn.active ) {
        current = CanvasTool.BLUR;
      }
    });

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


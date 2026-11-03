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

  private Canvas             _canvas;
  private ToggleButton       _crop_btn;
  private Array<CheckButton> _width_btns;
  private Array<CheckButton> _dash_btns;
  private ColorDialogButton  _color_chooser;
  private HashMap<CanvasItemCategory,CurrentItem> _current_item;
  private Array<CanvasToolButton>                 _tool_btns;
  private bool                                    _syncing_tools = false;

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolbar( Canvas canvas ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5 );

    _canvas       = canvas;
    _width_btns   = new Array<CheckButton>();
    _dash_btns    = new Array<CheckButton>();
    _current_item = new HashMap<CanvasItemCategory,CurrentItem>();
    _tool_btns    = new Array<CanvasToolButton>();

    // Keep the toolbar's toggle buttons in sync with the active tool
    _canvas.items.tool_changed.connect((tool) => {
      sync_tool_buttons();
    });

    // Create current items
    _current_item.set( CanvasItemCategory.ARROW, new CurrentItem.with_canvas_item( CanvasItemType.ARROW ) );
    _current_item.set( CanvasItemCategory.SHAPE, new CurrentItem.with_canvas_item( CanvasItemType.RECT_STROKE ) );

    create_shapes( CanvasItemCategory.ARROW, _( "Add Arrow" ), _( "More Arrows" ), _( "Custom Arrows" ) );
    create_shapes( CanvasItemCategory.SHAPE, _( "Add Shape" ), _( "More Shapes" ), _( "Custom Shapes" ) );
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
    create_color();
    create_stroke();
    create_fonts();
    create_separator();
    create_drag_label();

    // If the selection changes, update the toolbar
    _canvas.items.selection_changed.connect( selection_changed );

  }

  //-------------------------------------------------------------
  // Creates the shape toolbar item
  private void create_shapes( CanvasItemCategory category, string tooltip, string mb_tooltip, string custom_label ) {

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

    var mb = new Button.with_label( "\u23f7" ) {
      has_frame    = false,
      tooltip_text = mb_tooltip,
      margin_start = 0,
      margin_end   = margin
    };

    var popover = new Popover() {
      child = box
    };
    popover.set_parent( mb );

    mb.clicked.connect(() => {
      popover.popup();
    });

    var btn = new ToggleButton() {
      has_frame    = false,
      margin_start = margin,
      margin_end   = 0,
      tooltip_text = tooltip,
      child        = _current_item.get( category ).get_image( _canvas.win )
    };
    btn.toggled.connect(() => {
      if( _syncing_tools ) return;
      var current = _current_item.get( category );
      if( current.is_tool() ) {
        _canvas.items.set_tool( btn.active ? current.canvas_type : CanvasItemType.NONE );
      } else {
        _canvas.items.set_tool( CanvasItemType.NONE );
        current.add_item( _canvas.items );
      }
      sync_tool_buttons();
    });
    _tool_btns.append_val( new CanvasToolButton( btn, category, CanvasItemType.NONE ) );

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
          btn.child = _current_item.get( category ).get_image( _canvas.win );
          if( shape_type.is_tool() ) {
            _canvas.items.set_tool( shape_type );
          } else {
            _canvas.items.set_tool( CanvasItemType.NONE );
            _current_item.get( category ).add_item( _canvas.items );
          }
          sync_tool_buttons();
          popover.popdown();
        });
        fb.append( b );
      }
    }

    box.append( fb );
    _canvas.items.custom_items.create_menu( _canvas.win, category, popover, box, custom_label, 4 );
    _canvas.items.custom_items.item_selected.connect((cat, item) => {
      if( cat == category ) {
        _canvas.items.set_tool( CanvasItemType.NONE );
        _current_item.get( cat ).custom_item( item );
        _current_item.get( cat ).add_item( _canvas.items );
        sync_tool_buttons();
        btn.child = _current_item.get( cat ).get_image( _canvas.win );
        popover.popdown();
      }
    });

    var shape_box = new Box( Orientation.HORIZONTAL, 0 );
    shape_box.append( btn );
    shape_box.append( mb );

    append( shape_box );

    // If the system dark mode changes, hide the popover
    _canvas.win.theme_changed.connect((dark_mode) => {
      popover.hide();
    });

  }

  //-------------------------------------------------------------
  // Creates a toggle button which activates the given tool mode.
  private ToggleButton create_tool_button( CanvasItemType type ) {
    var btn = new ToggleButton() {
      icon_name      = type.icon_name(),
      has_frame      = false,
      tooltip_markup = type.tooltip(),
      margin_start   = margin,
      margin_end     = margin
    };
    btn.toggled.connect(() => {
      if( _syncing_tools ) return;
      _canvas.items.set_tool( btn.active ? type : CanvasItemType.NONE );
      sync_tool_buttons();
    });
    _tool_btns.append_val( new CanvasToolButton( btn, CanvasItemCategory.NONE, type ) );
    return( btn );
  }

  //-------------------------------------------------------------
  // Updates the pressed state of every tool button to match the
  // currently active tool.
  private void sync_tool_buttons() {
    var tool = _canvas.items.tool;
    _syncing_tools = true;
    for( int i=0; i<_tool_btns.length; i++ ) {
      var tb   = _tool_btns.index( i );
      var type = (tb.category != CanvasItemCategory.NONE) ?
                 _current_item.get( tb.category ).canvas_type : tb.tool;
      var current_is_tool = (tb.category == CanvasItemCategory.NONE) ||
                            _current_item.get( tb.category ).is_tool();
      tb.button.active = current_is_tool && (tool != CanvasItemType.NONE) && (tool == type);
    }
    _syncing_tools = false;
  }

  //-------------------------------------------------------------
  // Creates the sticker toolbar item
  private void create_sticker() {

    var sticker = CanvasItemType.STICKER;

    var mb = new MenuButton() {
      icon_name      = sticker.icon_name(),
      tooltip_markup = sticker.tooltip(),
      has_frame      = false,
      popover        = new Popover()
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = box
    };
    sw.set_size_request( 400, 400 );

    create_sticker_set( box, mb.popover );

    mb.popover.child = sw;

    append( mb );

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

    var btn = new Button.from_icon_name( "insert-image-symbolic" ) {
      has_frame      = false,
      tooltip_markup = CanvasItemType.IMAGE.tooltip(),
      margin_start   = margin,
      margin_end     = margin
    };
    btn.clicked.connect(() => {
      _canvas.items.add_image();
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the sequence button
  private void create_sequence() {

    var sequence = CanvasItemType.SEQUENCE;

    var btn = create_tool_button( sequence );

    append( btn );

  }

  //-------------------------------------------------------------
  // Starts a drawing operation with the pencil tool
  private void create_pencil() {

    var pencil = CanvasItemType.PENCIL;

    var btn = create_tool_button( pencil );

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the text insertion button
  private void create_text() {

    var btn = new Button.from_icon_name( "insert-text-symbolic" ) {
      has_frame      = false,
      tooltip_markup = CanvasItemType.TEXT.tooltip(),
      margin_start   = margin,
      margin_end     = margin
    };
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.TEXT );
    });

    append( btn );

  }

  //-------------------------------------------------------------
  // Adds the magnifier button
  private void create_magnifier() {

    var magnifier = CanvasItemType.MAGNIFIER;

    var btn = create_tool_button( magnifier );

    append( btn );

  }

  //-------------------------------------------------------------
  // Create the blur button
  private void create_blur() {

    var blur = CanvasItemType.BLUR;

    var btn = create_tool_button( blur );

    append( btn );

  }

  //-------------------------------------------------------------
  // Create the crop button
  private void create_crop() {

    _crop_btn = new ToggleButton() {
      icon_name    = "image-crop-symbolic",
      has_frame    = false,
      // TODO - tooltip_text = _( "Crop/Rotate Image" ),
      tooltip_text = _( "Crop Image" ),
      margin_start = margin,
      margin_end   = margin
    };

    _crop_btn.toggled.connect(() => {
      if( !_crop_btn.active ) {
        _canvas.image.cancel_crop();
      } else {
        _canvas.items.set_tool( CanvasItemType.NONE );
        _canvas.items.clear_selection();
        _canvas.image.start_crop();
      }
      _canvas.items.clear_selection();
      _canvas.queue_draw();
      _canvas.grab_focus();
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
  // Creates the color dropdown
  private void create_color() {

    var dialog = new ColorDialog() {
      modal      = true,
      title      = _( "Selection Shape Color" ),
      with_alpha = true
    };

    _color_chooser = new ColorDialogButton( dialog ) {
      tooltip_text = _( "Shape Color" ),
      rgba         = _canvas.items.props.color
    };

    _color_chooser.notify["rgba"].connect(() => {
      _canvas.items.props.color = _color_chooser.get_rgba();
    });

    append( _color_chooser );

  }

  //-------------------------------------------------------------
  // Sets the current color
  public void set_color( Gdk.RGBA color ) {

    _color_chooser.rgba = color;

  }

  //-------------------------------------------------------------
  // Adds the stroke dropdown
  private void create_stroke() {

    var mb = new MenuButton() {
      has_frame    = false,
      tooltip_text = _( "Shape Border" ),
      popover      = new Gtk.Popover(),
      child        = make_stroke_icon()
    };

    _canvas.win.theme_changed.connect((dark) => {
      mb.child = make_stroke_icon();
    });

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };

    // Add stroke width
    var width_title = new Label( Utils.make_title( _( "Border Width" ) ) ) {
      halign     = Align.START,
      use_markup = true
    };
    box.append( width_title );

    unowned CheckButton? width_group = null;
    for( int i=0; i<CanvasItemStrokeWidth.NUM; i++ ) {
      var sw  = (CanvasItemStrokeWidth)i;
      var btn = new CheckButton() {
        margin_start = 20,
        active       = (_canvas.items.props.stroke_width == sw)
      };
      btn.set_group( width_group );
      btn.toggled.connect(() => {
        if( btn.get_active() ) {
          _canvas.items.props.stroke_width = sw;
          mb.child = make_stroke_icon();
        }
      });
      _width_btns.append_val( btn );
      if( width_group == null ) {
        width_group = btn;
      }
      var icn = new Picture.for_paintable( make_width_icon( 100, sw.width() ) ) {
        can_shrink = false
      };
      _canvas.win.theme_changed.connect((dark) => {
        icn.paintable = make_width_icon( 100, sw.width() );
      });
      var rbox = new Box( Orientation.HORIZONTAL, 5 );
      rbox.append( btn );
      rbox.append( icn );
      box.append( rbox );
    }

    // Add dash patterns
    var dash_title = new Label( Utils.make_title( _( "Dash Pattern" ) ) ) {
      halign     = Align.START,
      margin_top = 20,
      use_markup = true
    };
    box.append( dash_title );

    unowned CheckButton? dash_group = null;
    for( int i=0; i<CanvasItemDashPattern.NUM; i++ ) {
      var dash = (CanvasItemDashPattern)i;
      var btn  = new CheckButton() {
        margin_start = 20,
        active       = (_canvas.items.props.dash == dash),
      };
      btn.set_group( dash_group );
      btn.toggled.connect(() => {
        if( btn.get_active() ) {
          _canvas.items.props.dash = dash;
          mb.child = make_stroke_icon();
        }
      });
      _dash_btns.append_val( btn );
      if( dash_group == null ) {
        dash_group = btn;
      }
      var icn = new Picture.for_paintable( make_dash_icon( 100, dash ) ) {
        can_shrink = false
      };
      _canvas.win.theme_changed.connect((dark) => {
        icn.paintable = make_dash_icon( 100, dash );
      });
      var rbox = new Box( Orientation.HORIZONTAL, 5 );
      rbox.append( btn );
      rbox.append( icn );
      box.append( rbox );
    }

    // Add outline
    var outline_title = new Label( Utils.make_title( _( "Show Outline" ) ) ) {
      halign     = Align.START,
      use_markup = true
    };
    var outline_sw = new Switch() {
      halign = Align.END,
      active = _canvas.items.props.outline
    };
    outline_sw.notify["active"].connect(() => {
      _canvas.items.props.outline = !_canvas.items.props.outline;
    });
    var outline_box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = false,
      margin_top  = 20
    };
    outline_box.append( outline_title );
    outline_box.append( outline_sw );
    box.append( outline_box );

    mb.popover.child = box;

    append( mb );

  }

  //-------------------------------------------------------------
  // Adds the font menubutton
  private void create_fonts() {

    var btn = new Button.from_icon_name( "font-symbolic" ) {
      tooltip_text  = _( "Font Properties" ),
      has_frame     = false,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };

    var font_chooser = new FontDialog() {
      title = _( "Change Font" )
    };

    btn.clicked.connect(() => {
      font_chooser.choose_font.begin( _canvas.win, _canvas.items.props.font, null, (obj, res) => {
        try {
          var fd = font_chooser.choose_font.end( res );
          _canvas.items.props.font = fd;
        } catch( Error e ) {}
      });
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

  /*
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
  */

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

  }

  //-------------------------------------------------------------
  // Creates the stroke icon
  private Image make_stroke_icon() {

    var width   = 50;
    var height  = _canvas.items.props.stroke_width.width();

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)50, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the image
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
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
  // Called whenever the item selection changes
  private void selection_changed( CanvasItemProperties props ) {

    var p = new CanvasItemProperties();
    p.copy( props );

    // Updates the width group
    _width_btns.index( (int)p.stroke_width ).set_active( true );

    // Updates the dash group
    _dash_btns.index( (int)p.dash ).set_active( true );

    // Set the color
    _color_chooser.rgba = p.color;

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

//-------------------------------------------------------------
// Associates a toolbar toggle button with the tool it activates.
// Category buttons (arrows/shapes) resolve their tool from the
// toolbar's current item for that category.
public class CanvasToolButton {
  public ToggleButton       button   { get; private set; }
  public CanvasItemCategory category { get; private set; }
  public CanvasItemType     tool     { get; private set; }
  public CanvasToolButton( ToggleButton button, CanvasItemCategory category, CanvasItemType tool ) {
    this.button   = button;
    this.category = category;
    this.tool     = tool;
  }
}

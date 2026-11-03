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
using Gdk;
using Cairo;

public enum CanvasItemCategory {
  NONE,
  ARROW,
  SHAPE,
  TEXT,
  NUM
}

public enum CanvasItemType {
  RECT_STROKE,
  RECT_FILL,
  OVAL_STROKE,
  OVAL_FILL,
  STAR_STROKE,
  STAR_FILL,
  TALK,
  THINK,
  LINE,
  ARROW,
  TEXT,
  BLUR,
  MAGNIFIER,
  PENCIL,
  SEQUENCE,
  STICKER,
  IMAGE,
  NONE,
  NUM;

  public string to_string() {
    switch( this ) {
      case RECT_STROKE :  return( "rect-stroke" );
      case RECT_FILL   :  return( "rect-fill" );
      case OVAL_STROKE :  return( "oval-stroke" );
      case OVAL_FILL   :  return( "oval-fill" );
      case STAR_STROKE :  return( "star-stroke" );
      case STAR_FILL   :  return( "star-fill" );
      case TALK        :  return( "talk" );
      case THINK       :  return( "think" );
      case LINE        :  return( "line" );
      case ARROW       :  return( "arrow" );
      case TEXT        :  return( "text" );
      case BLUR        :  return( "blur" );
      case MAGNIFIER   :  return( "magnifier" );
      case PENCIL      :  return( "pencil" );
      case SEQUENCE    :  return( "sequence" );
      case STICKER     :  return( "sticker" );
      case IMAGE       :  return( "image" );
      default          :  return( "none" );
    }
  }

  public static CanvasItemType parse( string value ) {
    switch( value ) {
      case "rect-stroke" :  return( RECT_STROKE );
      case "rect-fill"   :  return( RECT_FILL );
      case "oval-stroke" :  return( OVAL_STROKE );
      case "oval-fill"   :  return( OVAL_FILL );
      case "star-stroke" :  return( STAR_STROKE );
      case "star-fill"   :  return( STAR_FILL );
      case "talk"        :  return( TALK );
      case "think"       :  return( THINK );
      case "line"        :  return( LINE );
      case "arrow"       :  return( ARROW );
      case "text"        :  return( TEXT );
      case "blur"        :  return( BLUR );
      case "magnifier"   :  return( MAGNIFIER );
      case "pencil"      :  return( PENCIL );
      case "sequence"    :  return( SEQUENCE );
      case "sticker"     :  return( STICKER );
      case "image"       :  return( IMAGE );
      default            :  return( NONE );
    }
  }

  public string icon_name() {
    switch( this ) {
      case RECT_STROKE :  return( "rect-stroke-symbolic" );
      case RECT_FILL   :  return( "rect-fill-symbolic" );
      case OVAL_STROKE :  return( "circle-stroke-symbolic" );
      case OVAL_FILL   :  return( "circle-fill-symbolic" );
      case STAR_STROKE :  return( "star-stroke-symbolic" );
      case STAR_FILL   :  return( "star-fill-symbolic" );
      case TALK        :  return( "bubble-talk-symbolic" );
      case THINK       :  return( "bubble-think-symbolic" );
      case LINE        :  return( "line-symbolic" );
      case ARROW       :  return( "arrow-symbolic" );
      case BLUR        :  return( "blur-symbolic" );
      case MAGNIFIER   :  return( "magnifier-symbolic" );
      case PENCIL      :  return( "edit-symbolic" );
      case SEQUENCE    :  return( "sequence-symbolic" );
      case STICKER     :  return( "sticker-symbolic" );
      default          :  return( "" );
    }
  }

  public string tooltip() {
    switch( this ) {
      case RECT_STROKE :  return( Utils.tooltip_with_accel( _( "Rectangle Outline" ), "r" ) );
      case RECT_FILL   :  return( Utils.tooltip_with_accel( _( "Rectangle" ), "<shift>r" ) );
      case OVAL_STROKE :  return( Utils.tooltip_with_accel( _( "Oval Outline" ), "o" ) );
      case OVAL_FILL   :  return( Utils.tooltip_with_accel( _( "Oval" ), "<shift>o" ) );
      case STAR_STROKE :  return( Utils.tooltip_with_accel( _( "Star Outline" ), "s" ) );
      case STAR_FILL   :  return( Utils.tooltip_with_accel( _( "Star" ), "<shift>s" ) );
      case TALK        :  return( Utils.tooltip_with_accel( _( "Talk Bubble" ), "k" ) );
      case THINK       :  return( Utils.tooltip_with_accel( _( "Think Bubble" ), "<shift>k" ) );
      case LINE        :  return( Utils.tooltip_with_accel( _( "Line" ), "l" ) );
      case ARROW       :  return( Utils.tooltip_with_accel( _( "Arrow" ), "a" ) );
      case TEXT        :  return( Utils.tooltip_with_accel( _( "Text" ), "t" ) );
      case BLUR        :  return( Utils.tooltip_with_accel( _( "Blur" ), "b" ) );
      case MAGNIFIER   :  return( Utils.tooltip_with_accel( _( "Magnifier" ), "m" ) );
      case PENCIL      :  return( Utils.tooltip_with_accel( _( "Pencil Tool" ), "p" ) );
      case SEQUENCE    :  return( Utils.tooltip_with_accel( _( "Sequence Number" ), "q" ) );
      case STICKER     :  return( _( "Sticker" ) );
      case IMAGE       :  return( Utils.tooltip_with_accel( _( "Image" ), "i" ) );
      default          :  return( "" );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this item type is used as a persistent tool
  // mode (the tool stays active and every press/drag on the canvas
  // creates a new item) instead of adding a single item.
  public bool is_tool() {
    switch( this ) {
      case RECT_STROKE  :
      case RECT_FILL    :
      case OVAL_STROKE  :
      case OVAL_FILL    :
      case STAR_STROKE  :
      case STAR_FILL    :
      case LINE         :
      case ARROW        :
      case BLUR         :
      case MAGNIFIER    :
      case PENCIL       :
      case SEQUENCE     :  return( true );
      default           :  return( false );
    }
  }

  public CanvasItemCategory category() {
    switch( this ) {
      case RECT_STROKE :  return( CanvasItemCategory.SHAPE );
      case RECT_FILL   :  return( CanvasItemCategory.SHAPE );
      case OVAL_STROKE :  return( CanvasItemCategory.SHAPE );
      case OVAL_FILL   :  return( CanvasItemCategory.SHAPE );
      case STAR_STROKE :  return( CanvasItemCategory.SHAPE );
      case STAR_FILL   :  return( CanvasItemCategory.SHAPE );
      case TALK        :  return( CanvasItemCategory.SHAPE );
      case THINK       :  return( CanvasItemCategory.SHAPE );
      case LINE        :  return( CanvasItemCategory.SHAPE );
      case ARROW       :  return( CanvasItemCategory.ARROW );
      case TEXT        :  return( CanvasItemCategory.TEXT );
      default          :  return( CanvasItemCategory.NONE );
    }
  }
}

public class CanvasItems {

  private Canvas               _canvas;
  private List<CanvasItem>     _items;
  private CanvasItem?          _active         = null;
  private int                  _selector_index = -1;
  private double               _last_x;
  private double               _last_y;
  private int                  _press_count    = -1;
  private FormatBar?           _format_bar     = null;
  private Cursor               _xterm_cursor   = new Cursor.from_name( "text", null );
  private CanvasItemType       _tool           = CanvasItemType.NONE;
  private bool                 _creating       = false;
  private double               _drag_x;
  private double               _drag_y;
  private int                  _drag_moves     = 0;

  public signal void tool_changed( CanvasItemType tool );

  // The currently active tool mode (NONE when no tool is active)
  public CanvasItemType tool {
    get {
      return( _tool );
    }
  }

  private const GLib.ActionEntry[] action_entries = {
    { "action_copy",          action_copy },
    { "action_cut",           action_cut },
    { "action_delete",        action_delete },
    { "action_send_to_front", action_send_to_front },
    { "action_send_to_back",  action_send_to_back },
    { "action_save_custom",   action_save_custom }
  };

  public CanvasItemProperties props        { get; private set; }
  public string               hilite_color { get; set; default = "yellow"; }
  public string               font_color   { get; set; default = "black"; }
  public CustomItems          custom_items { get; private set; }
  public bool                 control_set  { get; private set; default = false; }
  public bool                 shift_set    { get; private set; default = false; }

  public signal void text_item_edit_changed( CanvasItemText item );
  public signal void selection_changed( CanvasItemProperties props );

  //-------------------------------------------------------------
  // Constructor
  public CanvasItems( Canvas canvas ) {

    _canvas = canvas;

    // Create storage for the canvas items
    _items = new List<CanvasItem>();

    // Create the overall properties structure
    props = new CanvasItemProperties( true );
    props.changed.connect( update_selected_attributes );

    // Create the CustomItems object
    custom_items = new CustomItems();
    custom_items.load( this );

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    _canvas.insert_action_group( "items", actions );

  }

  //-------------------------------------------------------------
  // Returns true if at least one item exists in the canvas
  public bool items_exist() {
    return( _items.length() > 0 );
  }

  //-------------------------------------------------------------
  // Returns the box to place a canvas item into
  //-------------------------------------------------------------
  // Activates the given tool mode.  Passing NONE (or a type that
  // is not a tool) leaves tool mode.
  public void set_tool( CanvasItemType tool ) {
    if( !tool.is_tool() ) {
      tool = CanvasItemType.NONE;
    }
    if( _tool == tool ) return;
    if( in_edit_mode() ) {
      set_edit_mode( false );
    }
    clear_selection();
    _tool = tool;
    set_tool_cursor();
    tool_changed( _tool );
    _canvas.queue_draw();
    _canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Activates the given tool, or leaves tool mode if it is already
  // the active tool.
  public void toggle_tool( CanvasItemType tool ) {
    set_tool( (_tool == tool) ? CanvasItemType.NONE : tool );
  }

  //-------------------------------------------------------------
  // Sets the canvas cursor to match the active tool.
  private void set_tool_cursor() {
    switch( _tool ) {
      case CanvasItemType.NONE   :  _canvas.set_cursor( null );                   break;
      case CanvasItemType.PENCIL :  _canvas.set_cursor_from_name( "pencil" );     break;
      default                    :  _canvas.set_cursor_from_name( "crosshair" );  break;
    }
  }

  //-------------------------------------------------------------
  // Returns the index of the point which follows the cursor when
  // dragging out a new line-like item from its tail to its head.
  private int tool_head_index() {
    switch( _tool ) {
      case CanvasItemType.ARROW :  return( 0 );  // CanvasItemArrow head
      default                   :  return( 1 );  // Line end
    }
  }

  //-------------------------------------------------------------
  // Returns true if the active tool creates items by dragging out
  // a line (tail to head) rather than a box.
  private bool tool_is_linear() {
    return( (_tool == CanvasItemType.LINE) ||
            (_tool == CanvasItemType.ARROW) );
  }

  //-------------------------------------------------------------
  // Returns the minimum width/height of an item being dragged out.
  // Blur and magnifier sample image pixels and need a usable size.
  private double tool_min_size() {
    switch( _tool ) {
      case CanvasItemType.BLUR      :
      case CanvasItemType.MAGNIFIER :  return( 10 );
      default                       :  return( 1 );
    }
  }

  //-------------------------------------------------------------
  // Creates a new, unpositioned item for the active tool.
  private CanvasItem? create_tool_item() {
    switch( _tool ) {
      case CanvasItemType.RECT_STROKE  :  return( create_rectangle( false, true ) );
      case CanvasItemType.RECT_FILL    :  return( create_rectangle( true, true ) );
      case CanvasItemType.OVAL_STROKE  :  return( create_oval( false, true ) );
      case CanvasItemType.OVAL_FILL    :  return( create_oval( true, true ) );
      case CanvasItemType.STAR_STROKE  :  return( create_star( false, true ) );
      case CanvasItemType.STAR_FILL    :  return( create_star( true, true ) );
      case CanvasItemType.LINE         :  return( create_line( true ) );
      case CanvasItemType.ARROW        :  return( create_arrow( true ) );
      case CanvasItemType.BLUR         :  return( create_blur( true ) );
      case CanvasItemType.MAGNIFIER    :  return( create_magnifier( true ) );
      case CanvasItemType.PENCIL       :  return( create_pencil( true ) );
      case CanvasItemType.SEQUENCE     :  return( create_sequence( true ) );
      default                          :  return( null );
    }
  }

  //-------------------------------------------------------------
  // Starts creating a new item with the active tool at the given
  // canvas position.  Returns true if the canvas should be redrawn.
  private bool begin_tool_item( double x, double y ) {

    var item = create_tool_item();
    if( item == null ) return( false );

    clear_selection();

    _drag_x     = x;
    _drag_y     = y;
    _last_x     = x;
    _last_y     = y;
    _drag_moves = 0;

    // Sequence numbers are simply placed where the user clicks
    if( _tool == CanvasItemType.SEQUENCE ) {
      item.bbox = new CanvasRect.from_coords( (x - 25), (y - 25), 50, 50 );
      add_item( item, -1, true );
      return( true );
    }

    // Everything else is dragged out.  The item is only recorded in
    // the undo buffer once the drag completes (see end_tool_item).
    item.bbox = new CanvasRect.from_coords( x, y, tool_min_size(), tool_min_size() );
    _items.append( item );
    item.mode = CanvasItemMode.DRAWING;
    _active   = item;
    _creating = true;

    if( _tool == CanvasItemType.PENCIL ) {
      item.draw( x, y );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Updates the item being created as the cursor is dragged.
  private void update_tool_item( double x, double y, double diff_x, double diff_y ) {

    _drag_moves++;

    if( _tool == CanvasItemType.PENCIL ) {
      _active.draw( x, y );

    } else if( tool_is_linear() ) {
      _active.move_selector( tool_head_index(), diff_x, diff_y, shift_set );

    } else {
      var w = Math.fabs( x - _drag_x );
      var h = Math.fabs( y - _drag_y );
      // Shift constrains to a square; the magnifier is always round
      if( shift_set || (_tool == CanvasItemType.MAGNIFIER) ) {
        w = h = double.max( w, h );
      }
      var bx = (x < _drag_x) ? (_drag_x - w) : _drag_x;
      var by = (y < _drag_y) ? (_drag_y - h) : _drag_y;
      var min = tool_min_size();
      _active.bbox = new CanvasRect.from_coords( bx, by, double.max( w, min ), double.max( h, min ) );
    }

  }

  //-------------------------------------------------------------
  // Finishes creating the current tool item.  Items that were
  // barely dragged are discarded so that a stray click does not
  // leave an invisible item behind.
  private void end_tool_item( double x, double y ) {

    var item = _active;
    _creating = false;

    var valid = (_tool == CanvasItemType.PENCIL) ?
                (_drag_moves > 1) :
                (Math.sqrt( ((x - _drag_x) * (x - _drag_x)) + ((y - _drag_y) * (y - _drag_y)) ) >= 5);

    if( !valid ) {
      _items.remove( item );
      return;
    }

    _canvas.undo_buffer.add_item( new UndoItemAdd( item, _items.index( item ) ) );

    // Keep shapes selected so they can be adjusted right away.  Pencil
    // strokes are left unselected so drawing can continue freely.
    if( _tool == CanvasItemType.PENCIL ) {
      item.mode = CanvasItemMode.NONE;
    } else {
      item.mode = CanvasItemMode.SELECTED;
      selection_changed( item.props );
    }

  }

  public CanvasRect center_box( double width, double height ) {
    var rect = _canvas.editor.get_displayed_rect();
    rect.copy_coords( (rect.x + ((rect.width - width) / 2)), (rect.y + ((rect.height - height) / 2)), width, height );
    return( rect );
  }

  private CanvasItem create_rectangle( bool fill, bool loading = false ) {
    var item = new CanvasItemRect( _canvas, fill, props );
    if( !loading ) {
      item.bbox = center_box( 200, 50 );
    }
    return( item );
  }

  private CanvasItem create_oval( bool fill, bool loading = false ) {
    var item = new CanvasItemOval( _canvas, fill, props );
    if( !loading ) {
      item.bbox = center_box( 200, 50 );
    }
    return( item );
  }

  private CanvasItem create_star( bool fill, bool loading = false ) {
    var item = new CanvasItemStar( _canvas, fill, 5, 25, props );
    if( !loading ) {
      item.bbox = center_box( 100, 100 );
    }
    return( item );
  }

  private CanvasItem create_bubble( CanvasBubbleType type, bool loading = false ) {
    var item = new CanvasItemBubble( _canvas, type, props );
    if( !loading ) {
      item.bbox = center_box( 200, 100 );
    }
    return( item );
  }

  private CanvasItem create_line( bool loading = false ) {
    var item = new CanvasItemLine( _canvas, props );
    if( !loading ) {
      item.bbox = center_box( 200, 1 );
    }
    return( item );
  }

  private CanvasItem create_arrow( bool loading = false ) {
    var item = new CanvasItemArrow( _canvas, props );
    if( !loading ) {
      item.bbox = center_box( 200, 1 );
    }
    return( item );
  }

  private CanvasItem create_text( bool loading = false ) {
    var item = new CanvasItemText( _canvas, props );
    item.select_mode.connect((value) => {
      if( value ) {
        show_format_bar();
      } else {
        hide_format_bar();
      }
    });
    if( !loading ) {
      item.bbox = center_box( 200, 1 );
      item.mode = CanvasItemMode.SELECTED;
      _active = item;
      set_edit_mode( true );
    }
    return( item );
  }

  private CanvasItem create_blur( bool loading = false ) {
    var item = new CanvasItemBlur( _canvas, props );
    if( !loading ) {
      item.bbox = center_box( 200, 50 );
    }
    return( item );
  }

  private CanvasItem create_magnifier( bool loading = false ) {
    var item = new CanvasItemMagnifier( _canvas, 2.0, props );
    if( !loading ) {
      item.bbox = center_box( 200, 200 );
    }
    return( item );
  }

  private CanvasItem create_pencil( bool loading = false ) {
    var item = new CanvasItemPencil( _canvas, props );
    if( !loading ) {
      _active = item;
      _canvas.set_cursor_from_name( "pencil" );
    }
    return( item );
  }

  private CanvasItem create_sequence( bool loading = false ) {
    var item = new CanvasItemSequence( _canvas, props );
    if( !loading ) {
      item.bbox = center_box( 50, 50 );
    }
    return( item );
  }

  private CanvasItem create_sticker( string? name, bool loading = false ) {
    var item = new CanvasItemImage( _canvas, name, false, props );
    if( (name != null) && !loading ) {
      item.bbox = center_box( 50, 50 );
    }
    return( item );
  }

  private CanvasItem create_image( string? path, bool loading = false ) {
    var item = new CanvasItemImage( _canvas, path, true, props );
    if( (path != null) && !loading ) {
      item.bbox = center_box( item.bbox.width, item.bbox.height );
    }
    return( item );
  }

  public void add_item( CanvasItem item, int position, bool undo, bool draw = true ) {
    clear_selection();
    item.mode = CanvasItemMode.SELECTED;
    _items.insert( item, position );
    _canvas.grab_focus();
    if( undo ) {
      _canvas.undo_buffer.add_item( new UndoItemAdd( item, (int)(_items.length() - 1) ) );
    }
    if( draw ) {
      _canvas.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Adds the given shape to the top of the item stack
  public void add_shape_item( CanvasItemType type ) {
    if( !type.is_tool() ) {
      set_tool( CanvasItemType.NONE );
    }
    CanvasItem? item = null;
    switch( type ) {
      case CanvasItemType.RECT_STROKE  :  item = create_rectangle( false );  break;
      case CanvasItemType.RECT_FILL    :  item = create_rectangle( true );  break;
      case CanvasItemType.OVAL_STROKE  :  item = create_oval( false );  break;
      case CanvasItemType.OVAL_FILL    :  item = create_oval( true );  break;
      case CanvasItemType.STAR_STROKE  :  item = create_star( false );  break;
      case CanvasItemType.STAR_FILL    :  item = create_star( true );  break;
      case CanvasItemType.TALK         :  item = create_bubble( CanvasBubbleType.TALK );  break;
      case CanvasItemType.THINK        :  item = create_bubble( CanvasBubbleType.THINK );  break;
      case CanvasItemType.LINE         :  item = create_line();  break;
      case CanvasItemType.ARROW        :  item = create_arrow();  break;
      case CanvasItemType.TEXT         :  item = create_text();  break;
      case CanvasItemType.BLUR         :  item = create_blur();  break;
      case CanvasItemType.MAGNIFIER    :  item = create_magnifier();  break;
      case CanvasItemType.PENCIL       :  item = create_pencil();  break;
      case CanvasItemType.SEQUENCE     :  item = create_sequence();  break;
      default :  assert_not_reached();
    }
    add_item( item, -1, true );
  }

  public void add_sticker( string name ) {
    set_tool( CanvasItemType.NONE );
    var item = create_sticker( name );
    add_item( item, -1, true );
  }

  //-------------------------------------------------------------
  // Adds an image that the user can select from using a standard
  // file open dialog.
  public void add_image() {

    set_tool( CanvasItemType.NONE );

    // Create file filters for each supported format
    var filters = new GLib.ListStore( typeof( FileFilter ) );
    foreach( FileFilter filter in _canvas.win.image_filters ) {
      filters.append( filter );
    }

    // Get the file to open from the user
    var dialog = new FileDialog() {
      title   = _( "Open Insertion Image" ),
      filters = filters
    };
    Utils.set_chooser_folder( dialog );

    dialog.open.begin( _canvas.win, null, (obj, res) => {
      try {
        var file     = dialog.open.end( res );
        var filename = file.get_path();
        var item     = create_image( filename );
        add_item( item, -1, true );
        Utils.store_chooser_folder( filename );
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Removes all of the canvas items
  public void clear() {
    while( _items.first() != null ) {
      _items.delete_link( _items.first() );
    }
    _canvas.queue_draw();
  }

  public void insert_item( CanvasItem item, int position ) {
    _items.insert( item, position );
  }

  //-------------------------------------------------------------
  // Removes the item at the given position without undo addition
  public void remove_item( CanvasItem item ) {
    _items.remove( item );
    hide_format_bar();
  }

  //-------------------------------------------------------------
  // Adds the given item at the top of the item stack
  public void move_to_front( CanvasItem item ) {
    _items.append( item );
  }

  //-------------------------------------------------------------
  // Adds the given item at the bottom of the item stack
  public void move_to_back( CanvasItem item ) {
    _items.prepend( item );
  }

  //-------------------------------------------------------------
  // Returns true if an item is currently selected
  public bool is_item_selected() {
    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the currently selected item
  public CanvasItem? get_selected_item() {
    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        return( item );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Deletes all of the selected items
  private bool remove_selected() {
    var retval    = false;
    var position  = 0;
    var undo_item = new UndoItemDelete();
    unowned var item = _items.first();
    while( item != null ) {
      if( item.data.mode == CanvasItemMode.SELECTED ) {
        unowned var next = item.next;
        undo_item.add( item.data, position );
        _items.delete_link( item );
        _canvas.set_cursor( null );
        item = next;
        retval = true;
      } else {
        item = item.next;
      }
      position++;
    }
    if( retval ) {
      _canvas.undo_buffer.add_item( undo_item );
    }
    return( retval );
  }

  //-------------------------------------------------------------
  // Clears the currently selected items
  public bool clear_selection() {
    var retval = false;
    _selector_index = -1;
    foreach( CanvasItem item in _items ) {
      retval |= (item.mode != CanvasItemMode.NONE);
      item.mode = CanvasItemMode.NONE;
    }
    return( retval );
  }

  //-------------------------------------------------------------
  // Update the selected attributes
  private void update_selected_attributes() {
    var undo_item = new UndoItemPropChange();
    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        item.props = props;
        undo_item.add( item );
      }
    }
    if( !undo_item.empty() ) {
      _canvas.undo_buffer.replace_item( undo_item );
    }
    _canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Returns the position of the given canvas item in the list of
  // items
  private int item_position( CanvasItem item ) {
    var pos = 0;
    foreach( CanvasItem it in _items ) {
      if( it == item ) {
        return( pos );
      }
      pos++;
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adjusts all items by the given diff amounts
  public void adjust_items( double diffx, double diffy, bool moving = true ) {
    foreach( CanvasItem item in _items ) {
      item.move_item( diffx, diffy, moving );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the shift key is enabled in the given state
  private bool shift_state( ModifierType state ) {
    return( (bool)(state & ModifierType.SHIFT_MASK) );
  }

  //-------------------------------------------------------------
  // Returns true if the control key is enabled in the given state
  private bool control_state( ModifierType state ) {
    return( (bool)(state & ModifierType.CONTROL_MASK) );
  }

  //-------------------------------------------------------------
  // Returns true if the alt key is enabled in the given state
  /*
  private bool alt_state( ModifierType state ) {
    return( (bool)(state & ModifierType.ALT_MASK) );
  }
  */

  //-------------------------------------------------------------
  // Returns the active text item, if it is set; otherwise,
  // returns null
  public CanvasItemText? get_active_text() {
    return( ((_active == null) || (_active.itype != CanvasItemType.TEXT)) ? null : (_active as CanvasItemText) );
  }

  //-------------------------------------------------------------
  // Returns true if we are currently editing a text item
  public bool in_edit_mode() {
    var text = get_active_text();
    return( (text != null) ? text.edit : false );
  }

  //-------------------------------------------------------------
  // Returns true if we are currently drawing something
  public bool in_draw_mode() {
    return( (_active != null) && (_active.mode == CanvasItemMode.DRAWING) );
  }

  //-------------------------------------------------------------
  // Sets the edit mode of the active text item to the given value
  private bool set_edit_mode( bool value ) {
    var text = get_active_text();
    if( text != null ) {
      if( text.edit != value ) {
        text.edit = value;
        if( value ) {
          text.set_cursor_all( false );
          _canvas.set_cursor( _xterm_cursor );
          text.mode = CanvasItemMode.EDITING;
        } else {
          text.clear_selection();
          _canvas.set_cursor( null );
          text.mode = CanvasItemMode.SELECTED;
        }
        text_item_edit_changed( text );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // HANDLE KEY PRESS EVENTS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Handles keypress events.  Returns true if the canvas should
  // be redrawn.
  public bool key_pressed( uint keyval, uint keycode, ModifierType state ) {

    var control = control_state( state );
    var shift   = shift_state( state );
    KeymapKey[] ks  = {};
    uint[]      kvs = {};

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    if( Utils.has_key( kvs, Key.BackSpace ) )        { return( handle_backspace() ); }
    else if( Utils.has_key( kvs, Key.Delete ) )      { return( handle_delete() ); }
    else if( Utils.has_key( kvs, Key.Return ) )      { return( handle_return( shift ) ); }
    else if( Utils.has_key( kvs, Key.Escape ) )      { return( handle_escape() ); }
    else if(  shift && Utils.has_key( kvs, Key.a ) ) { return( handle_cursor( control, shift, Key.A ) ); }
    else if( !shift && Utils.has_key( kvs, Key.a ) ) {
      if( in_edit_mode() ) {
        return( handle_cursor( control, shift, Key.a ) );
      } else {
        toggle_tool( CanvasItemType.ARROW );
        return( true );
      }
    }
    else if( Utils.has_key( kvs, Key.Left ) )        { return( handle_cursor( control, shift, Key.Left ) ); }
    else if( Utils.has_key( kvs, Key.Right ) )       { return( handle_cursor( control, shift, Key.Right ) ); }
    else if( Utils.has_key( kvs, Key.Home ) )        { return( handle_cursor( control, shift, Key.Home ) ); }
    else if( Utils.has_key( kvs, Key.End ) )         { return( handle_cursor( control, shift, Key.End ) ); }
    else if( Utils.has_key( kvs, Key.Up ) )          { return( handle_cursor( control, shift, Key.Up ) ); }
    else if( Utils.has_key( kvs, Key.Down ) )        { return( handle_cursor( control, shift, Key.Down ) ); }
    else if( !shift && Utils.has_key( kvs, Key.r ) ) { toggle_tool( CanvasItemType.RECT_STROKE );  return( true ); }
    else if(  shift && Utils.has_key( kvs, Key.r ) ) { toggle_tool( CanvasItemType.RECT_FILL );    return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.o ) ) { toggle_tool( CanvasItemType.OVAL_STROKE );  return( true ); }
    else if(  shift && Utils.has_key( kvs, Key.o ) ) { toggle_tool( CanvasItemType.OVAL_FILL );    return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.s ) ) { toggle_tool( CanvasItemType.STAR_STROKE );  return( true ); }
    else if(  shift && Utils.has_key( kvs, Key.s ) ) { toggle_tool( CanvasItemType.STAR_FILL );    return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.k ) ) { add_shape_item( CanvasItemType.TALK );         return( true ); }
    else if(  shift && Utils.has_key( kvs, Key.k ) ) { add_shape_item( CanvasItemType.THINK );        return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.l ) ) { toggle_tool( CanvasItemType.LINE );         return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.t ) ) { add_shape_item( CanvasItemType.TEXT );         return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.b ) ) { toggle_tool( CanvasItemType.BLUR );         return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.m ) ) { toggle_tool( CanvasItemType.MAGNIFIER );    return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.p ) ) { toggle_tool( CanvasItemType.PENCIL );       return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.q ) ) { toggle_tool( CanvasItemType.SEQUENCE );     return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.i ) ) { add_image();                                   return( true ); }
    else if( !shift && Utils.has_key( kvs, Key.v ) ) { do_paste(); }
    else if( !shift && Utils.has_key( kvs, Key.Shift_L ) ) { return( handle_shift() ); }
    else if( !shift && Utils.has_key( kvs, Key.Control_L ) ) { return( handle_control() ); }

    return( false );

  }

  //-------------------------------------------------------------
  // If we editing text, handle the backspace character; otherwise,
  // delete the selected items.
  private bool handle_backspace() {
    if( in_edit_mode() ) {
      var text = get_active_text();
      text.backspace( _canvas.undo_text );
    } else {
      remove_selected();
    }
    return( true );
  }

  //-------------------------------------------------------------
  // If we editing text, handle the delete character; otherwise,
  // delete the selected items.
  private bool handle_delete() {
    if( in_edit_mode() ) {
      var text = get_active_text();
      text.delete( _canvas.undo_text );
    } else {
      remove_selected();
    }
    return( true );
  }

  //-------------------------------------------------------------
  // If we are in text editing mode, mark the node as being not
  // in edit mode
  private bool handle_return( bool shift ) {
    if( in_edit_mode() ) {
      if( shift ) {
        var text = get_active_text();
        text.insert( "\n", _canvas.undo_text );
      } else {
        set_edit_mode( false );
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // If we are in text editing mode, remove the active node from
  // editing mode
  private bool handle_escape() {
    if( in_edit_mode() ) {
      set_edit_mode( false );
      return( true );
    } else if( _tool != CanvasItemType.NONE ) {
      set_tool( CanvasItemType.NONE );
      return( true );
    } else if( clear_selection() ) {
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // If we are in edit mode, moves cursor to the left/right or
  // adds to the selection
  private bool handle_cursor( bool control, bool shift, uint keyval ) {
    if( in_edit_mode() ) {
      var text = get_active_text();
      if( control ) {
        if( shift ) {
          switch( keyval ) {
            case Key.A     :  text.clear_selection();        break;
            case Key.Left  :  text.selection_by_word( -1 );  break;
            case Key.Right :  text.selection_by_word( 1 );   break;
            case Key.Home  :  text.selection_to_start();     break;
            case Key.End   :  text.selection_to_end();       break;
            default        :  return( false );
          }
        } else {
          switch( keyval ) {
            case Key.a     :  text.set_cursor_all( false );    break;
            case Key.Left  :  text.move_cursor_by_word( -1 );  break;
            case Key.Right :  text.move_cursor_by_word( 1 );   break;
            case Key.Home  :  text.move_cursor_to_start();     break;
            case Key.End   :  text.move_cursor_to_end();       break;
            default        :  return( false );
          }
        }
      } else {
        if( shift ) {
          switch( keyval ) {
            case Key.Left  :  text.selection_by_char( -1 );         break;
            case Key.Right :  text.selection_by_char( 1 );          break;
            case Key.Up    :  text.selection_vertically( -1 );      break;
            case Key.Down  :  text.selection_vertically( 1 );       break;
            case Key.Home  :  text.selection_to_linestart( true );  break;
            case Key.End   :  text.selection_to_lineend( true );    break;
            default        :  return( false );
          }
        } else {
          switch( keyval ) {
            case Key.Left  :  text.move_cursor( -1 );             break;
            case Key.Right :  text.move_cursor( 1 );              break;
            case Key.Up    :  text.move_cursor_vertically( -1 );  break;
            case Key.Down  :  text.move_cursor_vertically( 1 );   break;
            case Key.Home  :  text.move_cursor_to_linestart();    break;
            case Key.End   :  text.move_cursor_to_lineend();      break;
            default        :  return( false );
          }
        }
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handles the control key
  private bool handle_control() {
    control_set = true;
    if( !in_edit_mode() ) {
      foreach( CanvasItem item in _items ) {
        if( item.is_within( _last_x, _last_y ) ) {
          _canvas.set_cursor_from_name( "copy" );
          break;
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Called when the shift key is pressed.
  private bool handle_shift() {
    shift_set = true;
    return( false );
  }

  //-------------------------------------------------------------
  // Handles key release events.  Returns true if the canvas should
  // be redrawn.
  public bool key_released( uint keyval, ModifierType state ) {
    switch( keyval ) {
      case Key.Control_L :  return( handle_release_control() );
      case Key.Shift_L   :  return( handle_release_shift() );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Called when the control key is released
  private bool handle_release_control() {
    control_set = false;
    if( !in_edit_mode() ) {
      foreach( CanvasItem item in _items ) {
        if( item.is_within( _last_x, _last_y ) ) {
          _canvas.set_cursor_from_name( "grabbing" );
          return( false );
        }
      }
      _canvas.set_cursor( null );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Called when the shift key is released.
  private bool handle_release_shift() {
    shift_set = false;
    return( false );
  }

  //-------------------------------------------------------------
  // HANDLE MOUSE EVENTS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Called whenever the cursor is pressed.  Returns true if the
  // canvas should draw itself.
  public bool cursor_pressed( double x, double y, int press_count ) {

    var retval  = false;

    // Keep track of the press count
    _press_count = press_count;

    // If the active item is a pencil, indicate that we are drawing
    if( (_active != null) && (_active.itype == CanvasItemType.PENCIL) ) {
      _active.mode = CanvasItemMode.DRAWING;
      return( false );
    }

    // In tool mode, a press creates a new item, unless it lands on a
    // handle of the selected item (so it can still be adjusted).
    if( _tool != CanvasItemType.NONE ) {
      if( press_count > 1 ) {
        return( false );
      }
      foreach( CanvasItem item in _items ) {
        if( item.mode == CanvasItemMode.SELECTED ) {
          _selector_index = item.is_within_selector( x, y );
          if( _selector_index != -1 ) {
            _active      = item;
            _active.mode = CanvasItemMode.RESIZING;
            return( false );
          }
        }
      }
      return( begin_tool_item( x, y ) );
    }

    // Reverse the list so that we grab the top-most item
    _items.reverse();

    // Handle a click within a selector
    foreach( CanvasItem item in _items ) {
      _selector_index = item.is_within_selector( x, y );
      if( _selector_index != -1 ) {
        _active = item;
        _active.mode = CanvasItemMode.RESIZING;
        _items.reverse();
        return( false );
      }
    }

    // Handle a click within an item
    foreach( CanvasItem item in _items ) {
      if( item.is_within( x, y ) ) {
        _active = item;
        if( _active.mode == CanvasItemMode.NONE ) {
          clear_selection();
        }
        if( in_edit_mode() ) {
          var text = get_active_text();
          switch( press_count ) {
            case 1 :  text.set_cursor_at_char( x, y, false );  break;
            case 2 :  text.set_cursor_at_word( x, y, false );  break;
            case 3 :  text.set_cursor_all( false );            break;
          }
        } else if( control_set && (press_count == 1) ) {  // Make a duplicate of the clicked on item
          _active = item.duplicate();
          _active.mode = CanvasItemMode.SELECTED;
          _canvas.set_cursor_from_name( "grabbing" );
          add_item( _active, -1, true, false );
          selection_changed( item.props );
        } else {
          switch( press_count ) {
            case 1 :
              _active.mode = CanvasItemMode.SELECTED;
              _canvas.set_cursor_from_name( "grabbing" );
              selection_changed( item.props );
              break;
            case 2 :
              if( _active.itype != CanvasItemType.TEXT ) return( false );
              set_edit_mode( true );
              break;
          }
        }
        _items.reverse();
        return( true );
      }
    }

    // Return the list order
    _items.reverse();

    // If we didn't click on anything, clear the selection
    clear_selection();

    // Clear the edit mode, if we are in it
    retval = set_edit_mode( false );

    // Clear the active indicator
    _active = null;

    return( retval );

  }

  //-------------------------------------------------------------
  // Called whenever the cursor is moved.  Returns true if the
  // canvas should draw itself.
  public bool cursor_moved( double x, double y ) {

    var diff_x  = x - _last_x;
    var diff_y  = y - _last_y;

    _last_x = x;
    _last_y = y;

    // Since we pressed on a selector, move the selector
    if( _selector_index != -1 ) {
      _active.move_selector( _selector_index, diff_x, diff_y, shift_set );
      return( true );

    // If we are in edit mode, drag out the selection
    } else if( in_edit_mode() ) {
      var text = get_active_text();
      if( text.is_within( x, y ) ) {
        _canvas.set_cursor( _xterm_cursor );
        switch( _press_count ) {
          case 1  :  text.set_cursor_at_char( x, y, true );  break;
          case 2  :  text.set_cursor_at_word( x, y, true );  break;
          default :  return( false );
        }
      } else {
        _canvas.set_cursor( null );
      }
      return( true );

    // If we are in drawing mode, indicate that the cursor has moved
    } else if( in_draw_mode() ) {
      if( _creating ) {
        update_tool_item( x, y, diff_x, diff_y );
      } else {
        _active.draw( x, y );
      }
      return( true );

    // Otherwise, move any selected items by the given amount
    } else if( (_active != null) && !in_edit_mode() ) {
      var retval = false;
      foreach( CanvasItem item in _items ) {
        if( item.mode.can_move() ) {
          item.move_item( diff_x, diff_y );
          retval = true;
        }
      }
      return( retval );

    // Otherwise, we are just moving the cursor around the screen
    } else {
      foreach( CanvasItem item in _items ) {
        if( item.mode == CanvasItemMode.SELECTED ) {
          var sel_index = item.is_within_selector( x, y );
          if( sel_index != -1 ) {
            _canvas.set_cursor( item.get_selector_cursor( sel_index ) );
            _canvas.set_tooltip_text( item.get_selector_tooltip( sel_index ) );
            return( false );
          }
        }
      }
      _canvas.set_tooltip_text( null );
      if( _tool != CanvasItemType.NONE ) {
        set_tool_cursor();
        return( false );
      }
      foreach( CanvasItem item in _items ) {
        if( item.is_within( x, y ) ) {
          if( control_set ) {
            _canvas.set_cursor_from_name( "copy" );
          } else {
            _canvas.set_cursor_from_name( "grab" );
          }
          return( false );
        }
      }
      _canvas.set_cursor( null );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Called whenever the cursor button is released.  Returns true
  // if the canvas should draw itself.
  public bool cursor_released( double x, double y ) {

    var retval = false;

    _press_count = -1;

    // If we are finished dragging the selector, clear it
    if( _selector_index != -1 ) {
      _canvas.undo_buffer.add_item( _active.get_undo_item_for_selector( _selector_index ) );
      _selector_index = -1;
      _active.mode    = CanvasItemMode.SELECTED;
      _active         = null;
      retval = true;

    // If we are editing text, do nothing
    } else if( in_edit_mode() ) {
      return( true );

    // Indicate that we are done editing
    } else if( in_draw_mode() ) {
      if( _creating ) {
        end_tool_item( x, y );
      } else {
        _active.mode = CanvasItemMode.SELECTED;
        selection_changed( _active.props );
      }
      retval = true;

    // If we were move one or more items, make sure that they stay selected
    } else if( _active != null ) {
      var undo_item = new UndoItemBoxChange( _( "move items" ) );
      foreach( CanvasItem item in _items ) {
        if( item.mode == CanvasItemMode.MOVING ) {
          undo_item.add( item );
          item.mode = CanvasItemMode.SELECTED;
          retval = true;
        }
      }
      if( retval ) {
        _canvas.undo_buffer.add_item( undo_item );
      }

    // If we have not clicked/moved anything important, clear the selection
    } else if( _active == null ) {
      clear_selection();
      retval = true;
    }

    // Clear the active element
    _active = null;

    // Restore the cursor (keeping the tool cursor in tool mode)
    set_tool_cursor();

    // Make sure that the canvas has input focus
    _canvas.grab_focus();

    return( retval );

  }

  //-------------------------------------------------------------
  // CONTEXTUAL MENU
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Displays the contextual menu for the currently selected item,
  // if one exists
  public void show_contextual_menu( double x, double y ) {

    CanvasItem? within = null;

    foreach( CanvasItem item in _items ) {
      if( item.mode == CanvasItemMode.SELECTED ) {
        create_contextual_menu( item );
        return;
      }
      if( (within == null) && item.is_within( x, y ) ) {
        within = item;
      }
    }

    // If a node was not selected, display it for the item under the given cursor position
    if( within != null ) {
      create_contextual_menu( within );
      within.mode = CanvasItemMode.SELECTED;
      selection_changed( within.props );
      _canvas.queue_draw();
    }

  }

  private void create_contextual_menu( CanvasItem item ) {

    var pos  = item_position( item );
    var last = (int)(_items.length() - 1);
    var menu = new CanvasItemMenu( _canvas );

    // Add the item's contextual menu items
    item.add_contextual_menu_items( menu );
    menu.complete_section();

    if( !in_edit_mode() ) {

      menu.add_menu_item( item, _( "Copy" ), "<Control>c", true, do_copy );
      menu.add_menu_item( item, _( "Cut" ),  "<Control>x", true, do_cut );
      menu.complete_section();

      menu.add_menu_item( item, _( "Delete" ), "Delete", true, do_delete );
      menu.complete_section();

      menu.add_menu_item( item, _( "Send to Front" ), null, (pos != last), do_send_to_front );
      menu.add_menu_item( item, _( "Send to Back" ),  null, (pos != 0), do_send_to_back );
      menu.complete_section();
  
      if( item.itype.category() != CanvasItemCategory.NONE ) {
        menu.add_menu_item( item, _( "Save As Custom" ), null, true, do_save_custom );
        menu.complete_section();
      }

    }

    // Create and display the popover
    var popover = menu.create_popover( item.bbox.to_rectangle( _canvas.zoom_factor ) );
    popover.popup();

  }

  //-------------------------------------------------------------
  // Copy operation
  private void action_copy() {
    do_copy( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Creates a copy of the item and sends it to the clipboard
  public void do_copy( CanvasItem? item ) {
    if( in_edit_mode() ) {
      var text = get_active_text();
      if( text.is_selected() ) {
        AnnotatorClipboard.copy_text( text.get_selected_text() );
      }
    } else if( item != null ) {
      var items = new Array<CanvasItem>();
      items.append_val( item );
      AnnotatorClipboard.copy_items( serialize_for_copy( items ) );
    }
  }

  private void action_cut() {
    do_cut( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Creates a copy of the item, sends it to the clipboard, and
  // removes the item
  public void do_cut( CanvasItem? item ) {
    do_copy( item );
    do_delete( item );
  }

  //-------------------------------------------------------------
  // Pastes the given item from the clipboard (if one exists)
  private void do_paste() {
    AnnotatorClipboard.paste( _canvas.editor );
  }

  private void action_delete() {
    do_delete( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Deletes the item
  private void do_delete( CanvasItem? item ) {
    if( in_edit_mode() ) {
      var text = get_active_text();
      if( text.is_selected() ) {
        text.backspace( _canvas.undo_text );
      }
    } else if( item != null ) {
      var position  = 0;
      var undo_item = new UndoItemDelete();
      for( unowned List<CanvasItem> it=_items.first(); it!=null; it=it.next ) {
        if( it.data == item ) {
          undo_item.add( item, position );
          _items.delete_link( it );
          _canvas.undo_buffer.add_item( undo_item );
          return;
        }
        position++;
      }
    }
  }

  private void action_send_to_front() {
    do_send_to_front( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Moves the item to the top of the item list
  private void do_send_to_front( CanvasItem item ) {
    _canvas.undo_buffer.add_item( new UndoItemSendFront( item, item_position( item ) ) );
    remove_item( item );
    move_to_front( item );
    _canvas.queue_draw();
  }

  private void action_send_to_back() {
    do_send_to_back( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Moves the item to the bottom of the item list
  private void do_send_to_back( CanvasItem item ) {
    _canvas.undo_buffer.add_item( new UndoItemSendBack( item, item_position( item ) ) );
    remove_item( item );
    move_to_back( item );
    _canvas.queue_draw();
  }

  private void action_save_custom() {
    do_save_custom( get_selected_item() );
  }

  //-------------------------------------------------------------
  // Saves the given item as a custom item
  private void do_save_custom( CanvasItem item ) {
    var save_item = new CustomItem.with_item( item.duplicate() );
    custom_items.add( _canvas.win, save_item );
  }

  //-------------------------------------------------------------
  // Serialize the canvas items for the copy buffer
  public string serialize_for_copy( Array<CanvasItem> items ) {
    var       serialized = "";
    Xml.Doc*  doc = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "items" );
    doc->set_root_element( root );
    for( int i=0; i<items.length; i++ ) {
      root->add_child( items.index( i ).save( i, "" ) );
    }
    doc->dump_memory( out serialized );
    delete doc;
    return( serialized );
  }

  //-------------------------------------------------------------
  // Deserialize the given string and add the elements to the
  // item list
  public void deserialize_for_paste( string serialized ) {
    Xml.Doc* doc = Xml.Parser.parse_doc( serialized );
    if( doc == null ) return;
    var undo_item = new UndoItemPaste();
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "item") ) {
        CanvasItem? item = null;
        var type = CanvasItem.get_type_from_xml( it );
        switch( type ) {
          case CanvasItemType.RECT_STROKE :  item = create_rectangle( false );  break;
          case CanvasItemType.RECT_FILL   :  item = create_rectangle( true );   break;
          case CanvasItemType.OVAL_STROKE :  item = create_oval( false );       break;
          case CanvasItemType.OVAL_FILL   :  item = create_oval( true );        break;
          case CanvasItemType.STAR_STROKE :  item = create_star( false );       break;
          case CanvasItemType.STAR_FILL   :  item = create_star( true );        break;
          case CanvasItemType.TALK        :  item = create_bubble( CanvasBubbleType.TALK );  break;
          case CanvasItemType.THINK       :  item = create_bubble( CanvasBubbleType.THINK );  break;
          case CanvasItemType.LINE        :  item = create_line();              break;
          case CanvasItemType.ARROW       :  item = create_arrow();             break;
          case CanvasItemType.TEXT        :  item = create_text();              break;
          case CanvasItemType.BLUR        :  item = create_blur();              break;
          case CanvasItemType.MAGNIFIER   :  item = create_magnifier();         break;
          case CanvasItemType.PENCIL      :  item = create_pencil();            break;
          case CanvasItemType.SEQUENCE    :  item = create_sequence();          break;
          case CanvasItemType.STICKER     :  item = create_sticker( null );     break;
          case CanvasItemType.IMAGE       :  item = create_image( null );       break;
          default                         :  break;
        }
        if( item != null ) {
          item.load( it );
          item.bbox = center_box( item.bbox.width, item.bbox.height );
          add_item( item, -1, false, false );
          undo_item.add( item );
        }
      }
    }
    _canvas.undo_buffer.add_item( undo_item );
    _canvas.queue_draw();
  }

  //-------------------------------------------------------------
  //  TEXT FORMATTING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // If the format bar needs to be created, create it.  Place it
  // at the current cursor position and make sure that it is visible.
  private void show_format_bar() {

    // If the format bar is currently displayed, just reposition it
    if( _format_bar == null ) {
      _format_bar = new FormatBar( _canvas );
    }

    int selstart, selend, cursor;
    var text = get_active_text();

    text.get_cursor_info( out cursor, out selstart, out selend );

    // Position the popover
    double left, top, bottom;
    int    line;
    text.get_char_pos( cursor, out left, out top, out bottom, out line );

    // If this is the first line of the first row, change the popover point to the bottom of the text
    Gdk.Rectangle rect = {(int)left, (int)top, 1, 1};
    _format_bar.pointing_to = rect;
    _format_bar.position    = PositionType.TOP;

    _format_bar.popup();

  }

  //-------------------------------------------------------------
  // Hides the format bar if it is currently visible and destroys it
  private void hide_format_bar() {
    if( _format_bar != null ) {
      _format_bar.popdown();
      _format_bar = null;
    }
  }

  //-------------------------------------------------------------
  //  SAVE/LOAD METHODS
  //-------------------------------------------------------------

  public Xml.Node* save( string? image_dir = null ) {
    Xml.Node* node = new Xml.Node( null, "items" );
    var       id   = 1;
    foreach( CanvasItem item in _items ) {
      node->add_child( item.save( id++, image_dir ) );
    }
    return( node );
  }

  public CanvasItem? load_item( Xml.Node* node ) {
    CanvasItem? item = null;
    var type = CanvasItem.get_type_from_xml( node );
    switch( type ) {
      case CanvasItemType.RECT_STROKE :  item = create_rectangle( false, true );  break;
      case CanvasItemType.RECT_FILL   :  item = create_rectangle( true, true );   break;
      case CanvasItemType.OVAL_STROKE :  item = create_oval( false, true );       break;
      case CanvasItemType.OVAL_FILL   :  item = create_oval( true, true );        break;
      case CanvasItemType.STAR_STROKE :  item = create_star( false, true );       break;
      case CanvasItemType.STAR_FILL   :  item = create_star( true, true );        break;
      case CanvasItemType.TALK        :  item = create_bubble( CanvasBubbleType.TALK, true );            break;
      case CanvasItemType.THINK       :  item = create_bubble( CanvasBubbleType.THINK, true );            break;
      case CanvasItemType.LINE        :  item = create_line( true );              break;
      case CanvasItemType.ARROW       :  item = create_arrow( true );             break;
      case CanvasItemType.TEXT        :  item = create_text( true );              break;
      case CanvasItemType.BLUR        :  item = create_blur( true );              break;
      case CanvasItemType.MAGNIFIER   :  item = create_magnifier( true );         break;
      case CanvasItemType.PENCIL      :  item = create_pencil( true );            break;
      case CanvasItemType.SEQUENCE    :  item = create_sequence( true );          break;
      case CanvasItemType.STICKER     :  item = create_sticker( null, true );     break;
      case CanvasItemType.IMAGE       :  item = create_image( null );             break;
      default                         :  break;
    }
    if( item != null ) {
      item.load( node );
    }
    return( item );
  }

  public void load( Xml.Node* node ) {
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "item") ) {
        var item = load_item( it );
        if( item != null ) {
          _items.append( item );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Draws all of the canvas items on the given context
  public void draw( Context ctx ) {
    foreach( CanvasItem item in _items ) {
      item.draw_item( ctx );
      // item.draw_extents( ctx );
      CanvasItemDashPattern.NONE.set_fg_pattern( ctx );
    }
    foreach( CanvasItem item in _items ) {
      item.draw_selectors( ctx );
    }
  }

}


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

public enum CanvasItemMode {
  NONE,
  SELECTED,
  MOVING,
  RESIZING,
  DRAWING;

  public string to_string() {
    switch( this ) {
      case NONE     :  return( "none" );
      case SELECTED :  return( "selected" );
      case MOVING   :  return( "moving" );
      case RESIZING :  return( "resizing" );
      case DRAWING  :  return( "drawing" );
      default       :  assert_not_reached();
    }
  }

  public static CanvasItemMode parse( string value ) {
    switch( value ) {
      case "none"     :  return( NONE );
      case "selected" :  return( SELECTED );
      case "moving"   :  return( MOVING );
      case "resizing" :  return( RESIZING );
      case "drawing"  :  return( DRAWING );
      default         :  assert_not_reached();
    }
  }

  /* Returns true if the item can be moved */
  public bool can_move() {
    return( (this == SELECTED) || (this == MOVING) );
  }

  /* Returns true if the item is being moved/resized */
  public bool moving() {
    return( (this == MOVING) || (this == RESIZING) );
  }

  /* Returns the alpha value to use for drawing an item based on the current mode */
  public double alpha( double dflt = 1.0 ) {
    return( ((this == MOVING) || (this == RESIZING)) ? (dflt * 0.5) : dflt );
  }

  /* Returns true if the canvas item should display the selectors */
  public bool draw_selectors() {
    return( (this == SELECTED) || (this == RESIZING) );
  }

}

public enum CanvasItemPathType {
  STROKE,
  FILL,
  CLIP;

  /* Returns true when the given coordinates are within the given path */
  public bool is_within( Context ctx, double x, double y ) {
    switch( this ) {
      case FILL   :  return( ctx.in_fill( x, y ) );
      case STROKE :  return( ctx.in_stroke( x, y ) );
      case CLIP   :  return( ctx.in_clip( x, y ) );
      default     :  assert_not_reached();
    }
  }
}

public delegate void CanvasItemClickAction( CanvasItem item );
public delegate void CanvasItemScaleAction( CanvasItem item, double value );
public delegate void CanvasItemSpinnerAction( CanvasItem item, int value );

public class CanvasItem {

  private const double selector_size = 12;

  private CanvasRect           _bbox      = new CanvasRect();
  private CanvasItemMode       _mode      = CanvasItemMode.NONE;
  private CanvasItemProperties _props     = new CanvasItemProperties();
  private Cairo.Path?          _path      = null;
  private CanvasItemPathType   _path_type = CanvasItemPathType.FILL;

  protected Array<CanvasPoint> points { get; set; default = new Array<CanvasPoint>(); }
  protected Canvas             canvas { get; private set; }

  protected double selector_width {
    get {
      return( selector_size * (1 / canvas.image.width_scale) );
    }
  }
  protected double selector_height {
    get {
      return( selector_size * (1 / canvas.image.height_scale) );
    }
  }

  public CanvasItemType itype { get; private set; default = CanvasItemType.NONE; }
  public CanvasRect bbox {
    get {
      return( _bbox );
    }
    set {
      _bbox.copy( value );
      bbox_changed();
    }
  }
  public CanvasItemMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        if( _mode.moving() ) {
          last_bbox.copy( bbox );
        }
        mode_changed();
      }
    }
  }
  public CanvasItemProperties props {
    get {
      return( _props );
    }
    set {
      if( !_props.equals( value ) ) {
        last_props.copy( _props );
        _props.copy( value );
      }
    }
  }
  public CanvasItemProperties last_props { get; private set; default = new CanvasItemProperties(); }
  public CanvasRect           last_bbox  { get; private set; default = new CanvasRect(); }

  /* Constructor */
  public CanvasItem( CanvasItemType type, Canvas canvas, CanvasItemProperties props ) {

    this.canvas = canvas;

    this.itype = type;
    this.props.copy( props );

  }

  /* Creates a copy of the given canvas item */
  public virtual void copy( CanvasItem item ) {

    _bbox.copy( item.bbox );
    _mode = item.mode;
    props.copy( item.props );

    for( int i=0; i<item.points.length; i++ ) {
      points.index( i ).copy( item.points.index( i ) );
    }

  }

  /*
   Creates a duplicate of this canvas item and returns it to the calling
   function.
  */
  public virtual CanvasItem duplicate() {
    assert_not_reached();
  }

  /* Called whenever the bounding box changes */
  protected virtual void bbox_changed() {}

  /* Called whenever the mode changes */
  protected virtual void mode_changed() {}

  /* Moves the item by the given amount */
  public virtual void move_item( double diffx, double diffy ) {
    mode = CanvasItemMode.MOVING;
    bbox.x += diffx;
    bbox.y += diffy;
    bbox_changed();
  }

  /*
   This should be called in the move_selector method if the item responds to the
   shift key.
  */
  protected void adjust_diffs( bool shift, CanvasRect box, ref double diffx, ref double diffy ) {
    if( !shift ) return;
    if( box.width != box.height ) {
      box.width  = (box.width < box.height) ? box.width : box.height;
      box.height = (box.width < box.height) ? box.width : box.height;
    }
    if( Math.fabs( diffx ) < Math.fabs( diffy ) ) {
      diffx = diffy;
    } else {
      diffy = diffx;
    }
  }

  /* Adjusts the specified selector by the given amount */
  public virtual void move_selector( int index, double diffx, double diffy, bool shift ) {}

  /* If we need to draw something, update the item with the given cursor location */
  public virtual void draw( double x, double y ) {}

  /* Returns the type of cursor to use for the given selection cursor */
  public virtual CursorType? get_selector_cursor( int index ) {
    return( CursorType.HAND2 );
  }

  /* Returns the bounding box of the given selector */
  private void selector_bbox( int index, CanvasRect rect ) {
    var sel     = points.index( index );
    rect.x      = sel.x - (selector_width  / 2);
    rect.y      = sel.y - (selector_height / 2);
    rect.width  = selector_width;
    rect.height = selector_height;
  }

  /* Returns true if the given coordinates are within this item */
  public virtual bool is_within( double x, double y ) {
    var surface = new ImageSurface( Cairo.Format.ARGB32, canvas.image.info.width, canvas.image.info.height );
    var context = new Context( surface );
    context.append_path( _path );
    return( _path_type.is_within( context, x, y ) );
  }

  /* Returns the selector index that is below the current pointer coordinate */
  public int is_within_selector( double x, double y ) {
    if( !mode.draw_selectors() ) return( -1 );
    var box = new CanvasRect();
    for( int i=0; i<points.length; i++ ) {
      if( points.index( i ).kind.draw() ) {
        selector_bbox( i, box );
        if( box.contains( x, y ) ) {
          return( i );
        }
      }
    }
    return( -1 );
  }

  /* Saves the current path so that we can calculate is_within */
  protected void save_path( Context ctx, CanvasItemPathType type ) {
    _path      = ctx.copy_path_flat();
    _path_type = type;
  }

  /****************************************************************************/
  //  CONTEXTUAL MENU
  /****************************************************************************/

  /* Add contextual menu fields from the associated item */
  public virtual void add_contextual_menu_items( Box box ) {}

  /* Returns a menuitem with the given label, action and (optional) keyboard shortcut */
  public ModelButton add_contextual_menuitem( Box box, string label, string? shortcut, CanvasItemClickAction action ) {

    var btn = new ModelButton();
    btn.clicked.connect(() => {
      action( this );
    });

    if( shortcut != null ) {
      btn.get_child().destroy();
      btn.add( new Granite.AccelLabel( label, shortcut ) );
    } else {
      btn.text = label;
    }

    box.pack_start( btn, false, false );

    return( btn );

  }

  /* Adds a horizontal separator item to the contextual menu */
  public Separator add_contextual_separator( Box box ) {

    var sep = new Separator( Orientation.HORIZONTAL );

    box.pack_start( sep, false, true );

    return( sep );

  }

  /* Creates a scale widget for the contextual menu */
  protected Scale add_contextual_scale( Box box, string label, double min, double max, double step, double dflt, CanvasItemScaleAction action ) {

    var lbl = new Label( label );
    lbl.use_markup = true;
    lbl.halign     = Align.START;

    var scale = new Scale.with_range( Orientation.HORIZONTAL, min, max, step );
    scale.set_value( dflt );
    scale.draw_value = false;
    scale.width_request = 200;
    scale.value_changed.connect(() => {
      action( this, scale.get_value() );
    });

    var scale_box = new Box( Orientation.HORIZONTAL, 10 );
    scale_box.border_width = 10;
    scale_box.pack_start( lbl,   false, false );
    scale_box.pack_start( scale, true, true );

    box.pack_start( scale_box, false, true );

    return( scale );

  }

  /* Creates a scale widget for the contextual menu */
  protected SpinButton add_contextual_spinner( Box box, string label, int min, int max, int step, int dflt, CanvasItemSpinnerAction action ) {

    var lbl = new Label( label );
    lbl.use_markup = true;
    lbl.halign     = Align.START;

    var sb = new SpinButton.with_range( (double)min, (double)max, (double)step );
    sb.set_value( (double)dflt );
    sb.digits = max.to_string().char_count();
    sb.value_changed.connect(() => {
      action( this, (int)sb.get_value() );
    });

    var sb_box = new Box( Orientation.HORIZONTAL, 10 );
    sb_box.border_width = 10;
    sb_box.pack_start( lbl, false, false );
    sb_box.pack_start( sb,  true,  true );

    box.pack_start( sb_box, false, true );

    return( sb );

  }


  /****************************************************************************/
  //  DRAW METHODS
  /****************************************************************************/

  /* Draw the current item */
  public virtual void draw_item( Context ctx ) {}

  /* Draw the selection boxes */
  public void draw_selectors( Context ctx ) {

    if( !mode.draw_selectors() ) return;

    var black = Utils.color_from_string( "black" );
    var box   = new CanvasRect();

    for( int i=0; i<points.length; i++ ) {

      if( points.index( i ).kind.draw() ) {

        selector_bbox( i, box );

        ctx.set_line_width( 1 );

        /* Draw the selection rectangle */
        Utils.set_context_color( ctx, points.index( i ).kind.color() );
        ctx.rectangle( box.x, box.y, box.width, box.height );
        ctx.fill_preserve();

        /* Draw the stroke */
        Utils.set_context_color( ctx, black );
        ctx.stroke();

      }

    }

  }

  /****************************************************************************/
  //  SAVE/LOAD
  /****************************************************************************/

  /* Saves the item in XML format */
  public virtual Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "item" );
    node->set_prop( "type", itype.to_string() );
    node->set_prop( "x",    bbox.x.to_string() );
    node->set_prop( "y",    bbox.y.to_string() );
    node->set_prop( "w",    bbox.width.to_string() );
    node->set_prop( "h",    bbox.height.to_string() );
    node->set_prop( "mode", mode.to_string() );
    node->add_child( props.save() );
    return( node );
  }

  /* Loads the item in XML format */
  public virtual void load( Xml.Node* node ) {

    var t = node->get_prop( "type" );
    if( t != null ) {
      itype = CanvasItemType.parse( t );
    }
    var x = node->get_prop( "x" );
    if( x != null ) {
      bbox.x = int.parse( x );
    }
    var y = node->get_prop( "y" );
    if( y != null ) {
      bbox.y = int.parse( y );
    }
    var w = node->get_prop( "w" );
    if( w != null ) {
      bbox.width = int.parse( w );
    }
    var h = node->get_prop( "h" );
    if( h != null ) {
      bbox.height = int.parse( h );
    }
    var m = node->get_prop( "mode" );
    if( m != null ) {
      mode = CanvasItemMode.parse( m );
    }

    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "properties") ) {
        props.load( it );
      }
    }

  }

  /* Returns the canvas item type from the given XML node */
  public static CanvasItemType get_type_from_xml( Xml.Node* node ) {
    var t = node->get_prop( "type" );
    if( t != null ) {
      return( CanvasItemType.parse( t ) );
    }
    return( CanvasItemType.NONE );
  }

}



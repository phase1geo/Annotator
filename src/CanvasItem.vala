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

public enum CanvasItemMode {
  NONE,
  SELECTED,
  MOVING,
  RESIZING,
  EDITING,
  DRAWING;

  public string to_string() {
    switch( this ) {
      case NONE     :  return( "none" );
      case SELECTED :  return( "selected" );
      case MOVING   :  return( "moving" );
      case RESIZING :  return( "resizing" );
      case EDITING  :  return( "editing" );
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
      case "editing"  :  return( EDITING );
      case "drawing"  :  return( DRAWING );
      default         :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns true if the item can be moved
  public bool can_move() {
    return( (this == SELECTED) || (this == MOVING) );
  }

  //-------------------------------------------------------------
  // Returns true if the item is being moved/resized
  public bool moving() {
    return( (this == MOVING) || (this == RESIZING) );
  }

  //-------------------------------------------------------------
  // Returns the alpha value to use for drawing an item based on
  // the current mode
  public double alpha( double dflt = 1.0 ) {
    return( ((this == MOVING) || (this == RESIZING)) ? (dflt * 0.5) : dflt );
  }

  //-------------------------------------------------------------
  // Returns true if the canvas item should display the selectors
  public bool draw_selectors() {
    return( (this == SELECTED) || (this == RESIZING) );
  }

}

public enum CanvasItemColor {
  COLOR,
  DARK,
  LIGHT
}

public enum CanvasItemPathType {
  STROKE,
  FILL,
  CLIP;

  //-------------------------------------------------------------
  // Returns true when the given coordinates are within the given
  // path
  public bool is_within( Context ctx, double x, double y ) {
    switch( this ) {
      case FILL   :  return( ctx.in_fill( x, y ) );
      case STROKE :  return( ctx.in_stroke( x, y ) );
      case CLIP   :  return( ctx.in_clip( x, y ) );
      default     :  assert_not_reached();
    }
  }

  public string to_string() {
    switch( this ) {
      case FILL   :  return( "fill" );
      case STROKE :  return( "stroke" );
      case CLIP   :  return( "clip" );
      default     :  return( "unknown" );
    }
  }
}

public class CanvasItem {

  private const double selector_size = 12;

  private CanvasRect           _bbox      = new CanvasRect();
  private CanvasItemMode       _mode      = CanvasItemMode.NONE;
  private CanvasItemProperties _props     = new CanvasItemProperties();
  private Cairo.Path?          _path      = null;
  private CanvasItemPathType   _path_type = CanvasItemPathType.FILL;
  private Cursor               _sel_cursor;
  private double               _angle      = 0.0;
  private double               _rot_hx     = 0.0;    // Virtual pointer position while dragging the rotator
  private double               _rot_hy     = 0.0;
  private bool                 _rot_active = false;

  protected Array<CanvasPoint> points { get; set; default = new Array<CanvasPoint>(); }
  protected Canvas             canvas { get; private set; }

  // Index of the rotation selector in points (-1 if the item cannot be rotated)
  protected int rotator_index { get; set; default = -1; }

  // Extra distance (beyond bbox) that the rotation selector should clear, for
  // items which draw a padded border around their bbox
  protected double rotator_margin { get; set; default = 0.0; }

  protected double selector_width {
    get {
      return( selector_size * (1 / (canvas.image.width_scale * canvas.zoom_factor)) );
    }
  }
  protected double selector_height {
    get {
      return( selector_size * (1 / (canvas.image.height_scale * canvas.zoom_factor)) );
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
        if( (_mode == CanvasItemMode.NONE) && (value == CanvasItemMode.SELECTED) ) {
          if( any_selectors_hidden() ) {
            reset_selectors();
            set_selector_visual( 0, true );
          }
        }
        _mode       = value;
        _rot_active = false;
        if( _mode.moving() ) {
          last_bbox.copy( bbox );
          last_angle = _angle;
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

  // Rotation of the item (in radians, clockwise) about the center of its bounding box
  public double angle {
    get {
      return( _angle );
    }
    set {
      if( _angle != value ) {
        _angle = value;
        bbox_changed();
      }
    }
  }
  public double last_angle { get; private set; default = 0.0; }

  //-------------------------------------------------------------
  // Constructor
  public CanvasItem( CanvasItemType type, Canvas canvas, CanvasItemProperties? props ) {

    this.canvas = canvas;
    this.itype  = type;

    if( props != null ) {
      this.props.copy( props );
    }

    _sel_cursor = new Cursor.from_name( "grab", null );

  }

  //-------------------------------------------------------------
  // Creates a copy of the given canvas item
  public virtual void copy( CanvasItem item ) {

    _bbox.copy( item.bbox );
    _angle     = item.angle;
    last_angle = item.last_angle;
    _mode      = item.mode;
    props.copy( item.props );

    points.remove_range( 0, points.length );
    for( int i=0; i<item.points.length; i++ ) {
      var point = new CanvasPoint.from_point( item.points.index( i ) );
      points.append_val( point );
    }

  }

  //-------------------------------------------------------------
  // Returns the index of the selector that is used to resize
  // this item on creation.
  public virtual int resize_selector() {
    return( -1 );
  }

  //-------------------------------------------------------------
  // Creates a duplicate of this canvas item and returns it to
  // the calling function.
  public virtual CanvasItem duplicate() {
    assert_not_reached();
  }

  //-------------------------------------------------------------
  // Called whenever the bounding box changes
  protected virtual void bbox_changed() {}

  //-------------------------------------------------------------
  // Called whenever the mode changes
  protected virtual void mode_changed() {}

  //-------------------------------------------------------------
  // Moves the item by the given amount
  public virtual void move_item( double diffx, double diffy, bool moving = true ) {
    if( moving ) {
      mode = CanvasItemMode.MOVING;
    }
    bbox.x += diffx;
    bbox.y += diffy;
    bbox_changed();
  }

  //-------------------------------------------------------------
  // This should be called in the move_selector method if the item
  // responds to the shift key.
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

  //-------------------------------------------------------------
  //  ROTATION SUPPORT
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Rotates the given point by the given angle around (cx, cy)
  protected void rotate_point( double cx, double cy, double a, double x, double y, out double rx, out double ry ) {
    var c  = Math.cos( a );
    var s  = Math.sin( a );
    var dx = x - cx;
    var dy = y - cy;
    rx = cx + ((dx * c) - (dy * s));
    ry = cy + ((dx * s) + (dy * c));
  }

  //-------------------------------------------------------------
  // Rotates the given (unrotated) point around the center of the
  // given box using the item's current angle
  protected void rotate_about_center( CanvasRect box, double x, double y, out double rx, out double ry ) {
    if( _angle == 0.0 ) {
      rx = x;
      ry = y;
    } else {
      rotate_point( box.mid_x(), box.mid_y(), _angle, x, y, out rx, out ry );
    }
  }

  //-------------------------------------------------------------
  // Converts the given canvas coordinates into the item's
  // unrotated space (the inverse of rotate_about_center).  Use
  // this to hit-test or to convert mouse positions.
  protected void unrotate_about_center( CanvasRect box, double x, double y, out double lx, out double ly ) {
    if( _angle == 0.0 ) {
      lx = x;
      ly = y;
    } else {
      rotate_point( box.mid_x(), box.mid_y(), (0 - _angle), x, y, out lx, out ly );
    }
  }

  //-------------------------------------------------------------
  // Applies the item's rotation to the given context (about the
  // center of the bounding box).  The caller is responsible for
  // saving and restoring the context's matrix.
  protected void rotate_context( Context ctx ) {
    ctx.translate( bbox.mid_x(), bbox.mid_y() );
    ctx.rotate( _angle );
    ctx.translate( (0 - bbox.mid_x()), (0 - bbox.mid_y()) );
  }

  //-------------------------------------------------------------
  // Sets the given point to the given unrotated coordinates
  // after applying the item's rotation to it.  This should be
  // used in bbox_changed to position the selectors.
  protected void set_point_rotated( int index, double x, double y ) {
    double rx, ry;
    rotate_about_center( bbox, x, y, out rx, out ry );
    points.index( index ).copy_coords( rx, ry );
  }

  //-------------------------------------------------------------
  // Converts pointer differences (in canvas coordinates) into the
  // item's unrotated coordinate space.  Call this at the start of
  // move_selector for resize selectors.
  protected void unrotate_diffs( ref double diffx, ref double diffy ) {
    if( _angle == 0.0 ) return;
    var c  = Math.cos( _angle );
    var s  = Math.sin( _angle );
    var dx = diffx;
    var dy = diffy;
    diffx = (dx * c) + (dy * s);
    diffy = (dy * c) - (dx * s);
  }

  //-------------------------------------------------------------
  // Gets the anchor for a resize operation: the point opposite
  // the selector being dragged.  Returns its position in canvas
  // coordinates (wx, wy) and in the item's unrotated space
  // (lx, ly).  Call this BEFORE modifying the bounding box.
  protected void get_anchor( int index, out double lx, out double ly, out double wx, out double wy ) {
    wx = (2 * bbox.mid_x()) - points.index( index ).x;
    wy = (2 * bbox.mid_y()) - points.index( index ).y;
    if( _angle == 0.0 ) {
      lx = wx;
      ly = wy;
    } else {
      rotate_point( bbox.mid_x(), bbox.mid_y(), (0 - _angle), wx, wy, out lx, out ly );
    }
  }

  //-------------------------------------------------------------
  // Shifts the given (resized) box so that the anchor stays at the
  // same location on screen.  Resizing a rotated box moves its
  // center, which would otherwise make the opposite side drift.
  protected void fix_anchor( CanvasRect box, double lx, double ly, double wx, double wy ) {
    if( _angle == 0.0 ) return;
    double nx, ny;
    rotate_point( box.mid_x(), box.mid_y(), _angle, lx, ly, out nx, out ny );
    box.x += (wx - nx);
    box.y += (wy - ny);
  }

  //-------------------------------------------------------------
  // Positions the rotation selector above the top of the item.
  // The distance is kept constant on screen, so this is done at
  // draw time rather than in bbox_changed.
  protected void place_rotator() {
    if( rotator_index < 0 ) return;
    var gap = selector_height * 2.5;
    set_point_rotated( rotator_index, bbox.mid_x(), (bbox.y1() - rotator_margin - gap) );
  }

  //-------------------------------------------------------------
  // Handles dragging of the rotation selector.  Call this from
  // move_selector when the rotator is the selector being moved.
  // Holding shift snaps the angle to 15 degree increments.
  protected void rotate_selector( int index, double diffx, double diffy, bool shift ) {

    // Track where the pointer really is, since the selector itself
    // is constrained to a fixed distance from the item
    if( !_rot_active ) {
      _rot_hx     = points.index( index ).x;
      _rot_hy     = points.index( index ).y;
      _rot_active = true;
    }
    _rot_hx += diffx;
    _rot_hy += diffy;

    var a = Math.atan2( (_rot_hy - bbox.mid_y()), (_rot_hx - bbox.mid_x()) ) + (Math.PI / 2);

    if( shift ) {
      var step = Math.PI / 12;
      a = Math.round( a / step ) * step;
    }

    while( a < 0 ) {
      a += (2 * Math.PI);
    }
    while( a >= (2 * Math.PI) ) {
      a -= (2 * Math.PI);
    }

    angle = a;

  }

  //-------------------------------------------------------------
  // Returns true if any of the selectors are hidden
  private bool any_selectors_hidden() {
    bool hidden = false;
    for( int i=0; i<points.length; i++ ) {
      hidden |= points.index( i ).kind.is_hidden();
    }
    return( hidden );
  }

  //-------------------------------------------------------------
  // Resets all selectors to be shown
  private void reset_selectors() {
    for( int i=0; i<points.length; i++ ) {
      points.index( i ).reset_visual();
    }
  }

  //-------------------------------------------------------------
  // Called when the selectors need to be adjusted from shown or
  // hidden
  protected void set_selector_visual( int index, bool hide ) {
    CanvasPointType kind = points.index( index ).kind;
    for( int i=0; i<points.length; i++ ) {
      points.index( i ).set_visual( kind, hide );
    }
  }

  //-------------------------------------------------------------
  // Adjusts the specified selector by the given amount
  public virtual void move_selector( int index, double diffx, double diffy, bool shift ) {}

  //-------------------------------------------------------------
  // If we need to draw something, update the item with the given
  // cursor location
  public virtual void draw( double x, double y ) {}

  //-------------------------------------------------------------
  // Returns the type of cursor to use for the given selection
  // cursor
  public virtual Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  //-------------------------------------------------------------
  // Returns a tooltip to display for the given selector.  Only
  // control points should return a valid string.  To avoid
  // displaying a tooltip, return a value of null.
  public virtual string? get_selector_tooltip( int index ) {
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the undo item associated with a release of the given
  // selector
  public virtual UndoItem? get_undo_item_for_selector( int index ) {
    _rot_active = false;
    var name = (index == rotator_index) ? _( "rotate item" ) : _( "resize item" );
    return( new UndoItemBoxChange.with_item( name, this ) );
  }

  //-------------------------------------------------------------
  // Returns the bounding box of the given selector
  private void selector_bbox( int index, CanvasRect rect ) {
    var sel     = points.index( index );
    rect.x      = sel.x - (selector_width  / 2);
    rect.y      = sel.y - (selector_height / 2);
    rect.width  = selector_width;
    rect.height = selector_height;
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates are within this item
  public virtual bool is_within( double x, double y ) {
    var surface = new ImageSurface( Cairo.Format.ARGB32, canvas.image.info.width, canvas.image.info.height );
    var context = new Context( surface );
    context.set_line_width( props.stroke_width.width() );
    context.append_path( _path );
    return( _path_type.is_within( context, x, y ) );
  }

  //-------------------------------------------------------------
  // Returns the extents of the shape
  public void get_extents( out double x1, out double y1, out double x2, out double y2 ) {
    var surface = new ImageSurface( Cairo.Format.ARGB32, (int)(bbox.width * 2), (int)(bbox.height * 2) );
    var context = new Context( surface );
    if( _path == null ) {
      draw_item( context );
    }
    context.set_line_width( props.stroke_width.width() );
    context.append_path( _path );
    context.stroke_extents( out x1, out y1, out x2, out y2 );
  }

  //-------------------------------------------------------------
  // Returns the selector index that is below the current pointer
  // coordinate
  public int is_within_selector( double x, double y ) {
    if( !mode.draw_selectors() ) return( -1 );
    place_rotator();
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

  //-------------------------------------------------------------
  // Saves the current path so that we can calculate is_within
  protected void save_path( Context ctx, CanvasItemPathType type ) {
    _path      = ctx.copy_path_flat();
    _path_type = type;
  }

  //-------------------------------------------------------------
  //  CONTEXTUAL MENU
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Add contextual menu fields from the associated item
  public virtual void add_contextual_menu_items( CanvasItemMenu menu ) {}

  //-------------------------------------------------------------
  //  DRAW METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Draw the current item
  public virtual void draw_item( Context ctx, CanvasItemColor color = CanvasItemColor.COLOR ) {}

  public void draw_extents( Context ctx ) {
    double x1, y1, x2, y2;
    var red = Utils.color_from_string( "red" );
    get_extents( out x1, out y1, out x2, out y2 );
    ctx.set_line_width( 1 );
    Utils.set_context_color( ctx, red );
    ctx.rectangle( x1, y1, (x2 - x1), (y2 - y1) );
    ctx.stroke();
  }

  //-------------------------------------------------------------
  // Draw the selection boxes
  public void draw_selectors( Context ctx ) {

    if( !mode.draw_selectors() ) return;

    var black = Utils.color_from_string( "black" );
    var box   = new CanvasRect();

    // Draw a line connecting the item to its rotation selector
    if( rotator_index >= 0 ) {
      double tx, ty;
      place_rotator();
      rotate_about_center( bbox, bbox.mid_x(), (bbox.y1() - rotator_margin), out tx, out ty );
      ctx.set_line_width( 1 );
      Utils.set_context_color( ctx, black );
      ctx.move_to( tx, ty );
      ctx.line_to( points.index( rotator_index ).x, points.index( rotator_index ).y );
      ctx.stroke();
    }

    for( int i=0; i<points.length; i++ ) {

      if( points.index( i ).kind.draw() ) {

        selector_bbox( i, box );

        ctx.set_line_width( 1 );

        // Draw the selection rectangle
        Utils.set_context_color( ctx, points.index( i ).kind.color() );
        ctx.rectangle( box.x, box.y, box.width, box.height );
        ctx.fill_preserve();

        // Draw the stroke
        Utils.set_context_color( ctx, black );
        ctx.stroke();

      }

    }

  }

  //-------------------------------------------------------------
  // Sets the color of the given Context based on the provided
  // color attribute, property color and alpha value.
  protected void set_color( Context ctx, CanvasItemColor color_type, Gdk.RGBA color, double alpha ) {
    switch( color_type ) {
      case CanvasItemColor.COLOR :  Utils.set_context_color_with_alpha( ctx, color, alpha );  break;
      case CanvasItemColor.DARK  :  Utils.set_context_color( ctx, Utils.color_from_string( "white" ) );  break;
      case CanvasItemColor.LIGHT :  Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );  break;
    }
  }

  //-------------------------------------------------------------
  //  SAVE/LOAD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Saves the item in XML format
  public virtual Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = new Xml.Node( null, "item" );
    node->set_prop( "type", itype.to_string() );
    node->set_prop( "x",    bbox.x.to_string() );
    node->set_prop( "y",    bbox.y.to_string() );
    node->set_prop( "w",    bbox.width.to_string() );
    node->set_prop( "h",    bbox.height.to_string() );
    node->set_prop( "mode", mode.to_string() );
    if( _angle != 0.0 ) {
      node->set_prop( "angle", _angle.to_string() );
    }
    node->add_child( props.save() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the item in XML format
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
    var a = node->get_prop( "angle" );
    if( a != null ) {
      _angle = double.parse( a );
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

    bbox_changed();

  }

  //-------------------------------------------------------------
  // Returns the canvas item type from the given XML node
  public static CanvasItemType get_type_from_xml( Xml.Node* node ) {
    var t = node->get_prop( "type" );
    if( t != null ) {
      return( CanvasItemType.parse( t ) );
    }
    return( CanvasItemType.NONE );
  }

}



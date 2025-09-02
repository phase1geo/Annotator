/*s
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

public class CanvasItemMagnifier : CanvasItem {

  private const double max_zoom  = 5.0;
  private const double min_zoom  = 1.5;
  private const double step_zoom = 0.5;

  private CanvasImage _image;
  private double      _orig_zoom   = 2.0;
  private double      _zoom_factor = 2.0;
  private CanvasRect  _zoom_rect   = new CanvasRect();
  private CanvasPoint _press0      = new CanvasPoint();
  private CanvasPoint _press2      = new CanvasPoint();
  private bool        _focus_moved = false;
  private Cursor[]    _sel_cursors;

  public double zoom_factor {
    get {
      return( _zoom_factor );
    }
    set {
      if( _zoom_factor != value ) {
        _zoom_factor = value;
        bbox_changed();
      }
    }
  }
  public double orig_zoom {
    get {
      return( _orig_zoom );
    }
  }

  /* Constructor */
  public CanvasItemMagnifier( Canvas canvas, double zoom_factor, CanvasItemProperties props ) {
    base( CanvasItemType.MAGNIFIER, canvas, props );
    _image       = canvas.image;
    _zoom_factor = zoom_factor;
    create_points();
    _sel_cursors = new Cursor[3];
    _sel_cursors[0] = new Cursor.from_name( "grab", null );
    _sel_cursors[1] = new Cursor.from_name( "se-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "crosshair", null );
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );  // Magnification
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Resizer
    points.append_val( new CanvasPoint( CanvasPointType.CONTROL ) );  // Focus point
  }

  /* Copies the contents of the given item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var mag_item = (CanvasItemMagnifier)item;
    if( mag_item != null ) {
      _zoom_factor = mag_item._zoom_factor;
      _focus_moved = mag_item._focus_moved;
    }
  }

  /* Returns a copy of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemMagnifier( canvas, _zoom_factor, props );
    item.copy( this );
    return( item );
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    var radius        = bbox.width / 2;
    var RAD_distance  = ((2 * Math.PI) / 8);
    var RAD_half_PI   = Math.PI / 2;
    var new_outer_RAD = RAD_distance * 3;
    var angle         = (((_zoom_factor - min_zoom) / (max_zoom - min_zoom)) - 1) * RAD_half_PI;

    var x0 = bbox.mid_x() + Math.cos( angle ) * radius;
    var y0 = bbox.mid_y() + Math.sin( angle ) * radius;

    var x1 = bbox.mid_x() + Math.cos( (RAD_distance * 3) - RAD_half_PI ) * radius;
    var y1 = bbox.mid_y() + Math.sin( (RAD_distance * 3) - RAD_half_PI ) * radius;

    points.index( 0 ).copy_coords( x0, y0 );
    points.index( 1 ).copy_coords( x1, y1 );

    if( !_focus_moved ) {
      points.index( 2 ).copy_coords( bbox.mid_x(), bbox.mid_y() );
    }

    update_zoom_rect();

  }

  /*
   If the mode changes to RESIZING, capture the current zoom factor point in case it
   is the one being moved so that we can recalculate the proper zoom_factor value.
  */
  protected override void mode_changed() {
    if( mode == CanvasItemMode.RESIZING ) {
      _press0.copy( points.index( 0 ) );
      _press2.copy( points.index( 2 ) );
      _orig_zoom = _zoom_factor;
    }
  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    if( index == 0 ) {
      _press0.x += diffx;
      _press0.y += diffy;
      var b = (_press0.x - bbox.mid_x());
      var a = (bbox.mid_y() - _press0.y);
      if( (a >= 0) && (b >= 0) ) {
        var half_PI = Math.PI / 2;
        var angle   = Math.atan( a / b );    // 0 = max zoom (5), PI/2 = min zoom (1)
        _zoom_factor = ((1 - (angle / half_PI)) * (max_zoom - min_zoom)) + min_zoom;
      }
    } else if( index == 1 ) {
      box.width  += diffy;
      box.height += diffy;
    } else {
      points.index( 2 ).x += diffx;
      points.index( 2 ).y += diffy;
      _focus_moved = true;
    }

    if( box.width >= (selector_width * 3) ) {
      bbox = box;
    }

  }

  /* Returns the zoom rectangle */
  private void update_zoom_rect() {
    var width  = bbox.width / _zoom_factor;
    var adjust = width / 2;
    _zoom_rect.copy_coords( (points.index( 2 ).x - adjust), (points.index( 2 ).y - adjust), width, width );
  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    switch( index ) {
      case 0  :  return( _sel_cursors[0] );
      case 1  :  return( _sel_cursors[1] );
      default :  return( _sel_cursors[2] );
    }
  }

  public override string? get_selector_tooltip( int index ) {
    switch( index ) {
      case 0 :  return( _( "Drag to control amount of zoom" ) );
      case 2 :  return( _( "Drag to change area to magnify" ) );
    }
    return( null );
  }

  public override UndoItem? get_undo_item_for_selector( int index ) {
    if( index == 0 ) {
      return( new UndoItemMagnifierZoom( this, _orig_zoom, _zoom_factor ) );
    } else if( index == 2 ) {
      return( new UndoItemMagnifierFocus( this, _press2, points.index( 2 ) ) );
    } else {
      return( base.get_undo_item_for_selector( index ) );
    }
  }

  /* Called to restore the given point */
  public void set_focus_point( CanvasPoint point ) {
    points.index( 2 ).copy( point );
    _focus_moved = (point.x != bbox.mid_x()) || (point.y != bbox.mid_y());
    bbox_changed();
  }

  /* Creates the contextual menu items */
  protected override void add_contextual_menu_items( CanvasItemMenu menu ) {

    menu.add_scale( this, _( "Magnification:" ), min_zoom, max_zoom, step_zoom, _zoom_factor,
      (item, value) => {
        _zoom_factor = value;
        bbox_changed();
        canvas.queue_draw();
      },
      (item, old_value, new_value) => {
        if( old_value != new_value ) {
          canvas.undo_buffer.add_item( new UndoItemMagnifierZoom( this, old_value, new_value ) );
        }
      }
    );

    menu.add_menu_item( this, _( "Reset Focal Point" ), null, _focus_moved, (item) => {
      var old_point = new CanvasPoint.from_point( points.index( 2 ) );
      _focus_moved = false;
      bbox_changed();
      canvas.undo_buffer.add_item( new UndoItemMagnifierFocus( this, old_point, points.index( 2 ) ) );
      canvas.queue_draw();
    });

  }

  //-------------------------------------------------------------
  // Saves this item as XML.
  public override Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    node->set_prop( "zoom-factor", _zoom_factor.to_string() );
    node->add_child( points.index( 2 ).save( "focus" ) );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this item from XML.
  public override void load( Xml.Node* node ) {
    var f = node->get_prop( "zoom-factor" );
    if( f != null ) {
      _zoom_factor = double.parse( f );
    }
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "focus") ) {
        points.index( 2 ).load( it );
        _focus_moved = true;
      }
    }
    base.load( node );
  }

  /* Helper function that finds the two tangential points on a circle to a given point */
  private bool find_tangents( CanvasPoint center, double radius, CanvasPoint external, CanvasPoint pt1, CanvasPoint pt2 ) {

    var dx  = center.x - external.x;
    var dy  = center.y - external.y;
    var dsq = (dx * dx) + (dy * dy);
    var rsq = radius * radius;
    if( dsq < rsq ) {
      return( false );
    }
    var l = Math.sqrt( dsq - rsq );

    return( find_circle_circle_intersections( center, radius, external, l, pt1, pt2 ) );

  }

  /* Helper function that finds the two points where two circles intersect */
  private bool find_circle_circle_intersections( CanvasPoint c0, double r0, CanvasPoint c1, double r1, CanvasPoint pt1, CanvasPoint pt2 ) {

    var dx   = c0.x - c1.x;
    var dy   = c0.y - c1.y;
    var dist = Math.sqrt( (dx * dx) + (dy * dy) );
    if( (dist > (r0 + r1)) || (dist < Math.fabs( r0 - r1 )) || ((dist == 0) && (r0 == r1)) ) {
      return( false );
    }
    var a = ((r0 * r0) - (r1 * r1) + (dist * dist)) / (2 * dist);
    var h = Math.sqrt( (r0 * r0) - (a * a) );
    var cx2 = c0.x + a * (c1.x - c0.x) / dist;
    var cy2 = c0.y + a * (c1.y - c0.y) / dist;

    pt1.copy_coords( (cx2 + (h * (c1.y - c0.y) / dist)), (cy2 - (h * (c1.x - c0.x) / dist)) );
    pt2.copy_coords( (cx2 - (h * (c1.y - c0.y) / dist)), (cy2 + (h * (c1.x - c0.x) / dist)) );

    return( true );

  }

  /* Draw the focal point triangle */
  private void draw_focal_point( Context ctx ) {

    if( !_focus_moved ) return;

    var center = new CanvasPoint.from_coords( bbox.mid_x(), bbox.mid_y() );
    var pt1    = new CanvasPoint();
    var pt2    = new CanvasPoint();

    if( !find_tangents( center, (bbox.width / 2), points.index( 2 ), pt1, pt2 ) ) return;

    /* Draw the triangle */
    Utils.set_context_color_with_alpha( ctx, props.color, 0.2 );
    ctx.set_line_width( 1 );
    ctx.move_to( pt1.x, pt1.y );
    ctx.line_to( points.index( 2 ).x, points.index( 2 ).y );
    ctx.line_to( pt2.x, pt2.y );
    ctx.close_path();
    ctx.fill();

    /*
    Utils.set_context_color_with_alpha( ctx, _image.average_color, 0.5 );
    ctx.stroke();
    */

  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var pixbuf = _image.get_pixbuf_for_rect( _zoom_rect );
    var black  = Utils.color_from_string( "black" );

    draw_focal_point( ctx );

    Utils.set_context_color_with_alpha( ctx, black, 0.5 );
    ctx.set_line_width( 5 );
    ctx.arc( bbox.mid_x(), bbox.mid_y(), (bbox.width / 2), 0, (2 * Math.PI) );
    save_path( ctx, CanvasItemPathType.FILL );
    ctx.stroke_preserve();

    ctx.save();
    ctx.clip();
    ctx.new_path();
   	ctx.scale( _zoom_factor, _zoom_factor );
    cairo_set_source_pixbuf( ctx, pixbuf, (bbox.x / _zoom_factor), (bbox.y / _zoom_factor) );
   	ctx.paint();
   	ctx.restore();

  }

}



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

//-------------------------------------------------------------
// Base class for canvas items that can be rotated.  The rotation
// is about the center of the item's bounding box (bbox), which is
// always kept in the item's own unrotated space.  Subclasses:
//
//  - add a CanvasPointType.ROTATOR point in create_points() and
//    set rotator_index to its index (rotator_margin can be set to
//    keep the selector clear of any padding drawn around bbox)
//  - position resize selectors with set_point_rotated() in
//    bbox_changed()
//  - call rotate_selector() from move_selector() when the rotator
//    is being dragged; otherwise use get_anchor(), unrotate_diffs()
//    and fix_anchor() to resize
//  - apply rotate_context() when drawing, and use
//    rotate_about_center() / unrotate_about_center() to convert
//    between canvas and item coordinates
public abstract class CanvasItemRotatable : CanvasItem {

  private double _angle      = 0.0;
  private double _rot_hx     = 0.0;    // Virtual pointer position while dragging the rotator
  private double _rot_hy     = 0.0;
  private bool   _rot_active = false;

  // Index of the rotation selector in points (-1 if not yet created)
  protected int rotator_index { get; set; default = -1; }

  // Extra distance (beyond bbox) that the rotation selector should clear, for
  // items which draw a padded border around their bbox
  protected double rotator_margin { get; set; default = 0.0; }

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
  protected CanvasItemRotatable( CanvasItemType type, Canvas canvas, CanvasItemProperties? props ) {
    base( type, canvas, props );
  }

  //-------------------------------------------------------------
  // Copies the rotation of the given item to ourselves
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var rot_item = item as CanvasItemRotatable;
    if( rot_item != null ) {
      _angle     = rot_item.angle;
      last_angle = rot_item.last_angle;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the mode changes.  Ends any rotation drag and
  // remembers the angle so that changes can be undone.
  protected override void mode_changed() {
    base.mode_changed();
    _rot_active = false;
    if( mode.moving() ) {
      last_angle = _angle;
    }
  }

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
  // Returns the undo item for a released selector
  public override UndoItem? get_undo_item_for_selector( int index ) {
    _rot_active = false;
    if( index == rotator_index ) {
      return( new UndoItemBoxChange.with_item( _( "rotate item" ), this ) );
    }
    return( base.get_undo_item_for_selector( index ) );
  }

  //-------------------------------------------------------------
  // Returns the index of the selector that contains the given
  // point (or -1 if none)
  public override int is_within_selector( double x, double y ) {
    place_rotator();
    return( base.is_within_selector( x, y ) );
  }

  //-------------------------------------------------------------
  // Draws the selection boxes along with a line connecting the
  // item to its rotation selector
  public override void draw_selectors( Context ctx ) {

    if( !mode.draw_selectors() ) return;

    if( rotator_index >= 0 ) {
      double tx, ty;
      place_rotator();
      rotate_about_center( bbox, bbox.mid_x(), (bbox.y1() - rotator_margin), out tx, out ty );
      ctx.set_line_width( 1 );
      Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );
      ctx.move_to( tx, ty );
      ctx.line_to( points.index( rotator_index ).x, points.index( rotator_index ).y );
      ctx.stroke();
    }

    base.draw_selectors( ctx );

  }

  //-------------------------------------------------------------
  // Saves the rotation (only if the item is rotated)
  public override Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    if( _angle != 0.0 ) {
      node->set_prop( "angle", _angle.to_string() );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the rotation.  This must happen before the base class
  // loads, since it calls bbox_changed() which positions selectors.
  public override void load( Xml.Node* node ) {
    var a = node->get_prop( "angle" );
    if( a != null ) {
      _angle = double.parse( a );
    }
    base.load( node );
  }

}

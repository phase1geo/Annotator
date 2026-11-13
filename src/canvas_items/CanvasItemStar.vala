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

public class CanvasItemStar : CanvasItem {

  private double   _inner_ratio = 0.381966;
  private Cursor[] _sel_cursors;

  public int num_points { get; set; default = 5; }

  //-------------------------------------------------------------
  // Constructor
  public CanvasItemStar( Canvas canvas, int point_num, CanvasItemProperties props ) {
    base( CanvasItemType.STAR, canvas, props );
    create_points();
    num_points = point_num;
    _sel_cursors = new Cursor[5];
    _sel_cursors[0] = new Cursor.from_name( "crosshair", null );
    _sel_cursors[1] = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[3] = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[4] = new Cursor.from_name( "se-resize", null );
  }

  private double regular_ratio( int n ) {
    if( n < 5 ) {
      return( 0.5 );
    }
    return( Math.cos( (2 * Math.PI) / n ) / Math.cos( Math.PI / n ) );
  }

  private double outer_radius() {
    return( Math.fmin( bbox.width, bbox.height ) / 2 );
  }

  //-------------------------------------------------------------
  // Creates the item points
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Outer radius
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Upper left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // Upper right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // Lower left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Lower right
    points.append_val( new CanvasPoint( CanvasPointType.ROTATOR ) );   // Rotator
    rotator_index = 5;
  }

  public override int resize_selector() {
    return( 4 );
  }

  //-------------------------------------------------------------
  // Copies the contents of the given item to ourselves
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var star = (CanvasItemStar)item;
    _inner_ratio = star._inner_ratio;
    num_points   = star.num_points;
  }

  //-------------------------------------------------------------
  // Returns a duplicate of this item
  public override CanvasItem duplicate() {
    var item = new CanvasItemStar( canvas, num_points, props );
    item.copy( this );
    return( item );
  }

  //-------------------------------------------------------------
  // Calculates the given star vertex in the item's unrotated space.
  // Rotation is applied separately when drawing and when placing
  // the selectors.
  private void calculate_point( int point_num, CanvasPoint point ) {

    var outer     = outer_radius();
    var RAD_dist  = (2 * Math.PI) / num_points;
    var outer_RAD = ((point_num / 2) + 1) * RAD_dist;
    var is_inner  = ((point_num % 2) == 0);
    var angle     = (is_inner ? (outer_RAD - (RAD_dist / 2)) : outer_RAD) - (Math.PI / 2);
    var radius    = is_inner ? (outer * _inner_ratio) : outer;

    point.copy_coords( bbox.mid_x() + (Math.cos( angle ) * radius),
                       bbox.mid_y() + (Math.sin( angle ) * radius) );

  }

  //-------------------------------------------------------------
  // Updates the selection boxes whenever the bounding box changes
  protected override void bbox_changed() {

    // Calculate the inner and outer control points
    var inner = new CanvasPoint();
    calculate_point( 0, inner );
    set_point_rotated( 0, inner.x, inner.y );

    // Update the selector positions for changing the boundary
    set_point_rotated( 1, bbox.x1(), bbox.y1() );
    set_point_rotated( 2, bbox.x2(), bbox.y1() );
    set_point_rotated( 3, bbox.x1(), bbox.y2() );
    set_point_rotated( 4, bbox.x2(), bbox.y2() );

    // The rotation selector (index 5) is positioned at draw time

  }

  //-------------------------------------------------------------
  // Adjusts the bounding box
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    if( index == rotator_index ) {
      rotate_selector( index, diffx, diffy, shift );
      return;
    }

    var box   = new CanvasRect.from_rect( bbox );
    var outer = outer_radius();
    double anchor_lx = 0, anchor_ly = 0, anchor_wx = 0, anchor_wy = 0;

    // Work in the item's unrotated space.  For the corner selectors,
    // remember where the opposite corner is so that it doesn't move.
    if( index > 0 ) {
      get_anchor( index, out anchor_lx, out anchor_ly, out anchor_wx, out anchor_wy );
    }
    unrotate_diffs( ref diffx, ref diffy );

    // If we are moving the selector representing the outer radius, update the box
    switch( index ) {
      case 0 :
        _inner_ratio = Math.fmax( 0.05, Math.fmin( 0.95, _inner_ratio - (diffy / outer) ) );
        break;
      case 1 :  box.x += diffy;  box.y += diffy;  box.width -= diffy;        box.height -= diffy;  break;
      case 2 :                   box.y += diffy;  box.width -= diffy;        box.height -= diffy;  break;
      case 3 :  box.x -= diffy;                   box.width += diffy;        box.height += diffy;  break;
      case 4 :                                    box.width += diffy;        box.height += diffy;  break;
    }

    if( box.height >= 1 ) {
      if( index > 0 ) {
        fix_anchor( box, anchor_lx, anchor_ly, anchor_wx, anchor_wy );
      }
      bbox = box;
    }

  }

  //-------------------------------------------------------------
  // Provides cursor to display when mouse cursor is hovering over
  // the given selector
  public override Cursor? get_selector_cursor( int index ) {
    if( index == rotator_index ) {
      return( base.get_selector_cursor( index ) );
    }
    return( _sel_cursors[index] );
  }

  //-------------------------------------------------------------
  // Adds the contextual menu items
  protected override void add_contextual_menu_items( CanvasItemMenu menu ) {

    menu.add_spinner( this, _( "Points:" ), 3, 50, 1, num_points,
      (item, value) => {
        num_points = value;
        bbox_changed();
        canvas.queue_draw();
      },
      (item, old_value, new_value) => {
        if( old_value != new_value ) {
          canvas.undo_buffer.add_item( new UndoItemStarPoints( this, old_value, new_value ) );
        }
      }
    );

  }

  //-------------------------------------------------------------
  // Saves the contents of this canvas item in XML format.
  public override Xml.Node* save( int id, string image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    node->set_prop( "points",      num_points.to_string() );
    node->set_prop( "inner-ratio", _inner_ratio.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this item from XML.
  public override void load( Xml.Node* node ) {
    var p = node->get_prop( "points" );
    if( p != null ) {
      num_points = int.parse( p );
    }
    var r = node->get_prop( "inner-ratio" );
    if( r != null ) {
      _inner_ratio = double.parse( r );
    } else {
      var i = node->get_prop( "inner-radius" );
      if( (i != null) && (outer_radius() > 0) ) {
        _inner_ratio = double.parse( i ) / outer_radius();
      }
    }
    base.load( node );
  }

  //-------------------------------------------------------------
  // Draw the star.
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var alpha       = mode.alpha( props.color.alpha );
    var point       = new CanvasPoint();
    var save_matrix = ctx.get_matrix();

    // Build the path in the item's rotated space, then restore the
    // matrix so that stroke widths aren't distorted by the rotation
    ctx.translate( bbox.mid_x(), bbox.mid_y() );
    ctx.rotate( angle );
    ctx.translate( (0 - bbox.mid_x()), (0 - bbox.mid_y()) );

    calculate_point( 0, point );
    ctx.move_to( point.x, point.y );
    for( int i=1; i<(num_points * 2); i++ ) {
      calculate_point( i, point );
      ctx.line_to( point.x, point.y );
    }
    ctx.close_path();
    ctx.set_matrix( save_matrix );

    save_path( ctx, CanvasItemPathType.FILL );

    if( props.outline ) {
      var outline = Granite.contrasting_foreground_color( props.color );
      set_color( ctx, color, outline, (alpha / 2) );
      if( props.fill ) {
        ctx.set_line_width( 1 );
        ctx.stroke_preserve();
      }
      if( props.stroke ) {
        props.dash.set_bg_pattern( ctx );
        ctx.set_line_width( props.stroke_width.width() + 2 );
        ctx.stroke_preserve();
      }
    }

    if( props.fill ) {
      set_color( ctx, color, props.color, alpha );
      if( props.stroke ) {
        ctx.fill_preserve();
      } else {
        ctx.fill();
      }
    }

    if( props.stroke ) {
      set_color( ctx, color, props.stroke_color, mode.alpha( props.stroke_color.alpha ) );
      ctx.set_line_width( props.stroke_width.width() );
      props.dash.set_fg_pattern( ctx );
      ctx.stroke();
    }

  }

}



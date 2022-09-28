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

public class CanvasItemStar : CanvasItem {

  private double _inner_radius = 15;
  private double _inner_angle  = 0;

  public int num_points { get; set; default = 5; }

  /* Constructor */
  public CanvasItemStar( Canvas canvas, bool fill, int point_num, double inner_radius, CanvasItemProperties props ) {
    base( (fill ? CanvasItemType.STAR_FILL : CanvasItemType.STAR_STROKE), canvas, props );
    num_points    = point_num;
    _inner_radius = inner_radius;
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Outer radius
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Inner radius
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Upper left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Upper right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Lower left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Lower right
  }

  /* Copies the contents of the given item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var star = (CanvasItemStar)item;
    _inner_radius = star._inner_radius;
    num_points    = star.num_points;
  }

  /* Returns a duplicate of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemStar( canvas, (itype == CanvasItemType.STAR_FILL), num_points, _inner_radius, props );
    item.copy( this );
    return( item );
  }

  private void calculate_point( int point_num, CanvasPoint point ) {

    var start_x      = bbox.mid_x();
    var start_y      = bbox.mid_y();
    var RAD_distance = ((2 * Math.PI) / num_points);
    var RAD_half_PI  = Math.PI /2;

    var new_outer_RAD      = ((point_num / 2) + 1) * RAD_distance;
    var half_new_outer_RAD = new_outer_RAD - (RAD_distance / 2);

    if( (point_num % 2) == 0 ) {
      var x = start_x + Math.cos(half_new_outer_RAD - RAD_half_PI) * _inner_radius;
      var y = start_y + Math.sin(half_new_outer_RAD - RAD_half_PI) * _inner_radius;
      point.copy_coords( x, y );
    } else {
      var outer_radius = bbox.height / 2;
      var x = start_x + Math.cos(new_outer_RAD - RAD_half_PI) * outer_radius;
      var y = start_y + Math.sin(new_outer_RAD - RAD_half_PI) * outer_radius;
      point.copy_coords( x, y );
    }

  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    /* Calculate the inner and outer control points */
    calculate_point( 0, points.index( 0 ) );
    calculate_point( ((num_points * 2) - 1), points.index( 1 ) );

    /* Update the selector positions for changing the bondary */
    points.index( 2 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( 3 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( 4 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( 5 ).copy_coords( bbox.x2(), bbox.y2() );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box          = new CanvasRect.from_rect( bbox );
    var inner_radius = _inner_radius;

    /* If we are moving the selector representing the outer radius, update the box */
    switch( index ) {
      case 0 :  inner_radius -= diffy;  break;
      case 1 :  box.x += diffy;  box.y += diffy;  box.width -= (diffy * 2);  box.height -= (diffy * 2);  break;
      case 2 :  box.x += diffy;  box.y += diffy;  box.width -= diffy;        box.height -= diffy;  break;
      case 3 :                   box.y += diffy;  box.width -= diffy;        box.height -= diffy;  break;
      case 4 :  box.x -= diffy;                   box.width += diffy;        box.height += diffy;  break;
      case 5 :                                    box.width += diffy;        box.height += diffy;  break;
    }

    /* Adjust the inner radius if the bbox resizers were moved */
    if( index >= 2 ) {
      var inner_ratio = inner_radius / (box.height * 0.5);
      inner_radius = (box.height / 2) * inner_ratio;
    }

    /*
     If the inner radius value is greater than zero and hte inner radius is less than
     the outer radius.
    */
    if( (inner_radius > 5) && ((box.height / 2) > inner_radius) ) {
      _inner_radius = inner_radius;
      bbox          = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    return( CursorType.TCROSS );
  }

  /* Adds the contextual menu items */
  protected override void add_contextual_menu_items( Box box ) {

    add_contextual_spinner( box, _( "Points:" ), 3, 50, 1, num_points,
      (item, value) => {
        num_points = value;
        create_points();
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

  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "points",       num_points.to_string() );
    node->set_prop( "inner-radius", _inner_radius.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var p = node->get_prop( "points" );
    if( p != null ) {
      num_points = int.parse( p );
    }
    var i = node->get_prop( "inner-radius" );
    if( i != null ) {
      _inner_radius = double.parse( i );
    }
    bbox_changed();
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var outline = Granite.contrasting_foreground_color( props.color );
    var alpha   = mode.alpha( props.alpha );
    var point   = new CanvasPoint();

    set_color( ctx, color, props.color, alpha );
    ctx.move_to( points.index( 0 ).x, points.index( 0 ).y );
    for( int i=1; i<(num_points * 2); i++ ) {
      calculate_point( i, point );
      ctx.line_to( point.x, point.y );
    }
    ctx.close_path();

    if( itype == CanvasItemType.STAR_FILL ) {

      save_path( ctx, CanvasItemPathType.FILL );

      if( props.outline ) {
        ctx.fill_preserve();
        set_color( ctx, color, outline, 0.5 );
        ctx.set_line_width( 1 );
        ctx.stroke();
      } else {
        ctx.fill();
      }

    } else {

      var sw = props.stroke_width.width();

      if( props.outline ) {
        set_color( ctx, color, outline, 0.5 );
        ctx.set_line_width( sw + 2 );
        props.dash.set_bg_pattern( ctx );
        save_path( ctx, CanvasItemPathType.STROKE );
        ctx.stroke_preserve();
      }

      set_color( ctx, color, props.color, alpha );
      ctx.set_line_width( sw );
      props.dash.set_fg_pattern( ctx );
      ctx.stroke();

    }

  }

}



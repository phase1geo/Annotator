/*s
* Copyright (c) 2020 (https://github.com/phase1geo/Annotator)
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

  private bool   _fill         = false;
  private int    _num_points   = 5;
  private double _inner_radius = 15;
  private double _inner_angle  = 0;

  /* Constructor */
  public CanvasItemStar( bool fill, int num_points, double inner_radius, CanvasItemProperties props ) {
    base( "star", props );
    _fill         = fill;
    _num_points   = num_points;
    _inner_radius = inner_radius;
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    if( points.length > 0 ) {
      points.remove_range( 0, points.length );
    }
    for( int i=0; i<(_num_points * 2); i++ ) {
      points.append_val( new CanvasPoint( (i == 0) || (i == ((_num_points * 2) - 1)) ) );
    }
    for( int i=0; i<4; i++ ) {
      points.append_val( new CanvasPoint( true ) );
    }
  }

  public override void copy( CanvasItem item ) {
    base.copy( item );
    var star = (CanvasItemStar)item;
    _fill         = star._fill;
    _inner_radius = star._inner_radius;
    if( _num_points != star._num_points ) {
      _num_points   = star._num_points;
      create_points();
    }
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    var outer_radius = bbox.height / 2;
    var start_x      = bbox.mid_x();
    var start_y      = bbox.mid_y();
    var RAD_distance = ((2 * Math.PI) / _num_points);
    var RAD_half_PI  = Math.PI /2;

    /* Adjust the starting point */
    points.index( 0 ).copy_coords( start_x, start_y );

    for( int i=0; i<_num_points; i++ ) {

      var new_outer_RAD      = (i + 1) * RAD_distance;
      var half_new_outer_RAD = new_outer_RAD - (RAD_distance / 2);

      var x = start_x + Math.cos(half_new_outer_RAD - RAD_half_PI) * _inner_radius;
      var y = start_y + Math.sin(half_new_outer_RAD - RAD_half_PI) * _inner_radius;
      points.index( (i * 2) + 0 ).copy_coords( x, y );

      x = start_x + Math.cos(new_outer_RAD - RAD_half_PI) * outer_radius;
      y = start_y + Math.sin(new_outer_RAD - RAD_half_PI) * outer_radius;
      points.index( (i * 2) + 1 ).copy_coords( x, y );

    }

    /* Update the selector positions for changing the bondary */
    var b = _num_points * 2;
    points.index( b + 0 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( b + 1 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( b + 2 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( b + 3 ).copy_coords( bbox.x2(), bbox.y2() );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box          = new CanvasRect.from_rect( bbox );
    var inner_radius = _inner_radius;

    /* If we are moving the selector representing the outer radius, update the box */
    if( index == ((_num_points * 2) - 1) ) {
      box.x += diffy;  box.y += diffy;  box.width -= (diffy * 2);  box.height -= (diffy * 2);

    /*
     Otherwise, if we are manipulating the inner radius or moving the four border
     selectors, update the inner radius to match the diffy value.  If we are manipulating
     the border selectors, adjust the bbox.
    */
    } else {
      var inner_ratio = inner_radius / (box.height * 0.5);
      switch( index - (_num_points * 2) ) {
        case 0 :  box.x += diffy;  box.y += diffy;  box.width -= diffy;  box.height -= diffy;  break;
        case 1 :                   box.y += diffy;  box.width -= diffy;  box.height -= diffy;  break;
        case 2 :  box.x -= diffy;                   box.width += diffy;  box.height += diffy;  break;
        case 3 :                                    box.width += diffy;  box.height += diffy;  break;
      }
      if( index == 0 ) {
        inner_radius -= diffy;
      } else {
        inner_radius = (box.height / 2) * inner_ratio;
      }
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

  /* Returns true if the given point is within this circle */
  public override bool is_within( double x, double y ) {
    return( Utils.is_within_polygon( x, y, points, (_num_points * 2) ) );
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "points",       _num_points.to_string() );
    node->set_prop( "inner-radius", _inner_radius.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var p = node->get_prop( "points" );
    if( p != null ) {
      _num_points = int.parse( p );
    }
    var i = node->get_prop( "inner-radius" );
    if( i != null ) {
      _inner_radius = double.parse( i );
    }
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var outline = Granite.contrasting_foreground_color( props.color );
    var alpha   = mode.alpha( props.alpha );

    Utils.set_context_color_with_alpha( ctx, props.color, alpha );
    ctx.move_to( points.index( 0 ).x, points.index( 0 ).y );
    for( int i=1; i<(_num_points * 2); i++ ) {
      ctx.line_to( points.index( i ).x, points.index( i ).y );
    }
    ctx.close_path();

    if( _fill ) {

      ctx.fill_preserve();

      Utils.set_context_color_with_alpha( ctx, outline, 0.5 );
      ctx.set_line_width( 1 );
      ctx.stroke();

    } else {

      var sw = props.stroke_width.width();

      Utils.set_context_color_with_alpha( ctx, outline, 0.5 );
      ctx.set_line_width( sw + 2 );
      props.dash.set_bg_pattern( ctx );
      ctx.stroke_preserve();

      Utils.set_context_color_with_alpha( ctx, props.color, alpha );
      ctx.set_line_width( sw );
      props.dash.set_fg_pattern( ctx );
      ctx.stroke();

    }

  }

}



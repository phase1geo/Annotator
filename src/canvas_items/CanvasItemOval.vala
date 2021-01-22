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

public class CanvasItemOval : CanvasItem {

  private bool _fill;

  /* Constructor */
  public CanvasItemOval( Canvas canvas, bool fill, CanvasItemProperties props ) {
    base( "oval", canvas, props );
    _fill = fill;
    create_points();
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // upper-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // upper-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // lower-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // lower-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // top
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // bottom
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER ) );  // left
  }

  /* Copies the contents of the given canvas item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var oval_item = (CanvasItemOval)item;
    if( oval_item != null ) {
      _fill = oval_item._fill;
    }
  }

  /* Returns a copy of this item */
  public override CanvasItem duplicate() {
    var item = new CanvasItemOval( canvas, _fill, props );
    item.copy( this );
    return( item );
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    points.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( 2 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( 3 ).copy_coords( bbox.x2(), bbox.y2() );

    points.index( 4 ).copy_coords( bbox.mid_x(), bbox.y1() );
    points.index( 5 ).copy_coords( bbox.x2(), bbox.mid_y() );
    points.index( 6 ).copy_coords( bbox.mid_x(), bbox.y2() );
    points.index( 7 ).copy_coords( bbox.x1(), bbox.mid_y() );
  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    adjust_diffs( shift, box, ref diffx, ref diffy );

    switch( index ) {
      case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3 :                                    box.width += diffx;  box.height += diffy;  break;
      case 4 :                   box.y += diffy;                       box.height -= diffy;  break;
      case 5 :                                    box.width += diffx;                        break;
      case 6 :                                                         box.height += diffy;  break;
      case 7 :  box.x += diffx;                   box.width -= diffx;                        break;
    }

    if( (box.width >= (selector_width * 3)) && (box.height >= (selector_height * 3)) ) {
      bbox = box;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override CursorType? get_selector_cursor( int index ) {
    switch( index ) {
      case 0  :  return( CursorType.UL_ANGLE );
      case 1  :  return( CursorType.UR_ANGLE );
      case 2  :  return( CursorType.LL_ANGLE );
      case 3  :  return( CursorType.LR_ANGLE );
      case 4  :  return( CursorType.TOP_SIDE );
      case 5  :  return( CursorType.RIGHT_SIDE );
      case 6  :  return( CursorType.BOTTOM_SIDE );
      case 7  :  return( CursorType.LEFT_SIDE );
      default :  assert_not_reached();
    }
  }

  /* Saves this item as XML */
  public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "fill", _fill.to_string() );
    return( node );
  }

  /* Loads this item from XML */
  public override void load( Xml.Node* node ) {
    base.load( node );
    var f = node->get_prop( "fill" );
    if( f != null ) {
      _fill = bool.parse( f );
    }
  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx ) {

    var scale_width  = (bbox.width < bbox.height) ? (bbox.width / bbox.height) : 1.0;
    var scale_height = (bbox.width < bbox.height) ? 1.0 : (bbox.height / bbox.width);
    var radius       = (bbox.width < bbox.height) ? (bbox.height / 2.0) : (bbox.width / 2.0);
    var outline      = Granite.contrasting_foreground_color( props.color );
    var alpha        = mode.alpha( props.alpha );

    Utils.set_context_color_with_alpha( ctx, props.color, alpha );

    var save_matrix = ctx.get_matrix();
    ctx.translate( bbox.mid_x(), bbox.mid_y() );
    ctx.scale( scale_width, scale_height );
    ctx.translate( (0 - bbox.mid_x()), (0 - bbox.mid_y()) );
    ctx.new_path();
    ctx.arc( bbox.mid_x(), bbox.mid_y(), radius, 0, (2 * Math.PI) );
    ctx.set_matrix( save_matrix );

    save_path( ctx, CanvasItemPathType.FILL );

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



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

public class CanvasItemGroup : CanvasItem {

  private Cursor[]         _sel_cursors;
  private List<CanvasItem> _group;

  public List<CanvasItem> group {
    get {
      return( _group );
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public CanvasItemGroup( Canvas canvas, List<CanvasItem> items ) {

    base( CanvasItemType.GROUP, canvas, null );

    create_points();

    // Add the items and update the stored bbox
    _group = new List<CanvasItem>();
    foreach( var item in items ) {
      _group.append( item );
      canvas.items.remove_item( item );
      bbox.union( item.bbox );
    }
    bbox_changed();

    _sel_cursors = new Cursor[4];  // The rotator uses the default cursor
    _sel_cursors[0] = new Cursor.from_name( "nw-resize", null );
    _sel_cursors[1] = new Cursor.from_name( "ne-resize", null );
    _sel_cursors[2] = new Cursor.from_name( "sw-resize", null );
    _sel_cursors[3] = new Cursor.from_name( "se-resize", null );

  }

  //-------------------------------------------------------------
  // Create the points
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // upper-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // upper-right
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER1 ) );  // lower-left
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // lower-right
  }

  //-------------------------------------------------------------
  // Returns the southeast selector.
  public override int resize_selector() {
    return( 3 );
  }

  //-------------------------------------------------------------
  // Copies the contents of the given item to this one.
  public override void copy( CanvasItem item ) {
    base.copy( item );
    var group_item = (CanvasItemGroup)item;
    _group = new List<CanvasItem>();
    foreach( var grouped_item in group_item.group ) {
      _group.append( grouped_item.duplicate() );
    }
  }

  //-------------------------------------------------------------
  // Returns a duplicate of this item
  public override CanvasItem duplicate() {
    var empty = new List<CanvasItem>();
    var item  = new CanvasItemGroup( canvas, empty );
    item.copy( this );
    return( item );
  }

  //-------------------------------------------------------------
  // Updates the selection boxes whenever the bounding box changes
  protected override void bbox_changed() {
    points.index( 0 ).copy_coords( bbox.x1(), bbox.y1() );
    points.index( 1 ).copy_coords( bbox.x2(), bbox.y1() );
    points.index( 2 ).copy_coords( bbox.x1(), bbox.y2() );
    points.index( 3 ).copy_coords( bbox.x2(), bbox.y2() );
  }

  //-------------------------------------------------------------
  // Adjusts the bounding box
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    // TBD

    /*
    var box = new CanvasRect.from_rect( bbox );
    double anchor_lx, anchor_ly, anchor_wx, anchor_wy;

    // Work in the item's unrotated space and remember where the
    // opposite side is so that it doesn't move when resizing
    get_anchor( index, out anchor_lx, out anchor_ly, out anchor_wx, out anchor_wy );
    unrotate_diffs( ref diffx, ref diffy );
    adjust_diffs( shift, box, ref diffx, ref diffy );

    switch( index ) {
      case 0 :  box.x += diffx;  box.y += diffy;  box.width -= diffx;  box.height -= diffy;  break;
      case 1 :                   box.y += diffy;  box.width += diffx;  box.height -= diffy;  break;
      case 2 :  box.x += diffx;                   box.width -= diffx;  box.height += diffy;  break;
      case 3 :                                    box.width += diffx;  box.height += diffy;  break;
    }

    if( (box.width >= 1) && (box.height >= 1) ) {
      fix_anchor( box, anchor_lx, anchor_ly, anchor_wx, anchor_wy );
      bbox = box;
    }

    if( (box.abs_width() >= (selector_width * 3)) && (box.abs_height() >= (selector_height * 3)) ) {
      set_selector_visual( index, false );
    } else {
      set_selector_visual( index, true );
    }
    */

  }

  //-------------------------------------------------------------
  // Provides cursor to display when mouse cursor is hovering over
  // the given selector
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursors[index] );
  }

  //-------------------------------------------------------------
  // Draw the rectangle
  public override void draw_item( Context ctx, CanvasItemColor color ) {
    foreach( var item in _group ) {
      item.draw_item( ctx, color );
    }
  }

}



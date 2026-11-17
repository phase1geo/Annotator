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

public class UndoItemUngroup : UndoItem {

  private CanvasItemGroup _group;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemUngroup( CanvasItemGroup group ) {
    base( _( "ungroup" ) );
    _group = group;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void undo( Canvas canvas ) {
    var pos  = canvas.items.item_z_position( _group.group.nth_data( 0 ) );
    var item = new CanvasItemGroup( canvas, _group.group );
    item.mode = CanvasItemMode.SELECTED;
    canvas.items.insert_item( item, pos );
    _group = item;
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void redo( Canvas canvas ) {
    var pos = canvas.items.item_z_position( _group );
    foreach( var item in _group.group ) {
      item.mode = CanvasItemMode.SELECTED;
      canvas.items.insert_item( item, pos );
      pos++;
    }
    canvas.items.remove_item( _group );
    canvas.queue_draw();
  }

}

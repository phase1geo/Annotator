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

public class UndoItemsDelete : UndoItem {

  private struct UndoItemDelete {
    CanvasItem item;
    int        position;
    public UndoItemDelete( CanvasItem i, int p ) {
      item     = i;
      position = p;
    }
  }

  private Array<UndoItemDelete?> _list;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemsDelete( List<CanvasItem> items, List<int> pos ) {
    base( _( "item delete" ) );
    _list = new Array<UndoItemDelete?>();
    var i = 0;
    foreach( var item in items ) {
      _list.append_val( UndoItemDelete( item, pos.nth_data( i ) ) );
      i++;
    }
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      canvas.items.insert_item( elem.item, elem.position );
    }
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      canvas.items.remove_item( _list.index( i ).item );
    }
    canvas.queue_draw();
  }

}

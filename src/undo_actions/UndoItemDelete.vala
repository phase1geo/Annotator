/*
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

public class UndoItemDelete : UndoItem {

  private struct UndoItemDeleteElem {
    CanvasItem item;
    int        position;
    public UndoItemDeleteElem( CanvasItem i, int p ) {
      item     = i;
      position = p;
    }
  }

  private Array<UndoItemDeleteElem?> _list;

  /* Default constructor */
  public UndoItemDelete() {
    base( _( "item delete" ) );
    _list = new Array<UndoItemDeleteElem?>();
  }

  /* Adds a canvas item to this undo list */
  public void add( CanvasItem item, int position ) {
    _list.append_val( UndoItemDeleteElem( item, position ) );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      canvas.items.add_item( elem.item, elem.position );
    }
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      canvas.items.remove_item( _list.index( i ).item );
    }
    canvas.queue_draw();
  }

}

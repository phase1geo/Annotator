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

public class UndoItemBoxChange : UndoItem {

  private struct UndoItemChangeElem {
    CanvasItem item;
    CanvasRect old_rect;
    CanvasRect new_rect;
    public UndoItemChangeElem( CanvasItem i ) {
      item = i;
      old_rect = new CanvasRect();
      old_rect.copy( item.last_bbox );
      new_rect = new CanvasRect();
      new_rect.copy( item.bbox );
    }
  }

  private Array<UndoItemChangeElem?> _list;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemBoxChange( string name ) {
    base( name );
    _list = new Array<UndoItemChangeElem?>();
  }

  //-------------------------------------------------------------
  // Constructor
  public UndoItemBoxChange.with_item( string name, CanvasItem item ) {
    base( name );
    _list = new Array<UndoItemChangeElem?>();
    _list.append_val( UndoItemChangeElem( item ) );
  }

  //-------------------------------------------------------------
  // Adds a canvas item to this undo list
  public void add( CanvasItem item ) {
    _list.append_val( UndoItemChangeElem( item ) );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      elem.item.bbox = elem.old_rect;
    }
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      elem.item.bbox = elem.new_rect;
    }
    canvas.queue_draw();
  }

}

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

public class UndoItemPaste : UndoItem {

  private Array<CanvasItem> _items;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemPaste() {
    base( _( "item paste" ) );
    _items = new Array<CanvasItem>();
  }

  //-------------------------------------------------------------
  // Adds the given item to the internal list
  public void add( CanvasItem item ) {
    _items.append_val( item );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    for( int i=0; i<_items.length; i++ ) {
      canvas.items.remove_item( _items.index( i ) );
    }
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    for( int i=0; i<_items.length; i++ ) {
      canvas.items.add_item( _items.index( i ), -1, false, false );
    }
    canvas.queue_draw();
  }

}

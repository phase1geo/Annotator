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

using Gdk;

public class UndoItemsFlatten : UndoItem {

  private struct UndoItemFlatten {
    CanvasItem item;
    int        position;
    public UndoItemFlatten( CanvasItem i, int p ) {
      item     = i;
      position = p;
    }
  }

  private Array<UndoItemFlatten> _list;
  private Pixbuf                 _old_pixbuf;
  private Pixbuf                 _new_pixbuf;

  public UndoItemsFlatten( List<CanvasItem> items, List<int> positions, Pixbuf old_pixbuf, Pixbuf new_pixbuf ) {
    base( _( "flatten items" ) );
    _list = new Array<UndoItemFlatten>();
    _old_pixbuf = old_pixbuf;
    _new_pixbuf = new_pixbuf;
    var i = 0;
    foreach( var item in items ) {
      _list.append_val( new UndoItemFlatten( item, positions.nth_data( i++ ) ) );
    }
  }

  public override void undo( Canvas canvas ) {
    canvas.image.set_base_pixbuf( _old_pixbuf );
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      canvas.items.insert_item( elem.item, elem.position );
    }
    canvas.queue_draw();
  }

  public override void redo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      canvas.items.remove_item( elem.item );
    }
    canvas.image.set_base_pixbuf( _new_pixbuf );
    canvas.queue_draw();
  }

}

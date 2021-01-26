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

public class UndoItemSendFront : UndoItem {

  private CanvasItem _item;
  private int        _position;

  /* Default constructor */
  public UndoItemSendFront( CanvasItem item, int position ) {
    base( _( "move item to front" ) );
    _item     = item;
    _position = position;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    canvas.items.remove_item( _item );
    canvas.items.insert_item( _item, _position );
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    canvas.items.move_to_front( _item );
    canvas.queue_draw();
  }

}

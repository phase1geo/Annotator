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

public class UndoItemChangeZPos : UndoItem {

  private CanvasItem _item;
  private int _old_pos;
  private int _new_pos;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemChangeZPos( CanvasItem item, int old_pos, int new_pos, string msg ) {
    base( msg );
    _item    = item;
    _old_pos = old_pos;
    _new_pos = new_pos;
  }

  //-------------------------------------------------------------
  // Moves the item from its current Z-position to the specified
  // Z-position
  private void move( Canvas canvas, int to_pos ) {
    var from_pos = canvas.items.item_z_position( _item );
    canvas.items.move_to_z_position( from_pos, to_pos );
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    move( canvas, _old_pos );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    move( canvas, _new_pos );
  }

}

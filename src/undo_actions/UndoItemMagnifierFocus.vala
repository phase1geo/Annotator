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

public class UndoItemMagnifierFocus : UndoItem {

  private CanvasItemMagnifier _item;
  private CanvasPoint         _old_point;
  private CanvasPoint         _new_point;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemMagnifierFocus( CanvasItemMagnifier item, CanvasPoint old_point, CanvasPoint new_point ) {
    base( _( "magnifier focus change") );
    _item      = item;
    _old_point = new CanvasPoint.from_point( old_point );
    _new_point = new CanvasPoint.from_point( new_point );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    _item.set_focus_point( _old_point );
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    _item.set_focus_point( _new_point );
    canvas.queue_draw();
  }

}

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

using Gtk;

public class UndoTextCommit : UndoItem {

  private CanvasItemText _item;
  private CanvasItemText _old_item;
  private CanvasItemText _new_item;

  /* Constructor for a text item commit */
  public UndoTextCommit( Canvas canvas, CanvasItemText item, CanvasItemText orig_item ) {
    base( _( "text changed" ) );
    var props = new CanvasItemProperties();
    _item     = new CanvasItemText( canvas, props );
    _old_item = new CanvasItemText( canvas, props );
    _new_item = new CanvasItemText( canvas, props );
    _new_item.copy( item );
    _old_item.copy( orig_item );
  }

  /* Undoes a node name change */
  public override void undo( Canvas canvas ) {
    _item.copy( _old_item );
    canvas.queue_draw();
  }

  /* Redoes a node name change */
  public override void redo( Canvas canvas ) {
    _item.copy( _new_item );
    canvas.queue_draw();
  }

}

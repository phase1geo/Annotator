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

public class UndoItemBlur : UndoItem {

  private CanvasItemBlur _item;
  private int            _old_blur;
  private int            _new_blur;

  /* Default constructor */
  public UndoItemBlur( CanvasItemBlur item, int old_blur, int new_blur ) {
    base( _( "blur amount") );
    _item     = item;
    _old_blur = old_blur;
    _new_blur = new_blur;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    _item.blur_radius = _old_blur;
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    _item.blur_radius = _new_blur;
    canvas.queue_draw();
  }

}

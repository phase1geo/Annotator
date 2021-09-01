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

using Gdk;

public class UndoImageChange : UndoItem {

  private Pixbuf _old_pixbuf;
  private Pixbuf _new_pixbuf;

  /* Default constructor */
  public UndoImageChange( string name, Pixbuf old_pixbuf, Pixbuf new_pixbuf ) {
    base( name );
    _old_pixbuf = old_pixbuf.copy();
    _new_pixbuf = new_pixbuf.copy();
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    canvas.image.change_image( _old_pixbuf, null );
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    canvas.image.change_image( _new_pixbuf, null );
    canvas.queue_draw();
  }

}

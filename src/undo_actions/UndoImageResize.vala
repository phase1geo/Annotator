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

public class UndoImageResize : UndoItem {

  private int        _old_width;
  private int        _old_height;
  private CanvasRect _old_rect;
  private int        _new_width;
  private int        _new_height;
  private CanvasRect _new_rect;

  /* Default constructor */
  public UndoImageResize( int old_width, int old_height, CanvasRect old_rect, int new_width, int new_height, CanvasRect new_rect ) {
    base( _( "image resize" ) );
    _old_width  = old_width;
    _old_height = old_height;
    _old_rect   = new CanvasRect.from_rect( old_rect );
    _new_width  = new_width;
    _new_height = new_height;
    _new_rect   = new CanvasRect.from_rect( new_rect );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    canvas.image.do_resize( _old_width, _old_height, _old_rect );
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    canvas.image.do_resize( _new_width, _new_height, _new_rect );
    canvas.queue_draw();
  }

}

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

public class UndoImageResize : UndoItem {

  private CanvasImageInfo _old_info;
  private CanvasImageInfo _new_info;

  //-------------------------------------------------------------
  // Default constructor
  public UndoImageResize( CanvasImageInfo old_info, CanvasImageInfo new_info ) {
    base( _( "image resize" ) );
    _old_info = new CanvasImageInfo.from_info( old_info );
    _new_info = new CanvasImageInfo.from_info( new_info );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    canvas.image.do_resize( _new_info, _old_info );
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    canvas.image.do_resize( _old_info, _new_info );
    canvas.queue_draw();
  }

}

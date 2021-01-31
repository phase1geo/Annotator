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

public class UndoItemMagnifierZoom : UndoItem {

  private CanvasItemMagnifier _item;
  private double              _old_zoom;
  private double              _new_zoom;

  /* Default constructor */
  public UndoItemMagnifierZoom( CanvasItemMagnifier item, double old_zoom, double new_zoom ) {
    base( _( "magnifier zoom") );
    _item     = item;
    _old_zoom = old_zoom;
    _new_zoom = new_zoom;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( Canvas canvas ) {
    _item.zoom_factor = _old_zoom;
    canvas.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( Canvas canvas ) {
    _item.zoom_factor = _new_zoom;
    canvas.queue_draw();
  }

}

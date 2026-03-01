/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

public enum CanvasTool {
  SELECTOR,
  ARROW,
  SHAPE,
  STICKER,
  IMAGE,
  SEQUENCE,
  PENCIL,
  TEXT,
  MAGNIFIER,
  BLUR,
  CROP,
  NUM
}

public class CanvasToolButton : ToggleButton {

  private bool _ignore  = false;

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolButton( CanvasToolbar toolbar, CanvasTool tool, Popover? popover = null ) {

    Object( has_frame: false, active: false );

    if( popover != null ) {
      popover.set_parent( this );
    }

    toggled.connect(() => {
      if( !_ignore ) {
        if( active ) {
          if( popover != null ) {
            popover.popup();
          }
        } else {
          if( popover != null ) {
            popover.popdown();
          }
        }
        toolbar.selected( tool );
      }
    });

    toolbar.selected.connect((t) => {
      _ignore = true;
      if( t == tool ) {
        active = true;
      } else {
        active = false;
        if( popover != null ) {
          popover.popdown();
        }
      }
      _ignore = false;
    });

  }

}

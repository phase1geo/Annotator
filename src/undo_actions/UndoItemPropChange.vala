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

public class UndoItemPropChange : UndoItem {

  private struct UndoItemChangeElem {

    CanvasItemProperties props;
    CanvasItemProperties old_props;
    CanvasItemProperties new_props;

    public UndoItemChangeElem( CanvasItem item ) {
      props = item.props;
      old_props = new CanvasItemProperties();
      old_props.copy( item.last_props );
      new_props = new CanvasItemProperties();
      new_props.copy( item.props );
    }

    public bool matches( UndoItemChangeElem elem ) {
      return( props == elem.props );
    }

    public void merge( UndoItemChangeElem elem ) {
      new_props.copy( elem.new_props );
    }

  }

  private Array<UndoItemChangeElem?> _list;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemPropChange() {
    base( _( "item property change" ) );
    _list = new Array<UndoItemChangeElem?>();
  }

  //-------------------------------------------------------------
  // Adds a canvas item to this undo list
  public void add( CanvasItem item ) {
    _list.append_val( UndoItemChangeElem( item ) );
  }

  //-------------------------------------------------------------
  // Returns the length of the item list
  public bool empty() {
    return( _list.length == 0 );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      elem.props.copy( elem.old_props );
    }
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( Canvas canvas ) {
    for( int i=0; i<_list.length; i++ ) {
      var elem = _list.index( i );
      elem.props.copy( elem.new_props );
    }
    canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Returns true if the given undo item is mergeable with us
  public override bool matches( UndoItem item ) {
    var cast_item = (item as UndoItemPropChange);
    if( (cast_item == null) || (_list.length != cast_item._list.length) ) return( false );
    for( int i=0; i<_list.length; i++ ) {
      if( !_list.index( i ).matches( cast_item._list.index( i ) ) ) return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Replaces the current item with the new item
  public override void replace_with_item( UndoItem item ) {
    var cast_item = (item as UndoItemPropChange);
    for( int i=0; i<_list.length; i++ ) {
      _list.index( i ).merge( cast_item._list.index( i ) );
    }
  }

}

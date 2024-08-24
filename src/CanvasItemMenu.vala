/*
* Copyright (c) 2024 (https://github.com/phase1geo/Annotator)
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

public delegate void CanvasItemClickAction( CanvasItem item );
public delegate void CanvasItemScaleAction( CanvasItem item, double value );
public delegate void CanvasItemSpinnerAction( CanvasItem item, int value );
public delegate void CanvasItemSwitchAction( CanvasItem item );
public delegate void CanvasItemScaleComplete( CanvasItem item, double old_value, double new_value );
public delegate void CanvasItemSpinnerComplete( CanvasItem item, int old_value, int new_value );

public class CanvasItemMenu {

  private Canvas            _canvas;
  private GLib.Menu         _menu;
  private GLib.Menu         _submenu;
  private Array<Widget>     _widgets;
  private SimpleActionGroup _actions;

  //-------------------------------------------------------------
  // Default constructor
  public CanvasItemMenu( Canvas canvas ) {
    _canvas  = canvas;
    _menu    = new GLib.Menu();
    _submenu = new GLib.Menu();
    _widgets = new Array<Widget>();
    _actions = new SimpleActionGroup();
  }

  //-------------------------------------------------------------
  // Attaches the given widget to the popover menu.
  private void attach_widget( Widget widget ) {

    var name = "item%u".printf( _widgets.length );
    var mi   = new GLib.MenuItem( null, null );

    mi.set_attribute( "custom", "s", name );

    _menu.append_item( mi );
    _widgets.append_val( widget );

  }

  //-------------------------------------------------------------
  // Populate the contextual menu with all of the stored widgets.
  public PopoverMenu create_popover( Gdk.Rectangle pointing_to ) {

    complete_section();

    var popover = new PopoverMenu.from_model( _menu ) {
      autohide    = true,
      pointing_to = pointing_to,
      position    = PositionType.RIGHT,
    };
    popover.set_parent( _canvas );

    for( int i=0; i<_widgets.length; i++ ) {
      var widget = _widgets.index( i );
      popover.add_child( widget, "item%d".printf( i ) );
    }

    /* Set the stage for menu actions */
    _canvas.insert_action_group( "item_menu", _actions );

    return( popover );

  }

  //-------------------------------------------------------------
  // Adds the current menu section to the main menu.
  public void complete_section( string? label = null ) {
    if( _submenu.get_n_items() > 0 ) {
      _menu.append_section( label, _submenu );
    }
    _submenu = new GLib.Menu();
  }

  //-------------------------------------------------------------
  // Returns a menuitem with the given label, action and (optional)
  // keyboard shortcut.
  public void add_menu_item( CanvasItem item, string label, string? shortcut, bool sensitive,
    CanvasItemClickAction action
  ) {

    var name    = "action%d".printf( _actions.list_actions().length );
    var saction = new SimpleAction( name, null );
    saction.set_enabled( sensitive );

    saction.activate.connect((value) => {
      action( item );
    });

    _submenu.append( label, "item_menu.%s".printf( name ) );

    _actions.add_action( saction );

  }

  //-------------------------------------------------------------
  // Creates a scale widget for the contextual menu
  public Scale add_scale(
    CanvasItem item, string label, double min, double max, double step, double dflt,
    CanvasItemScaleAction   action,
    CanvasItemScaleComplete complete
  ) {

    var lbl = new Label( label ) {
      halign     = Align.START,
      use_markup = true
    };

    var btn_controller = new GestureClick();
    var scale = new Scale.with_range( Orientation.HORIZONTAL, min, max, step ) {
      halign        = Align.FILL,
      hexpand       = true,
      draw_value    = false,
      width_request = 200
    };
    scale.add_controller( btn_controller );
    scale.set_value( dflt );
    scale.value_changed.connect(() => {
      action( item, scale.get_value() );
    });
    btn_controller.released.connect((n_press, x, y) => {
      complete( item, dflt, scale.get_value() );
    });

    var scale_box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign        = Align.FILL,
      hexpand       = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    scale_box.append( lbl );
    scale_box.append( scale );

    attach_widget( scale_box );

    return( scale );

  }

  //-------------------------------------------------------------
  // Creates a scale widget for the contextual menu.
  public SpinButton add_spinner(
    CanvasItem item, string label, int min, int max, int step, int dflt,
    CanvasItemSpinnerAction   action,
    CanvasItemSpinnerComplete complete
  ) {

    var lbl = new Label( label ) {
      halign     = Align.START,
      use_markup = true
    };

    var btn_controller = new GestureClick();
    var sb = new SpinButton.with_range( (double)min, (double)max, (double)step ) {
      halign = Align.FILL,
      hexpand = true,
      digits = 0
    };
    sb.add_controller( btn_controller );
    sb.set_value( (double)dflt );
    sb.value_changed.connect(() => {
      action( item, (int)sb.get_value() );
    });
    btn_controller.released.connect((n_press, x, y) => {
      complete( item, dflt, (int)sb.get_value() );
    });

    var sb_box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign        = Align.FILL,
      hexpand       = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    sb_box.append( lbl );
    sb_box.append( sb );

    attach_widget( sb_box );

    return( sb );

  }

  //-------------------------------------------------------------
  // Creates a switch widget for the contextual menu.
  public Switch add_switch( CanvasItem item, string label, bool dflt, CanvasItemSwitchAction action ) {

    var lbl = new Label( label ) {
      halign     = Align.START,
      use_markup = true
    };

    var sw = new Switch();
    sw.set_active( dflt );
    sw.notify["active"].connect(() => {
      action( item );
    });

    var sw_box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign        = Align.FILL,
      hexpand       = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10,
      homogeneous   = false
    };
    sw_box.append( lbl );
    sw_box.append( sw );

    attach_widget( sw_box );

    return( sw );

  }

}

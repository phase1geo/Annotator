/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
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

public class CanvasToolbar : Toolbar {

  private const int margin = 10;

  private CanvasItems _items;

  /* Constructor */
  public CanvasToolbar( CanvasItems items ) {

    _items = items;

    create_shapes();
    create_text();
    create_separator();
    create_color();
    create_stroke_width();

    show_all();

  }

  /* Creates the shape toolbar item */
  private void create_shapes() {

    var mb    = new MenuButton();
    mb.set_tooltip_text( _( "Shapes" ) );
    mb.image  = _items.get_shape_icon( 0 );
    mb.relief = ReliefStyle.NONE;
    mb.popup  = new Gtk.Menu();

    for( int i=0; i<_items.num_shapes(); i++ ) {
      var menu_item  = new Gtk.MenuItem();
      var shape_type = (CanvasItemType)i;
      menu_item.activate.connect(() => {
        _items.add_shape_item( shape_type );
        mb.image = _items.get_shape_icon( shape_type );
      });
      menu_item.add( _items.get_shape_icon( i ) );
      mb.popup.add( menu_item );
    }

    mb.popup.show_all();

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Add Shape" ) );
    btn.add( mb );

    add( btn );

  }

  /* Adds the text insertion button */
  private void create_text() {

    var btn = new ToolButton( null, null );
    btn.icon_name = "insert-text-symbolic";
    btn.clicked.connect(() => {
      _items.add_shape_item( CanvasItemType.TEXT );
    });

    add( btn );

  }

  private void create_color() {

    var colors    = new ColorButton();
    colors.set_tooltip_text( _( "Item Color" ) );
    colors.relief = ReliefStyle.NONE;
    colors.rgba   = _items.color;
    colors.color_set.connect(() => {
      _items.color = colors.rgba;
    });

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Item Color" ) );
    btn.add( colors );

    add( btn );

  }

  private void create_stroke_width() {

    var mb    = new MenuButton();
    mb.set_tooltip_text( _( "Line Width" ) );
    mb.relief = ReliefStyle.NONE;
    mb.image  = new Image.from_surface( make_stroke_icon( 24, _items.stroke_width ) );
    mb.popup  = new Gtk.Menu();

    for( int i=1; i<=4; i++ ) {
      var width       = i * _items.stroke_width;
      var menu_item   = new Gtk.MenuItem();
      menu_item.add( new Image.from_surface( make_stroke_icon( 50, width ) ) );
      menu_item.activate.connect(() => {
        _items.stroke_width = width;
        mb.image = new Image.from_surface( make_stroke_icon( 24, width ) );
      });
      mb.popup.add( menu_item );
    }
    mb.popup.show_all();

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Stroke Width" ) );
    btn.add( mb );

    add( btn );

  }

  private Cairo.Surface make_stroke_icon( int width, int stroke_width ) {

    var height  = stroke_width;
    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, width, height );
    var ctx     = new Cairo.Context( surface );

    /* Draw the stroke */
    Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );
    ctx.set_line_width( stroke_width );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( surface );

  }

  /* Adds a separator to the toolbar */
  private void create_separator() {

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.add( new Separator( Orientation.VERTICAL ) );

    add( btn );
  }

}


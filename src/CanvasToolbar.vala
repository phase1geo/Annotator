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

  private const int margin = 5;

  private Canvas _canvas;

  /* Constructor */
  public CanvasToolbar( Canvas canvas ) {

    _canvas = canvas;

    create_shapes();
    create_text();
    create_blur();
    create_crop();
    create_separator();
    create_color();
    create_stroke();

    show_all();

  }

  /* Creates the shape toolbar item */
  private void create_shapes() {

    var mb    = new MenuButton();
    mb.set_tooltip_text( _( "Shapes" ) );
    mb.image  = _canvas.items.get_shape_icon( 0 );
    mb.relief = ReliefStyle.NONE;
    mb.popup  = new Gtk.Menu();

    for( int i=0; i<_canvas.items.num_shapes(); i++ ) {
      var menu_item  = new Gtk.MenuItem();
      var shape_type = (CanvasItemType)i;
      menu_item.activate.connect(() => {
        _canvas.items.add_shape_item( shape_type );
        mb.image = _canvas.items.get_shape_icon( shape_type );
      });
      menu_item.add( _canvas.items.get_shape_icon( i ) );
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
    btn.set_tooltip_text( _( "Add Text" ) );
    btn.icon_name    = "insert-text-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.TEXT );
    });

    add( btn );

  }

  /* Create the blur button */
  private void create_blur() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Add Blur Box" ) );
    btn.icon_name    = "blur-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.BLUR );
    });

    add( btn );

  }

  /* Create the crop button */
  private void create_crop() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Crop Image" ) );
    btn.icon_name    = "image-crop-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.clear_selection();
      _canvas.image.start_crop();
      _canvas.queue_draw();
    });

    add( btn );

  }

  /* Creates the color dropdown */
  private void create_color() {

    var mb = new MenuButton();
    mb.set_tooltip_text( _( "Item Color" ) );
    mb.relief = ReliefStyle.NONE;
    mb.get_style_context().add_class( "color_chooser" );
    mb.popover = new Popover( null );

    var chooser = new ColorChooserWidget();
    chooser.border_width = 10;
    chooser.rgba = _canvas.items.props.color;
    chooser.color_activated.connect((c) => {
      _canvas.items.props.color = c;
      mb.image = new Image.from_surface( make_color_icon() );
      Utils.hide_popover( mb.popover );
    });
    mb.image = new Image.from_surface( make_color_icon() );
    chooser.show_all();

    mb.popover.add( chooser );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Item Color" ) );
    btn.add( mb );

    add( btn );

  }

  private void update_css() {
    var provider = new CssProvider();
    try {
      var color    = Utils.color_to_string( _canvas.items.props.color );
      var css_data = ".color_chooser { background: %s; }".printf( color );
      provider.load_from_data( css_data );
      StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        provider,
        STYLE_PROVIDER_PRIORITY_APPLICATION
      );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to update css: %s\n", e.message );
    }
  }

  /* Adds the stroke dropdown */
  private void create_stroke() {

    var mb     = new MenuButton();
    mb.relief  = ReliefStyle.NONE;
    mb.image   = new Image.from_surface( make_stroke_icon() );
    mb.popover = new Gtk.Popover( null );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.border_width = 10;

    /* Add stroke width */
    var width_title = new Label( Utils.make_title( _( "Stroke Width" ) ) );
    width_title.halign     = Align.START;
    width_title.use_markup = true;
    box.pack_start( width_title, false, false, 5 );

    unowned RadioButton? width_group = null;
    for( int i=1; i<=4; i++ ) {
      var width = i * _canvas.items.props.stroke_width;
      var btn   = new Gtk.RadioButton.from_widget( width_group );
      btn.margin_left = 20;
      btn.add( new Image.from_surface( make_width_icon( 100, width ) ) );
      btn.toggled.connect(() => {
        if( btn.get_active() ) {
          _canvas.items.props.stroke_width = width;
          mb.image = new Image.from_surface( make_stroke_icon() );
        }
      });
      if( width_group == null ) {
        width_group = btn;
      }
      box.pack_start( btn, false, false, 5 );
    }

    /* Add dash patterns */
    var dash_title = new Label( Utils.make_title( _( "Dash Pattern" ) ) );
    dash_title.halign     = Align.START;
    dash_title.margin_top = 20;
    dash_title.use_markup = true;
    box.pack_start( dash_title,  false, false, 5 );

    unowned RadioButton? dash_group = null;
    for( int i=0; i<CanvasItemDashPattern.NUM; i++ ) {
      var dash = (CanvasItemDashPattern)i;
      var btn  = new Gtk.RadioButton.from_widget( dash_group );
      btn.margin_left = 20;
      btn.add( new Image.from_surface( make_dash_icon( 100, dash ) ) );
      btn.toggled.connect(() => {
        if( btn.get_active() ) {
          _canvas.items.props.dash = dash;
          mb.image = new Image.from_surface( make_stroke_icon() );
        }
      });
      if( dash_group == null ) {
        dash_group = btn;
      }
      box.pack_start( btn, false, false, 5 );
    }

    box.show_all();
    mb.popover.add( box );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Stroke Properties" ) );
    btn.add( mb );

    add( btn );

  }

  private Cairo.Surface make_color_icon() {

    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 30, 24 );
    var ctx     = new Cairo.Context( surface );

    Utils.set_context_color( ctx, _canvas.items.props.color );
    ctx.rectangle( 0, 0, 30, 24 );
    ctx.fill();

    return( surface );

  }

  private Cairo.Surface make_width_icon( int width, int stroke_width ) {

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

  private Cairo.Surface make_dash_icon( int width, CanvasItemDashPattern dash ) {

    var height  = 5;
    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, width, height );
    var ctx     = new Cairo.Context( surface );

    Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );
    ctx.set_line_width( height );
    dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( surface );

  }

  private Cairo.Surface make_stroke_icon() {

    var width   = 50;
    var height  = _canvas.items.props.stroke_width;
    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, width, height );
    var ctx     = new Cairo.Context( surface );

    /* Draw the stroke */
    Utils.set_context_color( ctx, Utils.color_from_string( "black" ) );
    ctx.set_line_width( _canvas.items.props.stroke_width );
    _canvas.items.props.dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( surface );

  }

  /* Adds a separator to the toolbar */
  private void create_separator() {

    var sep = new SeparatorToolItem();
    sep.draw = true;

    add( sep );

  }

}


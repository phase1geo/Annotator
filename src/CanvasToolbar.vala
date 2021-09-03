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

using Gtk;

public class CanvasToolbar : Toolbar {

  private const int margin = 5;

  private Canvas       _canvas;
  private ToggleButton _crop_btn;

  /* Constructor */
  public CanvasToolbar( Canvas canvas ) {

    _canvas = canvas;

    create_shapes();
    create_sticker();
    create_sequence();
    create_pencil();
    create_text();
    create_magnifier();
    create_blur();
    create_separator();
    create_crop();
    create_resize();
    create_separator();
    create_color();
    create_stroke();
    create_fonts();

    show_all();

  }

  /* Creates the shape toolbar item */
  private void create_shapes() {

    var mb = new MenuButton();
    mb.set_tooltip_text( _( "Add Shape" ) );
    mb.image   = _canvas.items.get_shape_icon( 0 );
    mb.relief  = ReliefStyle.NONE;

    var grid = new Grid();
    grid.border_width = 5;

    for( int i=0; i<_canvas.items.num_shapes(); i++ ) {
      var btn        = new Button();
      var shape_type = (CanvasItemType)i;
      btn.image  = _canvas.items.get_shape_icon( i );
      btn.relief = ReliefStyle.NONE;
      btn.margin = 5;
      btn.clicked.connect(() => {
        _canvas.items.add_shape_item( shape_type );
        mb.image = _canvas.items.get_shape_icon( shape_type );
        Utils.hide_popover( mb.popover );
      });
      grid.attach( btn, (i % 2), (i / 2) );
    }

    grid.show_all();

    mb.popover = new Popover( null );
    mb.popover.add( grid );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.add( mb );

    add( btn );

  }

  /* Creates the sticker toolbar item */
  private void create_sticker() {

    var mb = new MenuButton();
    mb.set_tooltip_text( _( "Add Sticker" ) );
    mb.image   = new Image.from_icon_name( "sticker-symbolic", IconSize.LARGE_TOOLBAR );
    mb.relief  = ReliefStyle.NONE;
    mb.popover = new Popover( null );

    var box = new Box( Orientation.VERTICAL, 0 );
    var sw  = new ScrolledWindow( null, null );
    var vp  = new Viewport( null, null );
    vp.set_size_request( 200, 400 );
    vp.add( box );
    sw.add( vp );

    create_via_xml( box, mb.popover );
    sw.set_size_request( 200, 400 );
    sw.show_all();

    mb.popover.add( sw );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.add( mb );

    add( btn );

  }

  /* Creates the rest of the UI from the stickers XML file that is stored in a gresource */
  private void create_via_xml( Box box, Popover popover ) {

    try {
      var template = resources_lookup_data( "/com/github/phase1geo/annotator/images/stickers.xml", ResourceLookupFlags.NONE);
      var contents = (string)template.get_data();
      Xml.Doc* doc = Xml.Parser.parse_memory( contents, contents.length );
      if( doc != null ) {
        for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
          if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "category") ) {
            var category = create_category( box, it->get_prop( "name" ) );
            for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "img") ) {
                var name = it2->get_prop( "title" );
                create_image( category, name, popover );
              }
            }
          }
        }
        delete doc;
      }
    } catch( Error e ) {
      warning( "Failed to load sticker XML template: %s", e.message );
    }

  }

  /* Creates the expander flowbox for the given category name and adds it to the sidebar */
  private FlowBox create_category( Box box, string name ) {

    /* Create expander */
    var exp  = new Expander( Utils.make_title( name ) );
    exp.use_markup = true;
    exp.expanded   = true;

    /* Create the flowbox which will contain the stickers */
    var fbox = new FlowBox();
    fbox.homogeneous = true;
    fbox.selection_mode = SelectionMode.NONE;
    exp.add( fbox );

    box.pack_start( exp, false, false, 20 );

    return( fbox );

  }

  /* Creates the image from the given name and adds it to the flow box */
  private void create_image( FlowBox box, string name, Popover popover ) {

    var resource = "/com/github/phase1geo/annotator/images/sticker_%s".printf( name );

    var btn = new Button();
    btn.image  = new Image.from_resource( resource );
    btn.relief = ReliefStyle.NONE;
    btn.set_tooltip_text( name );
    btn.clicked.connect((e) => {
      _canvas.items.add_sticker( resource );
      Utils.hide_popover( popover );
    });

    box.add( btn );

  }

  /* Adds the sequence button */
  private void create_sequence() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Add Sequence Number" ) );
    btn.icon_name    = "sequence-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.SEQUENCE );
    });

    add( btn );

  }

  /* Starts a drawing operation with the pencil tool */
  private void create_pencil() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Pencil Tool" ) );
    btn.icon_name = "edit-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.PENCIL );
    });

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

  private void create_magnifier() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Add magnifier" ) );
    btn.icon_name    = "magnifier-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.MAGNIFIER );
    });

    add(btn );

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

    _crop_btn = new ToggleButton();
    _crop_btn.set_tooltip_text( _( "Crop Image" ) );
    _crop_btn.relief       = ReliefStyle.NONE;
    _crop_btn.image        = new Image.from_icon_name( "image-crop-symbolic", IconSize.LARGE_TOOLBAR );
    _crop_btn.margin_left  = margin;
    _crop_btn.margin_right = margin;
    _crop_btn.toggled.connect(() => {
      if( !_crop_btn.active ) {
        _canvas.image.cancel_crop();
      } else {
        _canvas.items.clear_selection();
        _canvas.image.start_crop();
      }
      _canvas.items.clear_selection();
      _canvas.queue_draw();
      _canvas.grab_focus();
    });

    var ti = new ToolItem();
    ti.add( _crop_btn );

    add( ti );

  }

  /* Create the image resizer button */
  private void create_resize() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_text( _( "Resize Image" ) );
    btn.icon_name    = "view-fullscreen-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.clear_selection();
      _canvas.image.resize_image();
      _canvas.queue_draw();
      _canvas.grab_focus();
    });

    add( btn );

  }

  /* Creates the color dropdown */
  private void create_color() {

    var mb = new MenuButton();
    mb.set_tooltip_text( _( "Shape Color" ) );
    mb.relief = ReliefStyle.NONE;
    mb.get_style_context().add_class( "color_chooser" );
    mb.popover = new Popover( null );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.border_width = 10;

    var chooser = new ColorChooserWidget();
    chooser.rgba = _canvas.items.props.color;
    chooser.notify.connect((p) => {
      _canvas.items.props.color = chooser.rgba;
      mb.image = new Image.from_surface( make_color_icon() );
    });
    mb.image = new Image.from_surface( make_color_icon() );
    box.pack_start( chooser, false, false );

    create_color_alpha( mb, box );

    box.show_all();
    mb.popover.add( box );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.set_tooltip_text( _( "Item Color" ) );
    btn.add( mb );

    add( btn );

  }

  private void create_color_alpha( MenuButton mb, Box box ) {

    var ascale = new Scale.with_range( Orientation.HORIZONTAL, 0.0, 1.0, 0.1 );
    ascale.margin_left  = 20;
    ascale.margin_right = 20;
    ascale.draw_value   = true;
    ascale.set_value( _canvas.items.props.alpha );
    ascale.value_changed.connect(() => {
      _canvas.items.props.alpha = ascale.get_value();
      mb.image = new Image.from_surface( make_color_icon() );
    });
    ascale.format_value.connect((value) => {
      return( "%d%%".printf( (int)(value * 100) ) );
    });
    for( int i=0; i<=10; i++ ) {
      ascale.add_mark( (i / 10.0), PositionType.BOTTOM, null );
    }

    var areveal = new Revealer();
    areveal.reveal_child = (_canvas.items.props.alpha < 1.0);
    areveal.add( ascale );

    var asw = new Switch();
    asw.halign = Align.START;
    asw.set_active( _canvas.items.props.alpha < 1.0 );
    asw.button_release_event.connect((e) => {
      _canvas.items.props.alpha = areveal.reveal_child ? 1.0 : ascale.get_value();
      mb.image = new Image.from_surface( make_color_icon() );
      areveal.reveal_child = !areveal.reveal_child;
      return( false );
    });

    var albl = new Label( Utils.make_title( _( "Add Transparency" ) ) );
    albl.halign       = Align.START;
    albl.use_markup   = true;
    albl.margin_right = 10;

    var albox = new Box( Orientation.HORIZONTAL, 10 );
    albox.pack_start( asw,  false, false );
    albox.pack_start( albl, false, false );

    var abox = new Box( Orientation.VERTICAL, 0 );
    abox.margin_top = 20;
    abox.pack_start( albox,   false, false );
    abox.pack_start( areveal, true,  true );

    box.pack_start( abox, true, true );

  }

  /* Adds the stroke dropdown */
  private void create_stroke() {

    var mb     = new MenuButton();
    mb.set_tooltip_text( _( "Shape Border" ) );
    mb.relief  = ReliefStyle.NONE;
    mb.image   = new Image.from_surface( make_stroke_icon() );
    mb.popover = new Gtk.Popover( null );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.border_width = 10;

    /* Add stroke width */
    var width_title = new Label( Utils.make_title( _( "Border Width" ) ) );
    width_title.halign     = Align.START;
    width_title.use_markup = true;
    box.pack_start( width_title, false, false, 5 );

    unowned RadioButton? width_group = null;
    for( int i=0; i<CanvasItemStrokeWidth.NUM; i++ ) {
      var sw  = (CanvasItemStrokeWidth)i;
      var btn = new Gtk.RadioButton.from_widget( width_group );
      btn.margin_left = 20;
      btn.active = (_canvas.items.props.stroke_width == sw);
      btn.add( new Image.from_surface( make_width_icon( 100, sw.width() ) ) );
      btn.toggled.connect(() => {
        if( btn.get_active() ) {
          _canvas.items.props.stroke_width = sw;
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
      btn.active = (_canvas.items.props.dash == dash);
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
    btn.add( mb );

    add( btn );

  }

  /* Adds the font menubutton */
  private void create_fonts() {

    var mb = new MenuButton();
    mb.set_tooltip_text( _( "Font Properties" ) );
    mb.image  = new Image.from_icon_name( "font-x-generic-symbolic", IconSize.LARGE_TOOLBAR );
    mb.relief = ReliefStyle.NONE;
    mb.get_style_context().add_class( "color_chooser" );
    mb.popover = new Popover( null );

    var chooser = new FontChooserWidget();
    chooser.border_width = 10;
    chooser.font_desc    = _canvas.items.props.font;
    chooser.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    chooser.notify.connect((p) => {
      _canvas.items.props.font = Pango.FontDescription.from_string( chooser.get_font() );
    });
    chooser.show_all();

    mb.popover.add( chooser );

    var btn = new ToolItem();
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.add( mb );

    add( btn );

  }

  private Cairo.Surface make_color_icon() {

    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 30, 24 );
    var ctx     = new Cairo.Context( surface );
    var stroke  = Granite.contrasting_foreground_color( _canvas.items.props.color );

    Utils.set_context_color_with_alpha( ctx, _canvas.items.props.color, _canvas.items.props.alpha );
    ctx.rectangle( 0, 0, 30, 24 );
    ctx.fill_preserve();

    Utils.set_context_color_with_alpha( ctx, stroke, 0.5 );
    ctx.stroke();

    return( surface );

  }

  /* Returns true if the current mode is dark mode */
  private bool is_dark_mode() {

    var settings = Gtk.Settings.get_default();
    if( settings != null ) {
      return( settings.gtk_application_prefer_dark_theme );
    }

    return( false );

  }

  private Cairo.Surface make_width_icon( int width, int stroke_width ) {

    var height  = stroke_width;
    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, width, height );
    var ctx     = new Cairo.Context( surface );

    /* Draw the stroke */
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
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

    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( height );
    dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    return( surface );

  }

  private Cairo.Surface make_stroke_icon() {

    var width   = 50;
    var height  = _canvas.items.props.stroke_width.width();
    var surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, width, height );
    var ctx     = new Cairo.Context( surface );

    /* Draw the stroke */
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( height );
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

  /* Called when the canvas image crop ends */
  public void crop_ended() {
    _crop_btn.active = false;
  }

}


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
using Gee;

public class CanvasToolbar : Toolbar {

  private const int margin = 5;

  private Canvas             _canvas;
  private ToggleButton       _crop_btn;
  private Array<RadioButton> _width_btns;
  private Array<RadioButton> _dash_btns;
  private ColorChooserWidget _color_chooser;
  private Switch             _asw;
  private Revealer           _areveal;
  private Scale              _ascale;
  private FontChooserWidget  _font_chooser;
  private int                _current_shape;
  private HashMap<CanvasItemCategory,CurrentItem> _current_item;

  /* Constructor */
  public CanvasToolbar( Canvas canvas ) {

    _canvas       = canvas;
    _width_btns   = new Array<RadioButton>();
    _dash_btns    = new Array<RadioButton>();
    _current_item = new HashMap<CanvasItemCategory,CurrentItem>();

    /* Create current items */
    _current_item.set( CanvasItemCategory.ARROW, new CurrentItem.with_canvas_item( CanvasItemType.ARROW ) );
    _current_item.set( CanvasItemCategory.SHAPE, new CurrentItem.with_canvas_item( CanvasItemType.RECT_STROKE ) );

    create_shapes( CanvasItemCategory.ARROW, _( "Add Arrow" ), _( "More Arrows" ), _( "Custom Arrows" ) );
    create_shapes( CanvasItemCategory.SHAPE, _( "Add Shape" ), _( "More Shapes" ), _( "Custom Shapes" ) );
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

    /* If the selection changes, update the toolbar */
    _canvas.items.selection_changed.connect( selection_changed );

  }

  /* Creates the shape toolbar item */
  private void create_shapes( CanvasItemCategory category, string tooltip, string mb_tooltip, string custom_label ) {

    var box = new Box( Orientation.VERTICAL, 5 );
    box.margin = 5;

    var fb = new FlowBox();
    fb.orientation = Orientation.HORIZONTAL;
    fb.min_children_per_line = 4;
    fb.max_children_per_line = 4;

    var btn     = new ToolButton( null, null );
    var mb      = new ToolButton( null, null );
    var popover = new Popover( mb );

    for( int i=0; i<CanvasItemType.NUM; i++ ) {
      var shape_type = (CanvasItemType)i;
      if( shape_type.category() == category ) {
        var b = new Button();
        b.set_tooltip_markup( shape_type.tooltip() );
        b.image  = new Image.from_icon_name( shape_type.icon_name(), IconSize.LARGE_TOOLBAR );
        b.relief = ReliefStyle.NONE;
        b.margin = 5;
        b.clicked.connect(() => {
          _current_item.get( category ).canvas_item( shape_type );
          _current_item.get( category ).add_item( _canvas.items );
          btn.icon_widget = _current_item.get( category ).get_image();
          btn.show_all();
          Utils.hide_popover( popover );
        });
        fb.add( b );
      }
    }

    box.pack_start( fb, false, false, 0 );
    _canvas.items.custom_items.create_menu( category, popover, box, custom_label, 4 );
    _canvas.items.custom_items.item_selected.connect((cat, item) => {
      if( cat == category ) {
        _current_item.get( cat ).custom_item( item );
        _current_item.get( cat ).add_item( _canvas.items );
        btn.icon_widget = _current_item.get( cat ).get_image();
        btn.show_all();
        Utils.hide_popover( popover );
      }
    });
    box.show_all();

    popover.add( box );

    btn.set_tooltip_text( tooltip );
    btn.icon_widget  = _current_item.get( category ).get_image();
    btn.margin_left  = margin;
    btn.margin_right = 0;
    btn.clicked.connect(() => {
      _current_item.get( category ).add_item( _canvas.items );
    });

    var lbl = new Label( "\u25bc" );
    lbl.max_width_chars = 1;
    lbl.margin = 0;

    mb.set_tooltip_text( mb_tooltip );
    mb.label_widget = lbl;
    mb.margin_left  = 0;
    mb.margin_right = margin;
    mb.clicked.connect(() => {
      Utils.show_popover( popover );
    });

    add( btn );
    add( mb );

  }

  /* Creates the sticker toolbar item */
  private void create_sticker() {

    var mb = new MenuButton();
    mb.set_tooltip_markup( CanvasItemType.STICKER.tooltip() );
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
    btn.set_tooltip_markup( CanvasItemType.SEQUENCE.tooltip() );
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
    btn.set_tooltip_markup( CanvasItemType.PENCIL.tooltip() );
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
    btn.set_tooltip_markup( CanvasItemType.TEXT.tooltip() );
    btn.icon_name    = "insert-text-symbolic";
    btn.margin_left  = margin;
    btn.margin_right = margin;
    btn.clicked.connect(() => {
      _canvas.items.add_shape_item( CanvasItemType.TEXT );
    });
    /*
    btn.button_press_event.connect((e) => {
      if( e.button == Gdk.BUTTON_SECONDARY ) {
        show_custom_menu( btn, CanvasItemCategory.TEXT );
      }
      return( true );
    });
    */

    add( btn );

  }

  private void create_magnifier() {

    var btn = new ToolButton( null, null );
    btn.set_tooltip_markup( CanvasItemType.MAGNIFIER.tooltip() );
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
    btn.set_tooltip_markup( CanvasItemType.BLUR.tooltip() );
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

    _color_chooser = new ColorChooserWidget();
    _color_chooser.rgba = _canvas.items.props.color;
    _color_chooser.notify.connect((p) => {
      _canvas.items.props.color = _color_chooser.rgba;
      mb.image = new Image.from_surface( make_color_icon() );
    });
    mb.image = new Image.from_surface( make_color_icon() );
    box.pack_start( _color_chooser, false, false );

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

    _ascale = new Scale.with_range( Orientation.HORIZONTAL, 0.0, 1.0, 0.1 );
    _ascale.margin_left  = 20;
    _ascale.margin_right = 20;
    _ascale.draw_value   = true;
    _ascale.set_value( _canvas.items.props.alpha );
    _ascale.value_changed.connect(() => {
      _canvas.items.props.alpha = _ascale.get_value();
      mb.image = new Image.from_surface( make_color_icon() );
    });
    _ascale.format_value.connect((value) => {
      return( "%d%%".printf( (int)(value * 100) ) );
    });
    for( int i=0; i<=10; i++ ) {
      _ascale.add_mark( (i / 10.0), PositionType.BOTTOM, null );
    }

    _areveal = new Revealer();
    _areveal.reveal_child = (_canvas.items.props.alpha < 1.0);
    _areveal.add( _ascale );

    _asw = new Switch();
    _asw.halign = Align.START;
    _asw.set_active( _canvas.items.props.alpha < 1.0 );
    _asw.button_release_event.connect((e) => {
      _canvas.items.props.alpha = _areveal.reveal_child ? 1.0 : _ascale.get_value();
      mb.image = new Image.from_surface( make_color_icon() );
      _areveal.reveal_child = !_areveal.reveal_child;
      return( false );
    });

    var albl = new Label( Utils.make_title( _( "Add Transparency" ) ) );
    albl.halign       = Align.START;
    albl.use_markup   = true;
    albl.margin_right = 10;

    var albox = new Box( Orientation.HORIZONTAL, 10 );
    albox.pack_start( _asw, false, false );
    albox.pack_start( albl, false, false );

    var abox = new Box( Orientation.VERTICAL, 0 );
    abox.margin_top = 20;
    abox.pack_start( albox,    false, false );
    abox.pack_start( _areveal, true,  true );

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
      _width_btns.append_val( btn );
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
      _dash_btns.append_val( btn );
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

    _font_chooser = new FontChooserWidget();
    _font_chooser.border_width = 10;
    _font_chooser.font_desc    = _canvas.items.props.font;
    _font_chooser.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    _font_chooser.notify.connect((p) => {
      _canvas.items.props.font = Pango.FontDescription.from_string( _font_chooser.get_font() );
    });
    _font_chooser.show_all();

    mb.popover.add( _font_chooser );

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

  /* Called whenever the item selection changes */
  private void selection_changed( CanvasItemProperties props ) {

    var p = new CanvasItemProperties();
    p.copy( props );

    /* Updates the width group */
    _width_btns.index( (int)p.stroke_width ).set_active( true );

    /* Updates the dash group */
    _dash_btns.index( (int)p.dash ).set_active( true );

    /* Set the color */
    _color_chooser.rgba = p.color;

    /* Handle the alpha value */
    _ascale.set_value( p.alpha );
    _areveal.reveal_child = (p.alpha < 1.0);
    _asw.set_active( p.alpha < 1.0 );

    /* Set the font */
    _font_chooser.font_desc = p.font;

  }

  /*
   Displays the custom menu for the specified item category type
   relative to the given widget.
  */
  /*
  private void show_custom_menu( Widget w, CanvasItemCategory category ) {

    var fb = new FlowBox();
    fb.orientation = Orientation.HORIZONTAL;
    fb.min_children_per_line = 4;
    fb.max_children_per_line = 4;

    var popover = new Popover( w );
    _canvas.items.custom_items.populate_menu( category, null, popover, fb );

    if( fb.get_children().length() > 0 ) {
      popover.add( fb );
      Utils.show_popover( popover );
    }

  }
  */

}


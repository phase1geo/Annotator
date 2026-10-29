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
  RESIZE,
  DROPPER,
  NUM;

  //-------------------------------------------------------------
  // Converts to a string.
  public string to_string() {
    switch( this ) {
      case SELECTOR  :  return( "selector" );
      case ARROW     :  return( "arrow" );
      case SHAPE     :  return( "shape" );
      case STICKER   :  return( "sticker" );
      case IMAGE     :  return( "image" );
      case SEQUENCE  :  return( "sequence" );
      case PENCIL    :  return( "pencil" );
      case TEXT      :  return( "text" );
      case MAGNIFIER :  return( "magnifier" );
      case BLUR      :  return( "blur" );
      case CROP      :  return( "crop" );
      case RESIZE    :  return( "resize" );
      case DROPPER   :  return( "dropper" );
      default        :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses a string for the matching canvas tool.
  public static CanvasTool parse( string val ) {
    switch( val ) {
      case "selector"  :  return( SELECTOR );
      case "arrow"     :  return( ARROW );
      case "shape"     :  return( SHAPE );
      case "sticker"   :  return( STICKER );
      case "image"     :  return( IMAGE );
      case "sequence"  :  return( SEQUENCE );
      case "pencil"    :  return( PENCIL );
      case "text"      :  return( TEXT );
      case "magnifier" :  return( MAGNIFIER );
      case "blur"      :  return( BLUR );
      case "crop"      :  return( CROP );
      case "resize"    :  return( RESIZE );
      case "dropper"   :  return( DROPPER );
      default          :  return( NUM );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this tool needs to display border options.
  public bool has_border() {
    return( (this == ARROW)    ||
            (this == SHAPE)    ||
            (this == STICKER)  ||
            (this == IMAGE)    ||
            (this == SEQUENCE) ||
            (this == PENCIL)   ||
            (this == TEXT)     ||
            (this == MAGNIFIER) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool needs to display background options.
  public bool has_fill() {
    return( (this == ARROW)    ||
            (this == SHAPE)    ||
            (this == SEQUENCE) ||
            (this == PENCIL)   ||
            (this == TEXT) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool provides an alpha slider (but not a fill).
  public bool has_alpha() {
    return( (this == IMAGE) || (this == STICKER) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool needs to display font options.
  public bool has_font() {
    return( (this == SEQUENCE) ||
            (this == TEXT) );
  }

  //-------------------------------------------------------------
  // Returns true if this tool has properties.
  public bool has_properties() {
    return( has_border() || has_fill() || has_alpha() || has_font() );
  }

  //-------------------------------------------------------------
  // Returns the label displayed at the top of the options popup.
  public string options_title() {
    switch( this ) {
      case ARROW     :  return( _( "New Arrow Properties" ) );
      case SHAPE     :  return( _( "New Shape Properties" ) );
      case STICKER   :  return( _( "New Sticker Properties" ) );
      case IMAGE     :  return( _( "New Image Properties" ) );
      case SEQUENCE  :  return( _( "New Sequence Properties" ) );
      case PENCIL    :  return( _( "New Pencil Properties" ) );
      case TEXT      :  return( _( "New Text Properties" ) );
      case MAGNIFIER :  return( _( "New Magnifier Properties" ) );
      case BLUR      :  return( _( "New Blur Properties" ) );
      default        :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns the CanvasItemType associated with this tool
  public CanvasItemType canvas_item_type() {
    switch( this ) {
      case SELECTOR  :  return( CanvasItemType.NONE );
      case ARROW     :  return( CanvasItemType.ARROW );
      case SHAPE     :  return( CanvasItemType.RECT );
      case STICKER   :  return( CanvasItemType.STICKER );
      case IMAGE     :  return( CanvasItemType.IMAGE );
      case SEQUENCE  :  return( CanvasItemType.SEQUENCE );
      case PENCIL    :  return( CanvasItemType.PENCIL );
      case TEXT      :  return( CanvasItemType.TEXT );
      case MAGNIFIER :  return( CanvasItemType.MAGNIFIER );
      case BLUR      :  return( CanvasItemType.BLUR );
      case CROP      :  return( CanvasItemType.NONE );
      case RESIZE    :  return( CanvasItemType.NONE );
      case DROPPER   :  return( CanvasItemType.NONE );
      default        :  assert_not_reached();
    }
  }

}

public class CanvasToolButton : ToggleButton {

  private static ToggleButton? _group = null;

  private Canvas                _canvas;
  private CanvasItemProperties? _props   = null;
  private Popover?              _options = null;

  //-------------------------------------------------------------
  // Constructor
  public CanvasToolButton( CanvasToolbar toolbar, CanvasTool tool, Popover? popover = null ) {

    Object( has_frame: false, active: false );

    _canvas = toolbar.canvas;
    _props  = toolbar.canvas.props.get_properties( tool );

    if( _group != null ) {
      set_group( _group );
    } else {
      _group = (ToggleButton)this;
    }

    if( popover != null ) {
      popover.set_parent( this );
    }

    var left = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY,
      propagation_phase = PropagationPhase.CAPTURE 
    };
    add_controller( left );
    left.pressed.connect((n_press, x, y) => {
      if( active ) {
        if( popover != null ) {
          if( popover.get_mapped() ) {
            popover.popdown();
          } else {
            popover.popup();
          }
        }
      }
    });

    // Make sure that the options popover is displayed and hidden on right-click
    var right = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    add_controller( right );
    right.pressed.connect((n_press, x, y) => {
      if( _options != null ) {
        Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
        _options.pointing_to = rect;
        if( _options.get_mapped() ) {
          _options.popdown();
        } else {
          _options.popup();
        }
      }
    });

    // Set the current tool, tooltip and options
    var item = new CurrentItem.with_canvas_item( tool.canvas_item_type() );
    set_item( item );

  }

  //-------------------------------------------------------------
  // Changes the current tool and tooltip for the button.
  public void set_item( CurrentItem item ) {
    var tool = item.get_item_type().tool();
    tooltip_markup = item.get_tooltip(); 
    child          = item.get_image( _canvas.win );
    if( tool.has_properties() ) {
      tooltip_markup += "\n\n%s".printf( _( "Right-click for tool options" ) );
      _options        = create_options( tool );
    } else {
      _options        = null;
    }
  }

  //-------------------------------------------------------------
  // Adds the options for this tool button.  We will 
  private Popover create_options( CanvasTool tool ) {

    var lbl = new Label( Utils.make_title( tool.options_title() ) ) {
      use_markup = true
    };

    var grid = new Grid() {
      row_spacing    = 5,
      column_spacing = 20 
    };

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    box.append( lbl );
    box.append( grid );

    var row = 0;

    if( tool.has_fill() ) {
      create_background_options( grid, ref row );
    }

    if( tool.has_alpha() ) {
      create_alpha_options( grid, ref row );
    }

    if( tool.has_border() ) {
      create_border_options( grid, ref row );
    }

    if( tool.has_fill() || tool.has_border() ) {
      create_outline_options( grid, ref row );
    }

    if( tool.has_font() ) {
      create_font_options( grid, ref row );
    }

    var options = new Popover() {
      child    = box,
      position = PositionType.BOTTOM
    };
    options.set_parent( this );

    return( options );

  }

  //-------------------------------------------------------------
  // Adds a separator to the grid.
  private Separator create_separator( Grid grid, ref int row ) {

    var sep = new Separator( Orientation.HORIZONTAL );
    grid.attach( sep, 0, row, 3 );
    row++;

    return( sep );

  }

  //-------------------------------------------------------------
  // Adds the border options to this tool menu.
  private void create_border_options( Grid grid, ref int row ) {

    create_separator( grid, ref row );

    var lbl = new Label( _( "Border" ) ) {
      xalign = (float)0
    };

    var stroke = new Switch() {
      halign    = Align.START,
      active    = _props.stroke,
      sensitive = _props.fill
    };

    _props.changed.connect(() => {
      stroke.sensitive = _props.fill;
    });

    grid.attach( lbl,    0, row );
    grid.attach( stroke, 1, row );
    row++;

    var color_lbl = new Label( _( "Border Color" ) ) {
      xalign = (float)0
    };

    var dialog = new ColorDialog() {
      modal = true,
      title = _( "Choose Color" ),
      with_alpha = true
    };

    var color = new ColorDialogButton( dialog ) {
      rgba = _props.stroke_color,
      margin_top = 5
    };
    color.notify["rgba"].connect(() => {
      _props.stroke_color = color.get_rgba();
    });

    grid.attach( color_lbl, 0, row );
    grid.attach( color,     1, row, 2 );
    row++;

    var width_sep = create_separator( grid, ref row );
    width_sep.visible = _props.stroke;

    var width_lbl = new Label( _( "Border Width" ) ) {
      xalign = (float)0
    };
    var width_lev = new Revealer() {
      reveal_child = _props.stroke,
      child = width_lbl
    };

    var width_box = new Box( Orientation.VERTICAL, 5 );
    var width_rev = new Revealer() {
      reveal_child = _props.stroke,
      child = width_box
    };

    grid.attach( width_lev, 0, row );
    grid.attach( width_rev, 1, row, 2 );
    row++;

    unowned CheckButton? width_group = null;
    for( int i=0; i<CanvasItemStrokeWidth.NUM; i++ ) {
      var sw = (CanvasItemStrokeWidth)i;
      var width = new CheckButton() {
        halign = Align.FILL,
        active = (_props.stroke_width == sw),
        child  = make_width_icon( 100, sw.width() )
      };
      width.set_group( width_group );
      width.toggled.connect(() => {
        if( width.get_active() ) {
          _props.stroke_width = sw;
        }
      });
      width_box.append( width );
      if( width_group == null ) {
        width_group = width;
      }
    }

    var dash_sep = create_separator( grid, ref row );
    dash_sep.visible = _props.stroke;

    var dash_lbl = new Label( _( "Border Dash" ) ) {
      xalign = (float)0,
    };
    var dash_lev = new Revealer() {
      reveal_child = _props.stroke,
      child = dash_lbl
    };

    var dash_box = new Box( Orientation.VERTICAL, 5 );
    var dash_rev = new Revealer() {
      reveal_child = _props.stroke,
      child = dash_box
    };

    grid.attach( dash_lev, 0, row );
    grid.attach( dash_rev, 1, row, 2 );
    row++;

    unowned CheckButton? dash_group = null;
    for( int i=0; i<CanvasItemDashPattern.NUM; i++ ) {
      var dp = (CanvasItemDashPattern)i;
      var dash = new CheckButton() {
        halign = Align.FILL,
        active = (_props.dash == dp),
        child  = make_dash_icon( 100, dp )
      };
      dash.set_group( dash_group );
      dash.toggled.connect(() => {
        if( dash.get_active() ) {
          _props.dash = dp;
        }
      });
      dash_box.append( dash );
      row++;
      if( dash_group == null ) {
        dash_group = dash;
      }
    }

    stroke.notify["active"].connect(() => {
      _props.stroke          = stroke.active;
      color_lbl.visible      = stroke.active;
      color.visible          = stroke.active;
      width_sep.visible      = stroke.active;
      width_lev.visible      = stroke.active;
      width_rev.reveal_child = stroke.active;
      dash_sep.visible       = stroke.active;
      dash_lev.reveal_child  = stroke.active;
      dash_rev.reveal_child  = stroke.active;
    });

  }

  //-------------------------------------------------------------
  // Returns true if the current mode is dark mode
  private bool is_dark_mode() {

    var settings = Gtk.Settings.get_default();
    if( settings != null ) {
      return( settings.gtk_application_prefer_dark_theme );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Creates the width icon
  private Picture make_width_icon( int width, int stroke_width ) {

    var height = stroke_width;

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)width, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the stroke
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( stroke_width );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    var image = new Picture.for_paintable( snapshot.free_to_paintable( null ) ) {
      halign      = Align.START,
      hexpand     = true,
      content_fit = ContentFit.SCALE_DOWN,
      can_shrink  = false
    };

    return( image );

  }

  //-------------------------------------------------------------
  // Creates the dash icon
  private Picture make_dash_icon( int width, CanvasItemDashPattern dash ) {

    var height = 5;

    var snapshot = new Snapshot();
    var rect     = Graphene.Rect();
    rect.init( 0, 0, (float)width, (float)height );
    var ctx      = snapshot.append_cairo( rect );

    // Draw the image
    Utils.set_context_color( ctx, Utils.color_from_string( is_dark_mode() ? "white" : "black" ) );
    ctx.set_line_width( height );
    dash.set_fg_pattern( ctx );
    ctx.move_to( 0, (height / 2) );
    ctx.line_to( width, (height / 2) );
    ctx.stroke();

    var image = new Picture.for_paintable( snapshot.free_to_paintable( null ) ) {
      halign      = Align.START,
      hexpand     = true,
      content_fit = ContentFit.SCALE_DOWN,
      can_shrink  = false
    };

    return( image );

  }

  //-------------------------------------------------------------
  // Adds the background color options to this tool menu.
  private void create_background_options( Grid grid, ref int row ) {

    create_separator( grid, ref row );

    var lbl = new Label( _( "Fill" ) ) {
      xalign = (float)0
    };

    var fill = new Switch() {
      halign    = Align.START,
      active    = _props.fill,
      sensitive = _props.stroke
    };

    _props.changed.connect(() => {
      fill.sensitive = _props.stroke;
    });

    grid.attach( lbl,  0, row );
    grid.attach( fill, 1, row );
    row++;

    var fill_lbl = new Label( _( "Fill Color" ) ) {
      xalign = (float)0
    };
    var fill_lev = new Revealer() {
      reveal_child = _props.fill,
      child = fill_lbl
    };

    var dialog = new ColorDialog() {
      modal = true,
      title = _( "Choose Color" ),
      with_alpha = true
    };

    var color = new ColorDialogButton( dialog ) {
      rgba = _props.color
    };
    color.notify["rgba"].connect(() => {
      _props.color = color.get_rgba();
    });
    var color_rev = new Revealer() {
      reveal_child = _props.fill,
      child = color
    };

    grid.attach( fill_lev,  0, row );
    grid.attach( color_rev, 1, row, 2 );
    row++;

    fill.notify["active"].connect(() => {
      _props.fill            = fill.active;
      fill_lev.reveal_child  = fill.active;
      color_rev.reveal_child = fill.active;
    });

  }

  //-------------------------------------------------------------
  // Displays options to adjust alpha value of image/sticker.
  private void create_alpha_options( Grid grid, ref int row ) {

    create_separator( grid, ref row );

    var lbl = new Label( _( "Alpha" ) ) {
      xalign = (float)0
    };

    var alpha = new Scale.with_range( Orientation.HORIZONTAL, 0.0, 1.0, 0.05 ) {
      digits = 2,
      draw_value = true,
    };
    alpha.set_value( _props.alpha );

    alpha.value_changed.connect(() => {
      _props.alpha = alpha.get_value();
    });

    grid.attach( lbl,   0, row );
    grid.attach( alpha, 1, row, 2 );
    row++;

  }

  //-------------------------------------------------------------
  // Displays option to enable/disable shape outlining.
  private void create_outline_options( Grid grid, ref int row ) {

    create_separator( grid, ref row );

    var lbl = new Label( _( "Outline" ) ) {
      xalign = (float)0
    };

    var outline = new Switch() {
      halign = Align.START,
      active = _props.outline
    };

    grid.attach( lbl,     0, row );
    grid.attach( outline, 1, row );
    row++;

  }

  //-------------------------------------------------------------
  // Adds the font options to this tool menu.
  private void create_font_options( Grid grid, ref int row ) {

    create_separator( grid, ref row );

    var lbl = new Label( _( "Font" ) ) {
      xalign = (float)0
    };

    var dialog = new FontDialog() {
      modal = true,
      title = _( "Select Font" )
    };

    var font = new FontDialogButton( dialog ) {
      use_font = true
    };

    font.notify["font-desc"].connect(() => {
      _props.font = font.font_desc;
    });

    grid.attach( lbl,  0, row );
    grid.attach( font, 1, row, 2 );
    row++;

  }

}

/*s
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
using Gdk;
using Cairo;

public class CanvasItemSequence : CanvasItem {

  private static int _next_seq_num = 1;

  private int  _font_size;
  private bool _recalc_font_size = true;
  private int  _seq_num;
  private Cursor _sel_cursor;

  public int seq_num {
    get {
      return( _seq_num );
    }
    set {
      _seq_num = value;
      _next_seq_num = value + 1;
    }
  }

  /* Constructor */
  public CanvasItemSequence( Canvas canvas, CanvasItemProperties props ) {
    base( CanvasItemType.SEQUENCE, canvas, props );
    seq_num = _next_seq_num;
    create_points();
    _sel_cursor = new Cursor.from_name( "se-resize", null );
  }

  /* Called when the canvas is used to annotate a new image */
  public static void reset() {
    _next_seq_num = 1;
  }

  /* Creates the item points */
  private void create_points() {
    points.append_val( new CanvasPoint( CanvasPointType.RESIZER0 ) );  // Resizer
  }

  /* Copies the contents of the given item to ourselves */
  public override void copy( CanvasItem item ) {
    base.copy( item );
    _recalc_font_size = true;
  }

  /* Returns a copy of this sequence */
  public override CanvasItem duplicate() {
    var item = new CanvasItemSequence( canvas, props );
    item.copy( this );
    return( item );
  }

  /* Updates the selection boxes whenever the bounding box changes */
  protected override void bbox_changed() {

    var radius       = bbox.width / 2;
    var RAD_distance = ((2 * Math.PI) / 8);
    var RAD_half_PI  = Math.PI / 2;

    var x = bbox.mid_x() + Math.cos( (RAD_distance * 3) - RAD_half_PI ) * radius;
    var y = bbox.mid_y() + Math.sin( (RAD_distance * 3) - RAD_half_PI ) * radius;

    points.index( 0 ).copy_coords( x, y );

  }

  /* Adjusts the bounding box */
  public override void move_selector( int index, double diffx, double diffy, bool shift ) {

    var box = new CanvasRect.from_rect( bbox );

    box.width  += diffy;
    box.height += diffy;

    if( box.width >= (selector_width * 3) ) {
      bbox = box;
      _recalc_font_size = true;
    }

  }

  /* Provides cursor to display when mouse cursor is hovering over the given selector */
  public override Cursor? get_selector_cursor( int index ) {
    return( _sel_cursor );
  }

  //-------------------------------------------------------------
  // Adds the contextual menu items to the given menu.
  protected override void add_contextual_menu_items( CanvasItemMenu menu ) {

    menu.add_spinner( this, _( "Sequence Number:" ), 1, 100, 1, seq_num,
      (item, value) => {
        canvas.undo_buffer.add_item( new UndoItemSequenceNum( this, seq_num, value ) );
        seq_num = value;
        canvas.queue_draw();
      },
      (item, old_value, new_value) => {
        if( old_value != new_value ) {
          canvas.undo_buffer.add_item( new UndoItemSequenceNum( this, old_value, new_value ) );
        }
      }
    );

  }

  //-------------------------------------------------------------
  // Saves this item as XML.
  public override Xml.Node* save( int id, string? image_dir ) {
    Xml.Node* node = base.save( id, image_dir );
    node->set_prop( "sequence-num", seq_num.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this item from XML.
  public override void load( Xml.Node* node ) {
    var f = node->get_prop( "sequence-num" );
    if( f != null ) {
      seq_num = int.parse( f );
    }
    base.load( node );
  }

  /* Figure out the text size that will fit within the boundary box */
  private void set_font_size( Context ctx, out TextExtents extents ) {
    if( _recalc_font_size ) {
      _font_size = 20;
      ctx.set_font_size( _font_size );
      ctx.text_extents( seq_num.to_string(), out extents );
      while( extents.height < (bbox.height / 3) ) {
        _font_size++;
        ctx.set_font_size( _font_size );
        ctx.text_extents( seq_num.to_string(), out extents );
      }
      _recalc_font_size = false;
    } else {
      ctx.set_font_size( _font_size );
      ctx.text_extents( seq_num.to_string(), out extents );
    }

  }

  /* Draw the rectangle */
  public override void draw_item( Context ctx, CanvasItemColor color ) {

    var seq_color = Granite.contrasting_foreground_color( props.color );
    var alpha     = mode.alpha( props.alpha );

    /* Draw the sequence circle */
    Utils.set_context_color_with_alpha( ctx, props.color, alpha );
    ctx.arc( bbox.mid_x(), bbox.mid_y(), (bbox.width / 2), 0, (2 * Math.PI) );
    save_path( ctx, CanvasItemPathType.FILL );
    ctx.fill_preserve();

    Utils.set_context_color_with_alpha( ctx, seq_color, 0.5 );
    ctx.set_line_width( 1 );
    ctx.stroke();

    /* Draw the sequence number inside the circle */
    TextExtents extents;
    ctx.select_font_face( "Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD );
    set_font_size( ctx, out extents );

    Utils.set_context_color_with_alpha( ctx, seq_color, alpha );
    ctx.move_to( (bbox.mid_x() - (extents.width / 2)), (bbox.mid_y() + (extents.height / 2)) );
    ctx.show_text( seq_num.to_string() );
    ctx.new_path();

  }

}



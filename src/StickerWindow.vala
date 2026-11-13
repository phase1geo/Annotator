/*
* Copyright (c) 2026 (https://github.com/phase1geo/Annotator)
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

public class StickerWindow : Granite.Dialog {

  private CanvasItemImage _item;
  private Canvas          _canvas;

  //-------------------------------------------------------------
  // Constructor
  public StickerWindow( MainWindow win, CanvasItemImage item ) {

    Object(
      transient_for: win,
      modal: true
    );

    _item   = item;
    _canvas = win.editor.canvas;

    var box = new Box( Orientation.VERTICAL, 0 );
    var sw = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = box
    };
    sw.set_size_request( 400, 400 );

    var sticker_set = win.sticker_set;
    var categories  = sticker_set.get_categories();

    for( int i=0; i<categories.length; i++ ) {
      var category = create_sticker_category( box, categories.index( i ) );
      var icons    = sticker_set.get_category_icons( categories.index( i ) );
      for( int j=0; j<icons.length; j++ ) {
        var icon = icons.index( j );
        create_sticker_image( category, icon );
      }
    }

    // Add the main dialog content
    get_content_area().append( sw );

    // Add cancel button
    add_button( "Cancel", Gtk.ResponseType.CANCEL );

    // Handle any button clicks
    response.connect((id) => {
      _canvas.items.remove_item( _item );
      _canvas.queue_draw();
      destroy();
    });

  }

  //-------------------------------------------------------------
  // Creates the expander flowbox for the given category name and
  // adds it to the sidebar
  private FlowBox create_sticker_category( Box box, string name ) {

    // Create the flowbox which will contain the stickers
    var fbox = new FlowBox() {
      homogeneous = true,
      selection_mode = SelectionMode.NONE,
      min_children_per_line = 4,
      max_children_per_line = 4
    };

    // Create expander
    var exp = new Expander( Utils.make_title( name ) ) {
      margin_start = 20,
      margin_end   = 20,
      margin_top   = 20,
      use_markup   = true,
      expanded     = true,
      child        = fbox
    };

    box.append( exp );

    return( fbox );

  }

  //-------------------------------------------------------------
  // Creates the image from the given name and adds it to the
  // flow box
  private void create_sticker_image( FlowBox box, StickerInfo info ) {

    var buf     = StickerSet.make_pixbuf( info.resource );
    var texture = Gdk.Texture.for_pixbuf( buf );
    var picture = new Picture.for_paintable( texture ) {
      can_shrink = false
    };

    var btn = new Button() {
      has_frame    = false,
      tooltip_text = info.tooltip,
      child        = picture
    };

    btn.clicked.connect(() => {
      _item.create_image( info.resource );
      _canvas.queue_draw();
      destroy();
    });

    box.append( btn );

  }

}

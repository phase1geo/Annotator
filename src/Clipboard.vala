
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
using GLib;
using Gdk;

public class AnnotatorClipboard {

  const string ITEMS_MIME_TYPE = "x-application/annotator-items";

  /* Copies the selected text to the clipboard */
  public static void copy_text( string txt ) {
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_text( txt );
  }

  /* Copies the selected image to the clipboard */
  public static void copy_image( Pixbuf img ) {
    var clipboard = Display.get_default().get_clipboard();
    var texture   = new Texture.for_pixbuf( img );
    clipboard.set_texture( texture );
  }

  /* Copies the selected items to the clipboard */
  public static void copy_items( string it ) {
    var bytes     = new Bytes( it.data );
    var provider  = new ContentProvider.from_bytes( "application/xml", bytes );
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_content( provider );
  }

  /* Returns true if text is pasteable from the clipboard */
  public static bool text_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_gtype( Type.STRING ) );
  }

  /* Returns true if image is pastable from the clipboard */
  public static bool image_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( "image/png" ) );
  }

  /* Returns true if CanvasItems are pasteable from the clipboard */
  public static bool items_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( "application/xml" ) );
  }

  /* Called to paste current item in clipboard to the given Canvas */
  public static void paste( Editor editor ) {

    var clipboard = Display.get_default().get_clipboard();

    try {
      if( clipboard.get_formats().contain_mime_type( "application/xml" ) ) {
        clipboard.read_async.begin( {"application/xml"}, (obj, res) => {
          var stream = clipboard.read_async.end( res );
          uint8 buffer[];
		      stream.read( buffer );
          editor.paste_items( (string)buffer );
        });
      } else if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
        clipboard.read_text_async.begin((obj, res) => {
          var text = clipboard.read_text_async.end( res );
        });
      } else if( clipboard.get_formats().contain_gtype( GDK_TYPE_TEXTURE ) ) {
        clipboard.read_async.begin( {"image/png"}, (obj, res) => {
          var stream = clipboard.read_async.end( res );
          var pixbuf = new Pixbuf.from_stream( stream );
          editor.paste_image( pixbuf, true );
        });
      }
    } catch( Error e ) {}

  }

}

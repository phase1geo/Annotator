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

using Gtk;
using GLib;
using Gdk;

public class AnnotatorClipboard {

  const string ITEMS_MIME_TYPE = "x-application/annotator-items";

  //-------------------------------------------------------------
  // Returns the system's primary clipboard.
  public static Clipboard get_clipboard() {
    return( Display.get_default().get_clipboard() );
  }

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard
  public static void copy_text( string txt ) {
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_text( txt );
  }

  //-------------------------------------------------------------
  // Copies the selected image to the clipboard
  public static void copy_image( Pixbuf img ) {
    var clipboard = Display.get_default().get_clipboard();
    var texture   = Texture.for_pixbuf( img );
    clipboard.set_texture( texture );
  }

  //-------------------------------------------------------------
  // Copies the selected items to the clipboard
  public static void copy_items( string it ) {
    var bytes     = new Bytes( it.data );
    var provider  = new ContentProvider.for_bytes( "application/xml", bytes );
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_content( provider );
  }

  //-------------------------------------------------------------
  // Returns true if text is pasteable from the clipboard
  public static bool text_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_gtype( Type.STRING ) );
  }

  //-------------------------------------------------------------
  // Returns true if image is pastable from the clipboard
  public static bool image_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( "image/png" ) );
  }

  //-------------------------------------------------------------
  // Returns true if CanvasItems are pasteable from the clipboard
  public static bool items_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( "application/xml" ) );
  }

  //-------------------------------------------------------------
  // Called to paste current item in clipboard to the given Canvas
  public static bool paste( Editor editor, bool image_only = false ) {

    var clipboard = Display.get_default().get_clipboard();
    var retval    = false;

    try {
      if( clipboard.get_formats().contain_mime_type( "image/png" ) ) {
        clipboard.read_texture_async.begin( null, (ob, res) => {
          var texture = clipboard.read_texture_async.end( res );
          if( texture != null ) {
            var pixbuf = Utils.texture_to_pixbuf( texture );
            editor.paste_image( pixbuf, true );
          }
        });
        retval = true;
      } else if( !image_only && clipboard.get_formats().contain_mime_type( "application/xml" ) ) {
        clipboard.read_async.begin( {"application/xml"}, 0, null, (obj, res) => {
          string str;
          var stream   = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          editor.paste_items( contents );
        });
        retval = true;
      } else if( !image_only && clipboard.get_formats().contain_gtype( Type.STRING ) ) {
        clipboard.read_text_async.begin( null, (obj, res) => {
          var text = clipboard.read_text_async.end( res );
          editor.paste_text( text );
        });
        retval = true;
      }
    } catch( Error e ) {}

    return( retval );

  }

}

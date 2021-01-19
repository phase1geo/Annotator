
/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

  private static string? text  = null;
  private static Pixbuf  image = null;
  private static bool    set_internally = false;

  enum Target {
    STRING,
    IMAGE
  }

  const TargetEntry[] text_target_list = {
    { "UTF8_STRING", 0, Target.STRING },
    { "text/plain",  0, Target.STRING },
    { "STRING",      0, Target.STRING }
  };

  const TargetEntry[] image_target_list = {
    { "image/png", 0, Target.IMAGE }
  };

  public static void set_with_data( Clipboard clipboard, SelectionData selection_data, uint info, void* user_data_or_owner) {
    switch( info ) {
      case Target.STRING:
        if( text != null ) {
          selection_data.set_text( text, -1 );
        }
        break;
      case Target.IMAGE:
        if( image != null ) {
          selection_data.set_pixbuf( image );
        }
        break;
    }
  }

  /* Clears the class structure */
  public static void clear_data( Clipboard clipboard, void* user_data_or_owner ) {
    if( !set_internally ) {
      text  = null;
      image = null;
    }
    set_internally = false;
  }

  /* Copies the selected text to the clipboard */
  public static void copy_text( string txt ) {

    /* Store the data to copy */
    text           = txt;
    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( text_target_list, set_with_data, clear_data, null );

  }

  public static void copy_image( Pixbuf img ) {

    /* Store the data to copy */
    image          = img;
    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( image_target_list, set_with_data, clear_data, null );

  }

  /* Called to paste current item in clipboard to the given Canvas */
  public static void paste( Editor editor ) {

    var clipboard   = Clipboard.get_default( Gdk.Display.get_default() );
    var text_needed = false;  // da.is_node_editable() || da.is_connection_editable();

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    Atom? text_atom  = null;
    Atom? image_atom = null;

    /* Get the list of targets that we will support */
    foreach( var target in targets ) {
      switch( target.name() ) {
        case "UTF8_STRING"     :
        case "STRING"          :
        case "text/plain"      :  text_atom  = text_atom  ?? target;  break;
        case "image/png"       :  image_atom = image_atom ?? target;  break;
      }
    }

    /* If we need to handle pasting text, do it here */
    if( (image_atom != null) && ((text_atom == null) || !text_needed) ) {
      clipboard.request_contents( image_atom, (c, raw_data) => {
        var data = raw_data.get_pixbuf();
        if( data == null ) return;
        editor.paste_image( data );
      });

    /* If we need to handle pasting an image, do it here */
    } else if( text_atom != null ) {
      clipboard.request_contents( text_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        editor.paste_text( data );
      });
    }

  }

}

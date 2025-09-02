/*
* Copyright (c) 2020 (https://github.com/phase1geo/Annotator)
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

public class Exports {

  private Array<Export> _exports;

  public ExportClipboard clipboard { get; private set; }
  public ExportPrint     printer   { get; private set; }

  /* Constructor */
  public Exports( Canvas canvas ) {

    _exports = new Array<Export>();

    /* Add the exports */
    add( new ExportImage( canvas, "jpeg", _( "JPEG" ), { ".jpg", ",.jpeg" } ) );
    add( new ExportImage( canvas, "tiff", _( "TIFF" ), { ".tiff" } ) );
    add( new ExportImage( canvas, "bmp",  _( "BMP" ),  { ".bmp" } ) );
    add( new ExportPDF( canvas ) );
    add( new ExportPNG( canvas ) );
    add( new ExportSVG( canvas ) );
    add( new ExportEditable( canvas ) );
    add( new ExportWebP( canvas ) );

    clipboard = new ExportClipboard( canvas );
    printer   = new ExportPrint( canvas );

  }

  private void add( Export export ) {
    export.settings_changed.connect(() => {
      save();
    });
    _exports.append_val( export );
  }

  /* Returns the number of stored exports */
  public int length() {
    return( (int)_exports.length );
  }

  /* Returns the export at the given index */
  public Export index( int idx ) {
    return( _exports.index( idx ) );
  }

  /*
   Returns the export as determined by the given name; otherwise, returns null
   if name does not refer to a valid export type.
  */
  public Export? get_by_name( string name ) {
    for( int i=0; i<_exports.length; i++ ) {
      if( _exports.index( i ).name == name ) {
        return( _exports.index( i ) );
      }
    }
    return( null );
  }

  /* Gets the save filename and creates the parent directory if it doesn't exist */
  private string? settings_file( bool make_dir ) {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "annotator" );
    if( make_dir && !Utils.create_dir( dir ) ) {
      return( null );
    }
    return( GLib.Path.build_filename( dir, "exports.xml" ) );
  }

  /* Saves the settings to the save file */
  public void save() {
    var sfile = settings_file( true );
    if( sfile == null ) {
      return;
    }
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "exports" );
    root->set_prop( "version", Annotator.version );
    doc->set_root_element( root );
    for( int i=0; i<_exports.length; i++ ) {
      root->add_child( _exports.index( i ).save() );
    }
    doc->save_format_file( sfile, 1 );
    delete doc;
  }

  /* Loads the settings from the save file */
  public void load() {
    var sfile = settings_file( false );
    if( (sfile == null) || !FileUtils.test( sfile, FileTest.EXISTS ) ) return;
    Xml.Doc* doc = Xml.Parser.read_file( sfile, null, Xml.ParserOption.HUGE );
    if( doc == null ) return;
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "export") ) {
        var export_name = it->get_prop( "name" );
        for( int i=0; i<_exports.length; i++ ) {
          if( _exports.index( i ).name == export_name ) {
            _exports.index( i ).load( it );
            break;
          }
        }
      }
    }
    delete doc;
  }

}



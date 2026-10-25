/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

public class ToolProperties {

  private Array<CanvasItemProperties?> _props;
  private bool                         _changed = false;

  //-------------------------------------------------------------
  // Constructor
  public ToolProperties() {

    _props = new Array<CanvasItemProperties?>();

    for( int i=0; i<CanvasTool.NUM; i++ ) {
      var tool = (CanvasTool)i;
      if( tool.has_properties() ) {
        var prop = new CanvasItemProperties();
        prop.changed.connect(() => {
          _changed = true;
        });
        _props.append_val( prop );
      } else {
        CanvasItemProperties? prop = null;
        _props.append_val( prop );
      }
    }

    load();

  }

  //-------------------------------------------------------------
  // Returns the item properties for the given canvas tool.
  public CanvasItemProperties? get_properties( CanvasTool tool ) {
    return( _props.index( tool ) );
  }

  //-------------------------------------------------------------
  // Gets the save filename and creates the parent directory if
  // it doesn't exist
  private string? properties_file( bool make_dir ) {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "annotator" );
    if( make_dir && !Utils.create_dir( dir ) ) {
      return( null );
    }
    return( GLib.Path.build_filename( dir, "properties.xml" ) );
  }

  //-------------------------------------------------------------
  // Saves the settings to the save file
  public void save( Canvas canvas ) {
    var sfile = properties_file( true );
    if( (sfile == null) || !_changed ) {
      return;
    }
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "properties" );
    root->set_prop( "version", canvas.win.application.version );
    doc->set_root_element( root );
    for( int i=0; i<_props.length; i++ ) {
      var tool = (CanvasTool)i;
      root->add_child( _props.index( i ).save( tool.to_string() ) );
    }
    doc->save_format_file( sfile, 1 );
    _changed = false;
    delete doc;
  }

  //-------------------------------------------------------------
  // Loads the settings from the save file
  public void load() {
    var sfile = properties_file( false );
    if( (sfile == null) || !FileUtils.test( sfile, FileTest.EXISTS ) ) return;
    Xml.Doc* doc = Xml.Parser.read_file( sfile, null, Xml.ParserOption.HUGE );
    if( doc == null ) return;
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        var tool = CanvasTool.parse( it->name );
        if( tool != CanvasTool.NUM ) {
          _props.index( tool ).load( it );
        }
      }
    }
    delete doc;
  }

}

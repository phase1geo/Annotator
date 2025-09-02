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

using Cairo;
using Gdk;
using Gtk;

public class ExportEditable : Export {

  //-------------------------------------------------------------
  // Default constructor
  public ExportEditable( Canvas canvas ) {
    base( canvas, "annotator", _( "Annotator" ), { ".annotator" } );
  }
  
  //-------------------------------------------------------------
  // Main export function.
  public override bool export( string filename, Pixbuf source ) {

    /* Make sure that the filename is sane */
    var fname = repair_filename( filename );

    /* Figure out if the user wants to include the images or not */
    save( fname );

    return( true );

  }

  //-------------------------------------------------------------
  // Saves the *.annotator file as a temporary directory such that
  // images used within the annotation are saved into the directory
  // and the directory is zipped and archived as the final *.annotator
  // file.
  private void save( string fname ) {

    string temp_dir;

    // Make the temporary directory
    try {
      temp_dir = DirUtils.make_tmp( "annotator-XXXXXX" );
    } catch( Error e ) {
      critical( e.message );
      return;
    }

    var image_dir = GLib.Path.build_filename( temp_dir, "images" );
    DirUtils.create( image_dir, 0755 );

    var annotations_file = GLib.Path.build_filename( temp_dir, "annotations.xml" );
    save_xml( annotations_file, image_dir );

    // Create the tar.gz archive named according the the first argument
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( fname );

    // Add the Minder file to the archive
    archive_file( archive, annotations_file );

    // Add the images
    string? name = null;
    var     dir  = Dir.open( image_dir );
    while( (name = dir.read_name()) != null ) {
      archive_file( archive, GLib.Path.build_filename( image_dir, name ) );
    }

    // Close the archive
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

  }

  //-------------------------------------------------------------
  // Adds the given file to the archive.
  public bool archive_file( Archive.Write archive, string fname, int? image_id = null ) {

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read();
      var data_input_stream = new DataInputStream( input_stream );

      /* Add an entry to the archive */
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
      entry.set_size( (Archive.int64_t)file_info.get_size() );
      entry.set_filetype( Archive.FileType.IFREG );
      entry.set_perm( (Archive.FileMode)0644 );

      if( image_id != null ) {
        entry.xattr_add_entry( "image_id", (void*)image_id, sizeof( int ) );
      }

      if( archive.write_header( entry ) != Archive.Result.OK ) {
        critical ("Error writing '%s': %s (%d)", file.get_path (), archive.error_string (), archive.errno ());
        return( false );
      }

      /* Add the actual content of the file */
      size_t bytes_read;
      uint8[] buffer = new uint8[64];
      while( data_input_stream.read_all( buffer, out bytes_read ) ) {
        if( bytes_read <= 0 ) {
          break;
        }
        archive.write_data( buffer );
      }

    } catch( Error e ) {
      stdout.printf( "ERROR archiving: %s\n", e.message );
      critical( e.message );
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Saves the XML information from the annotation.  Copies the stored
  // images in the given image directory, if specified.
  private void save_xml( string fname, string image_dir ) {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "exports" );

    root->set_prop( "version", Annotator.version );
    root->add_child( canvas.save( image_dir, get_scale( "image-compression" ) ) );

    doc->set_root_element( root );
    doc->save_format_file( fname, 1 );
    delete doc;

  }

  //-------------------------------------------------------------
  // Loads the XML file and updates the editor.
  private bool load_xml( string fname ) {

    Xml.Doc* doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) return( false );

    var loaded = false;
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "canvas") ) {
        loaded = canvas.load( it );
      }
    }

    delete doc;

    return( loaded );

  }

  //-------------------------------------------------------------
  // Imports the given filename.
  public bool import( string filename ) {

    string temp_dir;

    // Make the temporary directory
    try {
      temp_dir = DirUtils.make_tmp( "annotator-XXXXXX" );
    } catch( Error e ) {
      critical( e.message );
      return( false );
    }

    Archive.Read archive = new Archive.Read();
    archive.support_filter_gzip();
    archive.support_format_all();

    Archive.ExtractFlags flags;
    flags  = Archive.ExtractFlags.TIME;
    flags |= Archive.ExtractFlags.PERM;
    flags |= Archive.ExtractFlags.ACL;
    flags |= Archive.ExtractFlags.FFLAGS;

    Archive.WriteDisk extractor = new Archive.WriteDisk();
    extractor.set_options( flags );
    extractor.set_standard_lookup();

    /* Open the portable Minder file for reading */
    if( archive.open_filename( filename, 16384 ) != Archive.Result.OK ) {
      return( false );
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      /*
       We will need to modify the entry pathname so the file is written to the
       proper location.
      */
      if( entry.pathname() == "annotations.xml" ) {
        entry.set_pathname( GLib.Path.build_filename( temp_dir, entry.pathname() ) );
      } else {
        entry.set_pathname( GLib.Path.build_filename( temp_dir, "images", entry.pathname() ) );
      }

      /* Read from the archive and write the files to disk */
      if( extractor.write_header( entry ) != Archive.Result.OK ) {
        continue;
      }
      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
        }
      }

    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
      return( false );
    }

    /* Finally, load the XML file */
    return( load_xml( GLib.Path.build_filename( temp_dir, "annotations.xml" ) ) );

  }

  //-------------------------------------------------------------
  // Add the setting to enable/disable including the images included
  // in the annotation.
  public override void add_settings( Grid grid ) {
    add_setting_scale( "image-compression", grid, _( "Image Compression" ), null, 0, 9, 1, 0 );
  }

  //-------------------------------------------------------------
  // Save the settings.
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "compression", get_scale( "image-compression" ).to_string() );
  }

  //-------------------------------------------------------------
  // Load the settings.
  public override void load_settings( Xml.Node* node ) {
    var c = node->get_prop( "compression" );
    if( c != null ) {
      set_scale( "image-compression", int.parse( c ) );
    }
  }

}

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

using Gtk;
using Gdk;
using Cairo;

public enum ExportType {
  JPEG,
  PNG,
  TIFF,
  BMP,
  PDF,
  SVG,
  NUM;

  public string to_string() {
    switch( this ) {
      case JPEG :  return( "jpeg" );
      case PNG  :  return( "png" );
      case TIFF :  return( "tiff" );
      case BMP  :  return( "bmp" );
      case PDF  :  return( "pdf" );
      case SVG  :  return( "svg" );
      default   :  assert_not_reached();
    }
  }

  public string description() {
    switch( this ) {
      case JPEG :  return( _( "JPEG Image (JPEG)" ) );
      case PNG  :  return( _( "Portable Network Graphics (PNG)" ) );
      case TIFF :  return( _( "Tag Image File Format (TIFF)" ) );
      case BMP  :  return( _( "Bitmap Image (BMP)" ) );
      case PDF  :  return( _( "Portable Document Format (PDF)" ) );
      case SVG  :  return( _( "Scalable Vector Graphics (SVG)" ) );
      default   :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case JPEG :  return( _( "Export As JPEG…" ) );
      case PNG  :  return( _( "Export As PNG…" ) );
      case TIFF :  return( _( "Export As TIFF…" ) );
      case BMP  :  return( _( "Export As BMP…" ) );
      case PDF  :  return( _( "Export As PDF…" ) );
      case SVG  :  return( _( "Export As SVG…" ) );
      default   :  assert_not_reached();
    }
  }

  public string extension() {
    switch( this ) {
      case JPEG :  return( _( ".jpg" ) );
      case PNG  :  return( _( ".png" ) );
      case TIFF :  return( _( ".tiff" ) );
      case BMP  :  return( _( ".bmp" ) );
      case PDF  :  return( _( ".pdf" ) );
      case SVG  :  return( _( ".svg" ) );
      default   :  assert_not_reached();
    }
  }

}

public class Exporter {

  private Canvas       _canvas;
  private ImageSurface _surface;

  /* Constructor */
  public Exporter( Canvas canvas ) {
    _canvas = canvas;
  }

  /* Exports to a user chosen file */
  public void export_image( ImageSurface source, ExportType type, string? filename = null ) {

    var fname = (filename == null) ? get_filename( type ) : filename;

    /* If the user cancelled the export, return now */
    if( fname == null ) return;

    /* Perform the export */
    switch( type ) {
      case ExportType.PDF :  export_pdf( filename, source );  break;
      case ExportType.SVG :  export_svg( filename, source );  break;
      default             :  export_other( filename, source, type );  break;
    }

  }

  /* Returns a filename from the user through a save dialog */
  private string? get_filename( ExportType type ) {

    /* Get the file to open from the user */
    var dialog   = new FileChooserNative( _( "Export Image" ), _canvas.win, FileChooserAction.SAVE, _( "Export" ), _( "Cancel" ) );
    Utils.set_chooser_folder( dialog );

    /* Create file filters */
    var filter = new FileFilter();
    filter.set_filter_name( type.description() );
    filter.add_pattern( "*" + type.to_string() );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      var filename = dialog.get_filename();
      if( !filename.has_suffix( type.extension() ) ) {
        filename += type.extension();
      }
      Utils.store_chooser_folder( filename );
      return( filename );
    }

    return( null );

  }

  /* Exports the given image type to file */
  private void export_other( string filename, ImageSurface source, ExportType type ) {

    string[] opt_keys   = {};
    string[] opt_values = {};

    /* Create the drawing surface */
    var surface = new ImageSurface( Format.RGB24, source.get_width(), source.get_height() );
    var context = new Context( surface );
    _canvas.on_draw( context );

    try {
      var pixbuf = pixbuf_get_from_surface( surface, 0, 0, surface.get_width(), surface.get_height() );
      pixbuf.savev( filename, type.to_string(), opt_keys, opt_values );
    } catch( Error e ) {
      stdout.printf( "%s\n", e.message );
    }

  }

  /* Exports the current image in PDF format */
  private void export_pdf( string filename, ImageSurface source ) {

    /* Get the width and height of the page */
    double page_width  = 8.5 * 72;
    double page_height = 11  * 72;
    double margin      = 0.5 * 72;

    /* Create the drawing surface */
    var surface = new PdfSurface( filename, page_width, page_height );
    var context = new Context( surface );
    var x       = 0;
    var y       = 0;
    var w       = source.get_width();
    var h       = source.get_height();

    /* Calculate the required scaling factor to get the document to fit */
    double width  = (page_width  - (2 * margin)) / w;
    double height = (page_height - (2 * margin)) / h;
    double sf     = (width < height) ? width : height;

    /* Scale and translate the image */
    context.scale( sf, sf );
    context.translate( ((0 - x) + (margin / sf)), ((0 - y) + (margin / sf)) );

    /* Recreate the image */
    _canvas.on_draw( context );

    /* Draw the page to the PDF file */
    context.show_page();

  }

  /* Exports the current image in SVG format */
  private void export_svg( string filename, ImageSurface source ) {

    /* Get the rectangle holding the entire document */
    var x = 0;
    var y = 0;
    var w = source.get_width();
    var h = source.get_height();

    /* Create the drawing surface */
    var surface = new SvgSurface( filename, w, h );
    var context = new Context( surface );

    surface.restrict_to_version( SvgVersion.VERSION_1_1 );

    /* Recreate the image */
    _canvas.on_draw( context );

    /* Draw the page to the PDF file */
    context.show_page();

  }

  /* Exports to the clipboard */
  public void export_clipboard( ImageSurface source ) {

    /* Create the drawing surface */
    var surface = new ImageSurface( Format.RGB24, source.get_width(), source.get_height() );
    var context = new Context( surface );
    _canvas.on_draw( context );

    /* Get the pixbuf */
    var pixbuf = pixbuf_get_from_surface( surface, 0, 0, surface.get_width(), surface.get_height() );

    /* Copy the image to the clipboard */
    AnnotatorClipboard.copy_image( pixbuf );

  }

  public void export_print( ImageSurface source ) {

    _surface = source;

    var op       = new PrintOperation();
    var settings = new PrintSettings();
    op.set_print_settings( settings );
    op.set_n_pages( 1 );
    op.set_unit( Unit.MM );

    /* Connect to the draw_page signal */
    op.draw_page.connect( draw_page );

    try {
      var res = op.run( PrintOperationAction.PRINT_DIALOG, _canvas.win );
      switch( res ) {
        case PrintOperationResult.APPLY :
          settings = op.get_print_settings();
          // Save the settings to a file - settings.to_file( fname );
          break;
        case PrintOperationResult.ERROR :
          /* TBD - Display the print error */
          break;
        case PrintOperationResult.IN_PROGRESS :
          /* TBD */
          break;
      }
    } catch( GLib.Error e ) {
      /* TBD */
    }

  }

  /* Draws the page */
  public void draw_page( PrintOperation op, PrintContext context, int page_nr ) {

    var ctx         = context.get_cairo_context();
    var page_width  = context.get_width();
    var page_height = context.get_height();
    var margin_x    = 0.5 * context.get_dpi_x();
    var margin_y    = 0.5 * context.get_dpi_y();

    /* Get the rectangle holding the entire document */
    var x = 0;
    var y = 0;
    var w = _surface.get_width();
    var h = _surface.get_height();

    /* Calculate the required scaling factor to get the document to fit */
    double width  = (page_width  - (2 * margin_x)) / w;
    double height = (page_height - (2 * margin_y)) / h;
    double sf     = (width < height) ? width : height;

    /* Scale and translate the image */
    ctx.scale( sf, sf );
    ctx.translate( ((0 - x) + margin_x), ((0 - y) + margin_y) );

    /* Set the source */
    _canvas.on_draw( ctx );

  }

}


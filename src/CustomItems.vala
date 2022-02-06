using Gtk;

public class CustomItems : Object {

  private List<CustomItem> _items;

  public signal void edit_start_custom( CanvasItemCategory category );
  public signal void edit_end_custom( CanvasItemCategory category );
  public signal void item_removed();

  /* Default constructor */
  public CustomItems() {
    _items = new List<CustomItem>();
  }

  /* Adds the given custom item to the stored list */
  public void add( CustomItem item ) {
    _items.append( item );
    save();
  }

  /*
   Creates the custom menu UI and adds it to the end of the given box.
  */
  public void create_menu( CanvasItems canvas_items, CanvasItemCategory category, Popover popover, Box box, string label_str, int columns = 4 ) {

    var rev_box = new Box( Orientation.VERTICAL, 5 );

    var lbl = new Label( label_str );
    var edit = new Button.with_label( _( "Edit" ) );
    edit.relief = ReliefStyle.NONE;

    var fb = new FlowBox();
    fb.orientation = Orientation.HORIZONTAL;
    fb.min_children_per_line = columns;
    fb.max_children_per_line = columns;
    popover.show.connect(() => {
      edit_end_custom( category );
      populate_menu( canvas_items, category, popover, fb );
      if( fb.get_children().length() == 0 ) {
        rev_box.hide();
      } else {
        rev_box.show();
      }
    });

    edit.clicked.connect(() => {
      if( edit.label == _( "Edit" ) ) {
        edit_start_custom( category );
      } else {
        edit_end_custom( category );
      }
    });
    edit_start_custom.connect((c) => {
      if( c == category ) {
        edit.label = _( "Done" );
      }
    });
    edit_end_custom.connect((c) => {
      if( c == category ) {
        edit.label = _( "Edit" );
      }
    });

    var lbl_box = new Box( Orientation.HORIZONTAL, 0 );
    lbl_box.pack_start( lbl,  false, false, 0 );
    lbl_box.pack_end(   edit, false, false, 0 );

    rev_box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true, 0 );
    rev_box.pack_start( lbl_box, false, true,  0 );
    rev_box.pack_start( fb,      false, false, 0 );

    item_removed.connect(() => {
      if( fb.get_children().length() == 0 ) {
        rev_box.hide();
      }
    });

    /* Add the revealer to the box */
    box.pack_start( rev_box, false, true, 0 );

  }

  /*
   Populates the given menu to display all custom items in the given category.  Returns true if
   at least one custom item was found for the given category; otherwise, returns false to indicate
   that the popover should not be popped up..
  */
  public void populate_menu( CanvasItems canvas_items, CanvasItemCategory category, Popover popover, FlowBox fb ) {

    /* Clear the flowbox */
    fb.get_children().foreach((child) => {
      fb.remove( child );
    });

    /* Add the items into the flowbox */
    _items.foreach((item) => {
      if( item.item.itype.category() == category ) {

        var box = new Box( Orientation.HORIZONTAL, 0 );
        var mb  = new Button();
        mb.image = item.get_image();
        mb.clicked.connect(() => {
          add_item_to_canvas( canvas_items, item.item );
          popover.popdown();
        });

        var del = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );

        var start_id = edit_start_custom.connect((c) => {
          if( c == category ) {
            mb.set_sensitive( false );
            box.pack_start( del, false, false, 0 );
            box.show_all();
          }
        });
        var end_id = edit_end_custom.connect((c) => {
          if( c == category ) {
            mb.set_sensitive( true );
            box.remove( del );
            box.show_all();
          }
        });

        del.clicked.connect(() => {
          _items.remove( item );
          save();
          disconnect( start_id );
          disconnect( end_id );
          fb.remove( box.parent );
          fb.show_all();
          item_removed();
        });

        box.pack_start( mb, false, false, 0 );
        fb.add( box );

      }
    });

    fb.show_all();

  }

  private void add_item_to_canvas( CanvasItems canvas_items, CanvasItem item ) {
    var it = item.duplicate();
    it.bbox = canvas_items.center_box( it.bbox.width, it.bbox.height );
    canvas_items.add_item( it, -1, true );
  }

  /* Returns the local filename containing the custom items */
  private string filename() {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "annotator" );
    DirUtils.create_with_parents( dir, 0775 );
    return( GLib.Path.build_filename( dir, "customs.xml" ) );
  }

  /* Saves all of the custom items */
  public void save() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "custom-items" );
    root->set_prop( "version", Annotator.version );

    _items.foreach((item) => {
      root->add_child( item.save() );
    });

    doc->set_root_element( root );
    doc->save_format_file( filename(), 1 );

    delete doc;

  }

  /* Loads the custom file */
  public void load( CanvasItems canvas_items ) {

    var fname = filename();

    /* If the filename does not exist, skip the load */
    if( !FileUtils.test( fname, FileTest.EXISTS ) ) {
      return;
    }

    Xml.Doc* doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return;
    }

    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "custom-item") ) {
        var item = new CustomItem();
        item.load( it, canvas_items );
        _items.append( item );
      }
    }

    delete doc;

  }

}

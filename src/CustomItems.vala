using Gtk;

public class CustomItems : Object {

  private List<CustomItem> _items;

  public signal void item_selected( CanvasItemCategory category, CustomItem item );
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
  public void create_menu( CanvasItemCategory category, Popover popover, Box box, string label_str, int columns = 4 ) {

    var rev_box = new Box( Orientation.VERTICAL, 5 );

    var lbl = new Label( label_str ) {
      halign = Align.START
    };
    var edit = new Button.with_label( _( "Edit" ) ) {
      halign = Align.END,
      has_frame = false
    };

    var fb = new FlowBox() {
      orientation = Orientation.HORIZONTAL,
      min_children_per_line = columns,
      max_children_per_line = columns
    };
    popover.show.connect(() => {
      edit_end_custom( category );
      populate_menu( category, fb );
      if( fb.get_first_child() == null ) {
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
    lbl_box.append( lbl );
    lbl_box.append( edit );

    rev_box.append( new Separator( Orientation.HORIZONTAL ) );
    rev_box.append( lbl_box );
    rev_box.append( fb );

    item_removed.connect(() => {
      if( fb.get_first_child() == null ) {
        rev_box.hide();
      }
    });

    /* Add the revealer to the box */
    box.append( rev_box );

  }

  /*
   Populates the given menu to display all custom items in the given category.  Returns true if
   at least one custom item was found for the given category; otherwise, returns false to indicate
   that the popover should not be popped up..
  */
  public void populate_menu( CanvasItemCategory category, FlowBox fb ) {

    /* Clear the flowbox */
    while( fb.get_first_child() != null ) {
      fb.remove( fb.get_first_child() );
    }

    /* Add the items into the flowbox */
    _items.foreach((item) => {
      if( item.item.itype.category() == category ) {

        var box = new Box( Orientation.HORIZONTAL, 0 );
        var mb  = new Button() {
          child = item.get_image()
        };
        mb.clicked.connect(() => {
          item_selected( category, item );
        });

        var del = new Button.from_icon_name( "edit-delete-symbolic" );

        var start_id = edit_start_custom.connect((c) => {
          if( c == category ) {
            mb.set_sensitive( false );
            box.append( del );
          }
        });
        var end_id = edit_end_custom.connect((c) => {
          if( c == category ) {
            mb.set_sensitive( true );
            box.remove( del );
          }
        });

        del.clicked.connect(() => {
          _items.remove( item );
          save();
          disconnect( start_id );
          disconnect( end_id );
          fb.remove( box.parent );
          item_removed();
        });

        box.append( mb );
        fb.append( box );

      }
    });

  }

  private void add_item_to_canvas( CanvasItems canvas_items, CustomItem item ) {
    var it = item.item.duplicate();
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

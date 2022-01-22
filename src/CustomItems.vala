using Gtk;

public class CustomItems {

  private List<CustomItem> _items;

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
   Populates the given menu to display all custom items in the given category.  Returns true if
   at least one custom item was found for the given category; otherwise, returns false to indicate
   that the popover should not be popped up..
  */
  public bool populate_menu( CanvasItems canvas_items, CanvasItemCategory category, Popover popover ) {
    var mbox = new Box( Orientation.VERTICAL, 0 );
    _items.foreach((item) => {
      if( item.item.itype.category() == category ) {
        var box   = new Box( Orientation.HORIZONTAL, 5 );
        var icon  = item.icon;
        var mb    = new ModelButton();
        mb.text = item.name;
        mb.clicked.connect(() => {
          var it = item.item.duplicate();
          it.bbox = canvas_items.center_box( it.bbox.width, it.bbox.height );
          canvas_items.add_item( it, -1, true );
          popover.popdown();
        });
        var del   = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
        del.clicked.connect(() => {
          _items.remove( item );
          save();
          mbox.remove( box );
          mbox.show_all();
          if( mbox.get_children().length() == 0 ) {
            popover.popdown();
          }
        });
        box.margin = 5;
        box.pack_start( icon, false, false, 0 );
        box.pack_start( mb,   false, false, 0 );
        box.pack_end(   del,  false, false, 0 );
        mbox.add( box );
      }
    });
    mbox.show_all();
    popover.add( mbox );
    return( mbox.get_children().length() > 0 );
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

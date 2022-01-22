using Gtk;

public class CustomItem {

  private static const int icon_size = 16;

  public string      name { get; private set; default = ""; }
  public CanvasItem? item { get; private set; default = null; }
  public Image?      icon { get; private set; default = null; }

  /* Default constructor */
  public CustomItem() {
    name = "";
    item = null;
    icon = null;
  }

  /* Constructor */
  public CustomItem.with_item( string name, CanvasItem item ) {
    this.name = name;
    this.item = item;
    create_icon();
  }

  /* Create an icon from the item */
  private void create_icon() {
    if( item != null ) {
      var src = new Cairo.ImageSurface( Cairo.Format.A8, icon_size, icon_size );
    	var ctx = new Cairo.Context( src );
      var it  = item.duplicate();
      ctx.scale( ((icon_size * 1.0) / it.bbox.width), ((icon_size * 1.0) / it.bbox.height) );
      it.move_item( (0 - it.bbox.x), (0 - it.bbox.y), false );
      it.draw_item( ctx );
      icon = new Image.from_surface( src );
    }
  }

  /* Saves this item as XML format */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "custom-item" );
    node->set_prop( "name", name );
    node->add_child( item.save() );
    return( node );
  }

  /* Loads this item from XML format */
  public void load( Xml.Node* node, CanvasItems canvas_items ) {
    var n = node->get_prop( "name" );
    if( n != null ) {
      name = n;
    }
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "item") ) {
        item = canvas_items.load_item( it );
        create_icon();
      }
    }
  }

}

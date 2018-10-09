public with sharing virtual class ComponentControllerBase {
  public PageControllerBase thePageController { get;
    set {
      if (value != null) {
	    thePageController = value;
	    thePageController.setComponentController(this);
      }
    }
  }
}
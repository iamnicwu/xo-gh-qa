({
  /**
   * Handler for showing modal
   */
  showModal: function(component, event, helper) {
    helper.init(component, event);
  },

  /**
   * Handler for hiding modal
   */
  hideModal: function(component, event, helper) {
    //Toggle CSS styles for hiding Modal
    helper.toggleClassInverse(component, 'backdrop', 'slds-backdrop--');
    helper.toggleClassInverse(component, 'modaldialog', 'slds-fade-in-');
  },

  /**
   * Handler for searching for new items
   */
  searchValueChanged: function(component, event, helper) {
    helper.search(component);
  },

  /**
   * Handler for selecting an item
   */
  selectedItem: function(component, event, helper) {
    var selectedItem = event.currentTarget,
      recId = selectedItem.dataset.recordid;

    component.set('v.selectedItemId', recId);
  },

  /**
   * Handler for updating the correct value in the calling component
   */
  updateValue: function(component, event, helper) {
    helper.setValueInParent(component);
    // Hide modal
    helper.toggleClassInverse(component, 'backdrop', 'slds-backdrop--');
    helper.toggleClassInverse(component, 'modaldialog', 'slds-fade-in-');
  }
})
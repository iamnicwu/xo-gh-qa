({
  /**
   * Used to initalize the component.
   *
   * @param component - The CaseCase component.
   * @param event - The event that fired.
   */
  init: function(component, event) {
    const params = event.getParams();
    let action;
    component.set('v.title', params.title);
    component.set('v.objectType', params.objectType);
    component.set('v.searchValue', '');
    component.set('v.searchResults', []);
    component.set('v.accountId', params.accountId);

    //Toggle CSS styles for opening Modal
    this.toggleClass(component, 'backdrop', 'slds-backdrop--');
    this.toggleClass(component, 'modaldialog', 'slds-fade-in-');

    if (params.objectType === 'Account') {
      action = component.get('c.initialSearchAccounts');
      action.setParams({
        searchVal: params.accountId
      });
    } else if (params.objectType === 'Contact') {
      action = component.get('c.initialSearchContacts');
      action.setParams({
        searchVal: params.accountId
      });
    } else if (params.objectType === 'Task') {
      action = component.get('c.initialSearchTasks');
      action.setParams({
        searchVal: params.accountId
      });
    } else if (params.objectType === 'User') {
      action = component.get('c.initialSearchUsers');
      action.setParams({
        searchVal: params.accountId
      });
    }

    if (!action) {
      console.log('Not valid objectType provided for initialSearch');
      return;
    }

    component.set('v.searching', true);

    action.setCallback(this, function(response){
      const state = response.getState();

      if (state === 'SUCCESS') {
        component.set('v.searchResults', response.getReturnValue());
      } else {
        console.log('Error search', response.getError());
        component.set('v.searchResults', []);
      }

      component.set('v.searching', false);
      component.set('v.selectedItemId', '');
    });

    $A.enqueueAction(action);
  },

  /**
   * Toggle class
   *
   * @param component - The modal component.
   * @param componentId - The component id.
   * @param className - The class name to add or remove.
   */
  toggleClass: function(component, componentId, className) {
    var modal = component.find(componentId);
    $A.util.removeClass(modal, className + 'hide');
    $A.util.addClass(modal, className + 'open');
  },

  /**
   * Toggle class inverse
   *
   * @param component - The modal component.
   * @param componentId - The component id.
   * @param className - The class name to add or remove.
   */
  toggleClassInverse: function(component, componentId, className) {
    var modal = component.find(componentId);
    $A.util.addClass(modal, className + 'hide');
    $A.util.removeClass(modal, className + 'open');
  },

  /**
   * Function to emit event to set value in parent
   *
   * @param component - The modal component.
   */
  setValueInParent: function(component) {
    var searchResults = component.get('v.searchResults'),
      selectedItemId = component.get('v.selectedItemId'),
      objectType = component.get('v.objectType'),
      item = searchResults.find(function(result) {
        return result.id === selectedItemId;
      });

    if (item) {
      $A.get('e.c:setModalValue')
        .setParams({
          item: item,
          objectType: objectType
        })
        .fire();
    }
  },

  /**
   * Send request to search for values
   *
   * @param component - The modal component.
   */
  search: function(component) {
    var currentTimeout = component.get('v.currentTimeout'),
      accountId = component.get('v.accountId'),
      searchVal = component.get('v.searchValue'),
      objectType = component.get('v.objectType'),
      action;

    if (currentTimeout) {
      clearTimeout(currentTimeout);
      component.set('v.currentTimeout', null);
    }

    if (objectType === 'Account') {
      action = component.get('c.searchAccounts');
      action.setParams({
        searchVal: searchVal
      });
    } else if (objectType === 'Contact') {
      action = component.get('c.searchContacts');
      action.setParams({
        searchVal: searchVal,
        accountId: accountId
      });
    } else if (objectType === 'Task') {
      action = component.get('c.searchTasks');
      action.setParams({
        searchVal: searchVal,
        accountId: accountId
      });
    } else if (objectType === 'User') {
      action = component.get('c.searchUsers');
      action.setParams({
        searchVal: searchVal
      });
    }

    if (!action) {
      console.log('Not valid objectType provided for search');
      component.set('v.currentTimeout', null);
      return;
    }

    component.set('v.searching', true);

    // Need $A.getCallback to wrap any code that accesses a component outside the normal
    // rerendering lifecycle, such as in a setTimeout() call
    currentTimeout = setTimeout($A.getCallback(function() {
      action.setCallback(this, function(response){
        var state = response.getState();

        if (state === 'SUCCESS') {
          component.set('v.searchResults', response.getReturnValue());
        } else {
          console.log('Error search', response.getError());
          component.set('v.searchResults', []);
        }

        component.set('v.searching', false);
        component.set('v.currentTimeout', null);
        component.set('v.selectedItemId', '');
      });

      $A.enqueueAction(action);
    }), 700);

    component.set('v.currentTimeout', currentTimeout);
  }
})
({
  /**
   * Handler for the initialization event.
   */
  doInit: function(component, event, helper) {
    helper.init(component);
  },

  /**
   * Handler for the changeOwner event.
   */
  changeOwner: function(component, event, helper) {
    var currentCase = component.get('v.currentCase');

    $A.get('e.c:openChangeModal')
      .setParams({
        title: 'Change Case Owner',
        objectType: 'User',
        accountId: currentCase.accountId
      })
      .fire();
  },

  /**
   * Handler for the changeContact event.
   */
  changeContact: function(component, event, helper) {
    var currentCase = component.get('v.currentCase');

    $A.get('e.c:openChangeModal')
      .setParams({
        title: 'Change Case Contact',
        objectType: 'Contact',
        accountId: currentCase.accountId
      })
      .fire();
  },

  /**
   * Handler for the changeAccount event.
   */
  changeAccount: function(component, event, helper) {
    var currentCase = component.get('v.currentCase');

    $A.get('e.c:openChangeModal')
      .setParams({
        title: 'Change Case Account',
        objectType: 'Account',
        accountId: currentCase.accountId
      })
      .fire();
  },

  /**
   * Handler for the changeActivity event.
   */
  changeTask: function(component, event, helper) {
    var currentCase = component.get('v.currentCase');

    $A.get('e.c:openChangeModal')
      .setParams({
        title: 'Select a Task or Email',
        objectType: 'Task',
        accountId: currentCase.accountId
      })
      .fire();
  },

  /**
   * Handler to set value from change modal.
   */
  setValueFromModal: function(component, event, helper) {
    helper.setValueFromModal(component, event);
  },

  /**
   * Handler for the cancel event.
   */
  cancel: function(component, event, helper) {
    helper.navigateToAccount(component);
  },

  /**
   * Handler for the saveExit event.
   */
  saveExit: function(component, event, helper) {
    var goNext = false;
    helper.saveCase(component, goNext);
  },

  /**
   * Handler for the callContact event.
   */
  callContact: function(component, event, helper) {

  },

  /**
   * Handler for the closing case and submitting cancel opp.
   */
  closeCaseSubmitOpp: function(component, event, helper) {
    helper.saveCase(component, true, true);
  },

  /**
   * Handler for handling file change.
   */
  handleFileChange: function(component, event, helper) {
    helper.handleFileChange(component, event);
  },

  /**
   * Handler for removing a file from the list.
   */
  removeFile: function(component, event, helper) {
    helper.removeFile(component, event);
  },

  /**
   * Handler for determining if the saved by select is disabled.
   */
  outcomeChanged: function(component, event, helper) {
    helper.savedByDisabled(component);
    helper.toggleUploadInput(component);
  },

  /**
   * Handler for going to previous page.
   */
  previous: function(component, event, helper) {
    helper.previous(component);
  },

  /**
   * Handler for going to next page.
   */
  next: function(component, event, helper) {
    var goNext = true;
    helper.saveCase(component, goNext);
  },

  /**
   * Handler for the FeatureRequestCanceledEvent.
   */
  handleFRCEvent: function(component, event, helper) {
    var success = event.getParam('success'),
      location = event.getParam('location');

    component.set('v.saving', false);
    if (success) {
      if (location === 'account') {
        helper.navigateToAccount(component);
      } else {
        helper.next(component);
      }
    }
  },

  /**
   * Utility function for checking submit status of next button.
   */
  checkNextButton: function(component, event, helper) {
    var currentCase = component.get('v.currentCase'),
      currentPage = component.get('v.currentPage'),
      nextDisabled, files;
    if (currentPage === 1) {
      nextDisabled = !currentCase || !currentCase.initialContact || !currentCase.originalRequestDate;
      component.set('v.nextDisabledPageOne', nextDisabled);
    } else if (currentPage === 3) {
      nextDisabled = !currentCase || !currentCase.type || !currentCase.reason || !currentCase.outcome;
      if (!nextDisabled) {
        if (currentCase.outcome === 'Cancelled') {
          // For page three with canceled outcome we either need a previously uploaded attachment, or a local uploaded file
          files = component.get('v.files');
          if (!files || files.length === 0 ) {
            nextDisabled = (!currentCase.attachments || currentCase.attachments.length === 0);
          }
        } else {
          nextDisabled = !currentCase.savedBy;
        }
        helper.savedByDisabled(component);
        helper.toggleUploadInput(component);
      }
      component.set('v.nextDisabledPageThree', nextDisabled);
    }
  }
})
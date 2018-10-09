({
  /**
   * Initalization function.
   */
  doInit: function (component, event, helper) {
    var caseId = component.get('v.caseId');
    if (caseId) {
      helper.getFRCs(component, caseId);
    }
  },

  /**
   * Check or uncheck all checkboxes.
   */
  updateAll: function (component, event, helper) {
    var value = event.getSource().get('v.value'),
      checkboxes = component.find('frcCheckbox'),
      FRCs = component.get('v.FRCs');

    FRCs.forEach(function (record) {
      record.isAdded = value;
    });
    component.set('v.FRCs', FRCs);

    // Update the UI components.
    // If there is only a single checkbox it will not be an array.
    if (!Array.isArray(checkboxes)) {
      checkboxes.set('v.value', value);
    } else {
      checkboxes.forEach(function (cb) {
        cb.set('v.value', value);
      });
    }
  },


  /**
   * Update an FCR isAdded value.
   */
  updateSelected: function (component, event, helper) {
    var indexOfCheckbox = event.getSource().get('v.name'),
      value = event.getSource().get('v.value'),
      FRCs = component.get('v.FRCs');

    FRCs[indexOfCheckbox].isAdded = value;
  },

  /**
   * Persist the FRC values and fire event for next.
   */
  persistFRCsNext: function(component, event, helper) {
    var submitting = component.get('v.submitAndNext');
    if (submitting) {
      helper.persistFRCs(component, 'next');
    }
  },

  /**
   * Persist the FRC values and fire event for account.
   */
  persistFRCsAccount: function(component, event, helper) {
    var submitting = component.get('v.submitAndAccount');
    if (submitting) {
      helper.persistFRCs(component, 'account');
    }
  }

})
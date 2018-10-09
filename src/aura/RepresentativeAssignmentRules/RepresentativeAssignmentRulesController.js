({
	doInit : function(component, event, helper) {
    var action = component.get('c.getPicklistValue');

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not try to execute setup code
      if(state !== 'SUCCESS' || returnValue === null) {
        return;
      }

      component.set('v.marketOptions', returnValue.Market);
      component.set('v.categoryOptions', returnValue.Category);
    });

    $A.enqueueAction(action);

    // Close auto search results when click on a non-result element - Potentially violating Lightning javascript security
    // principles by reaching out for the HTML node. No way to hook the HTML node in a component?
    document.querySelector('html').addEventListener('click', function(event) {
      var clickTarget = event.target;
      if(clickTarget.className.indexOf('result') > -1) {
        event.stopPropagation();
        return;
      }

      var searchResults = document.querySelector('.search-input-results');
      searchResults.style.display = 'none';
    });
	},
  inputSearch : function(component, event, helper) {
    var timer = component.get('v.timer');
    clearTimeout(timer);
    if(event.target.className.indexOf(' search') > -1) {
      helper.switchInputSearchState(event.target);
    }

    // Reset selectedid on keyup
    event.target.dataset.selectedid = '';
    
    timer = setTimeout(
      $A.getCallback(function() {
        helper.repQuery(event.target, component);
      }), 1000);

    component.set('v.timer', timer);
  },
  searchRules : function(component, event, helper) {
    helper.initiateRuleSearch(component);
    helper.showButtonSpinner();
  },
  selectSearchResult : function(component, event, helper) {
    if(event.target.className.indexOf('result') < 0) {
      return;
    }

    helper.setRepresentative(event.target, component);
  },
  sortAssignmentRules : function(component, event, helper) {
    var headerElement = event.target;
    if(headerElement.tagName.toLowerCase() !== 'th') {
      headerElement = helper.findAncestorByType(headerElement, 'th');
    }

    helper.beginSort(headerElement, headerElement.dataset.fieldName, component);
  },
  switchFilter : function(component, event, helper) {
    helper.setFilterView(event.target, component);
  },
  editRule : function(component, event, helper) {
    helper.createEditElements(event.target, component);
    helper.switchRuleLineActions(event.target, component, true);
  },
  createRule : function(component, event, helper) {
    if(helper.determineCreateEligibility(component)) {
      helper.prepareAndSaveRule(event.target, component);
      helper.showButtonSpinner();
    }
  },
  updateRule : function(component, event, helper) {
    helper.displayEditSpinner(event.target);
    helper.prepareAndSaveRule(event.target, component);
  },
  cancelRuleEdit : function(component, event, helper) {
    helper.switchRuleLineActions(event.target, component, false);
  },
  closeError : function(component, event, helper) {
    helper.hideError(component);
  },
  checkAll : function(component, event, helper) {
    var checkboxElements = document.querySelectorAll('td .input-checkbox');

    // Set all checkbox elements in the table to resemble that of the header checkbox
    for(var i = 0; i < checkboxElements.length; i++) {
      var currentCheckbox = checkboxElements[i];
      currentCheckbox.checked = event.target.checked;
    }

    helper.determineMassAssign();
  },
  checkboxChange : function(component, event, helper) {
    helper.determineMassAssign();
  },
  massAssignSwitch : function(component, event, helper) {
    helper.displayMassAssignmentBlock();
  },
  cancelAssign : function(component, event, helper) {
    helper.displayFilterGridBlock();
  },
  beginMassAssign : function(component, event, helper) {
    helper.massAssignOwner(component);
  }
})
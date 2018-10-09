({
	doInit : function(component, event, helper) {
    
    helper.retrieveSupportRoleMap(component);

    var action = component.get('c.getUsers');

    var whereClause = ' IsActive = true';

    action.setParams({
      'whereClauseList' : whereClause
    });

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {
        this.displayError(response.error, cmp);
        return;
      }

      component.set('v.userList', returnValue);
    });

    $A.enqueueAction(action);
	},
  filterByColumn : function(component, event, helper) {
    var columnSelect = document.getElementById('column-filter-select');
    var inputElement = event.target;
    if(inputElement.tagName !== 'INPUT') {
      inputElement = document.querySelector('.user-search input');
    }
    
    helper.filterTable(component, inputElement, columnSelect.options[columnSelect.selectedIndex].value);
  },
  editSupport : function(component, event, helper) {
    helper.switchRowState(event.target, 'edit');
    helper.generateSupportEdit(event.target, component);
  },
  updateSupport : function(component, event, helper) {
    helper.generateSaveSupportEdit(event.target, component);
  },
  cancelSupportEdit : function(component, event, helper) {
    helper.switchRowState(event.target, 'cancel');
  },
  closeError : function(component, event, helper) {
    helper.hideError(component);
  },
  searchState : function(component, event, helper) {
    var searchButton = event.target;
    var parentElement = searchButton.parentElement;
    var otherButton;
    if(searchButton.className.indexOf('search-icon') > -1) {
      otherButton = parentElement.querySelector('.close-icon');
    } else {
      otherButton = parentElement.querySelector('.search-icon');
    }

    
    var searchInput = parentElement.querySelector('input');
    var selectContainer = parentElement.querySelector('.slds-select_container');

    if(typeof searchInput === 'undefined' || typeof selectContainer === 'undefined') {
      return;
    }

    searchButton.style.display = 'none';
    otherButton.style.display = 'inline-block';

    if(searchInput.className.indexOf('hidden') > -1) {
      searchInput.className = searchInput.className.replace('hidden', 'shown animated slideInRight');
      selectContainer.className = selectContainer.className.replace('slideOutLeft', 'slideInLeft');
      if(searchInput.className.indexOf('animated')) {
        searchInput.className = searchInput.className.replace('animated slideOutRight', '');
      }
      searchInput.style.visibility = 'visible';
      selectContainer.style.visibility = 'visible';
      setTimeout(function() {
        searchInput.focus();
      }, 1000);
      return;
    }

    searchInput.className = searchInput.className.replace('shown animated slideInRight', 'hidden animated slideOutRight');
    selectContainer.className = selectContainer.className.replace('slideInLeft', 'slideOutLeft');

    setTimeout(function() {
      searchInput.style.visibility = 'hidden';
      searchInput.value = '';
      selectContainer.style.visibility = 'hidden';
      helper.filterTable(component, searchInput.value, 0);
    }, 1000);
  }
})
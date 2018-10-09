({
  doInit : function(component, event, helper) {
    // INIT FILTERS
    helper.retrieveObjectFilters('Lead', component, true);
    // Close auto search results when click on a non-result element - Potentially violating Lightning javascript security
    // principles by reaching out for the HTML node. No way to hook the HTML node in a component?
    document.querySelector('html').addEventListener('click', function(event) {
      var clickTarget = event.target;
      if(clickTarget.className.indexOf('result') > -1) {
        event.stopPropagation();
        return;
      }

      var userResults = document.querySelector('.user-input-results');
      userResults.style.display = 'none';
      var searchResults = document.querySelector('.search-input-results');
      searchResults.style.display = 'none';
    });
  },
  objectSelection : function(component, event, helper) {
    component.set('v.resultSize', null);

    helper.hideFilterInputs(component);
    helper.resetSelectedFilterValue(component);
    helper.resetFilters(component);
    helper.retrieveObjectFilters(event.target.value, component, false);
    helper.resetObjectResultTable(component);
    helper.determineAssignState(component);
    helper.resetSearchButton(component);
  },
  filterSelection : function(component, event, helper) {
    var eventTarget = event.target;
    helper.createFilter(eventTarget.options[eventTarget.selectedIndex], component);
  },
  inputSearch : function(component, event, helper) {
    var timer = component.get('v.timer');
    clearTimeout(timer);
    if(event.target.className.indexOf(' search') > -1) {
      helper.switchInputSearchState(event.target);
    }
    
    timer = setTimeout(
      $A.getCallback(function() {
        helper.initiateInputQuery(event.target, component);
      }), 1000);

    component.set('v.timer', timer);
  },
  userInputSearch : function(component, event, helper) {
    var timer = component.get('v.userTimer');
    clearTimeout(timer);
    if(event.target.className.indexOf(' search') > -1) {
      helper.switchInputSearchState(event.target);
    }

    timer = setTimeout(
      $A.getCallback(function() {
        helper.initiateUserQuery(event.target, component);
      }), 500);

    component.set('v.userTimer', timer);
  },
  userSelected : function(component, event, helper) {
    var target = event.target;
    if(target.className.indexOf('no-result') > -1) {
      return;
    }

    helper.retrieveUserInformation(target, component);
  },
  resetUser : function(component, event, helper) {
    helper.resetUserSelection(component);
  },
  addInputSearchFilter : function(component, event, helper) {
    var inputId = [];
    var textValue = [];

    if(event.target.innerHTML == 'No results found.'){
      return;
    }

    inputId.push(event.target.id);
    textValue.push(event.target.innerHTML);
    
    var filterValue = component.get('v.selectedFilterValue');
    var filterSelect = document.getElementById('filter-select');

    helper.spawnFilter(inputId, textValue, filterValue, 'textSearch', filterSelect.options[filterSelect.selectedIndex].text);
    helper.enableSearchButton(component);

    var parentNode = event.target.parentNode;
    parentNode.removeChild(event.target);

    if(parentNode.firstChild !== null) {
      return;
    }

    parentNode.style.display = 'none';
  },
  addFilter : function(component, event, helper) {
    var activeInput = document.querySelector('.filterArea .active');
    if(activeInput === null) {
      return;
    }

    while('INPUT, SELECT'.indexOf(activeInput.nodeName) < 0) {
      activeInput = activeInput.firstChild;
    }

    helper.removeErrorOnInput(activeInput);
    if(activeInput.value === null || activeInput.value === '') {
      helper.addErrorToInput(activeInput);
      return;
    }

    var filterSelect = document.getElementById('filter-select');

    var textValues = [];
    var inputValues = [];
    if(activeInput.nodeName == 'SELECT') {
      for(var i = 0; i < activeInput.options.length; i++) {
        if(!activeInput.options[i].selected) {
          continue;
        }
        var currentOption = activeInput.options[i];

        textValues.push(currentOption.text);
        inputValues.push(currentOption.value);
        // Remove selected child and decrement counter
        currentOption.parentNode.removeChild(currentOption);
        i--;
      }
    } else {
      console.log(activeInput);
      textValues.push(activeInput.value);
      inputValues.push(activeInput.value);
    }

    var filterValue = component.get('v.selectedFilterValue');

    helper.spawnFilter(inputValues, textValues, filterValue, filterSelect.options[filterSelect.selectedIndex].getAttribute('data-filtertype'), filterSelect.options[filterSelect.selectedIndex].text);

    activeInput.value = '';

    helper.enableSearchButton(component);
  },
  removeFilter : function(component, event, helper) {
    var target = event.target;
    if(target.className.indexOf('remove-filter-button') < 0) {
      return;
    }

    var parentPill = helper.findAncestorByClassName(target, 'pill-element');
    var groupingParent = helper.findAncestorByClassName(parentPill, 'filter-grouping');
    parentPill.parentNode.removeChild(parentPill);

    var groupingPills = groupingParent.querySelectorAll('.slds-pill');
    if(groupingPills.length < 1) {
      groupingParent.parentNode.removeChild(groupingParent);
    }

    var currentFilters = document.getElementsByClassName('slds-pill');
    if(currentFilters.length > 0) {
      return;
    }

    helper.resetSearchButton(component);
  }, 
  initiateSearch : function(component, event, helper) {
    helper.prepareAndSearch(component);
  },
  tableAction : function(component, event, helper) {
    if(event.target.nodeName === 'TH') {
      helper.sortTable(event.target, component);
    } else if(event.target.nodeName === 'INPUT') {
      if(event.target.id === 'check-all') {
        helper.checkAll(event.target, component);
        return;
      }
      
      helper.singleSelect(event.target, component);
    }
  },
  assignClick : function(component, event, helper) {
    helper.assignRecords(event.target, component, helper);
  },
  closeError : function(component, event, helper) {
    helper.hideError(component);
  }
})
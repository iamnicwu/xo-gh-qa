({
  repQuery : function(element, cmp) {
    var inputValue = element.value;

    var parentContainer = this.findAncestorByType(element, 'div');

    // Get DOM result area to append new child results
    var resultArea = parentContainer.querySelector('.search-input-results');

    if(inputValue === '' || inputValue === null) {
      // Remove all current search results
      this.removeChildNodes(resultArea);
      // Hide result area
      resultArea.style.display = 'none';

      // Switch search state
      this.switchInputSearchState(element);
      return;
    }

    var action = cmp.get('c.queryUsers');

    action.setParams({
      'inputValue': inputValue
    });

    action.setCallback(this, function(response) {
      this.switchInputSearchState(element);
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {
        this.displayError(response.error, cmp);
        return;
      }

      // Show the result area
      resultArea.style.display = '';

      // Remove all current search results
      this.removeChildNodes(resultArea);

      var resultLength = returnValue.length;
      if(resultLength < 1) {
        var noResults = document.createElement('div');
        noResults.className = 'no-result animated fadeInDown';
        noResults.innerHTML = 'No results found.';
        noResults.id = 'invalid';

        resultArea.appendChild(noResults);
        return;
      }

      for(var i = 0; i < resultLength; i++) {
        var currentResult = returnValue[i];

        var newResult = document.createElement('div');
        newResult.className = 'result animated fadeInDown';
        newResult.innerHTML = currentResult.Name;
        newResult.id = currentResult.Id;

        resultArea.appendChild(newResult);
      }

    });

    $A.enqueueAction(action);
  },
  setRepresentative : function(element, cmp) {
    var parentContainer = this.findAncestorByClassName(element, 'search-result-area');
    var resultArea = this.findAncestorByClassName(element, 'search-input-results');
    resultArea.style.display = 'none';

    var searchInput = parentContainer.querySelector('input.search');
    searchInput.value = element.innerHTML;
    searchInput.dataset.selectedid = element.id;
  },
  initiateRuleSearch : function(cmp) {
    var action = cmp.get('c.queryRules');

    var selectedMarket = document.getElementById('market-select');
    var selectedCategory = document.getElementById('category-select');
    var selectedPostalcode = document.getElementById('zipInput');
    var selectedRep = document.getElementById('searchInput');

    action.setParams({
      'market': selectedMarket.options[selectedMarket.selectedIndex].value,
      'category': selectedCategory.options[selectedCategory.selectedIndex].value,
      'postalCode': selectedPostalcode.value,
      'rep': selectedRep.dataset.selectedid
    });


    action.setCallback(this, function(response) {
      this.hideButtonSpinner();

      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {
        this.displayError(response.error, cmp);
        return;
      }

      var result = returnValue;
      cmp.set('v.tableMessage', 'No results found.');
      cmp.set('v.assignmentRules', result);

      // Upon searching ensure that the header checkbox element is unchecked
      var headerCheckbox = document.querySelector('tr .input-checkbox');
      headerCheckbox.checked = false;

      // Reset mass assign button
      this.setMassAssign(false);
      var massAssignCountElement = document.getElementById('massAssignCount');
      massAssignCountElement.innerText = '0 Assignment Rule(s) Selected';
    });

    $A.enqueueAction(action);
  },
  setFilterView : function(element, cmp) {
    var selectContainer = document.getElementById('market-select-container');
    var zipInput = document.getElementById('zipInput');
    var multiLabel = document.getElementById('multi-option-label');
    var switchLabel = element.nextSibling;
    
    if(element.checked) {
      selectContainer.style.display = 'none';
      var selectElement = document.getElementById('market-select');
      selectElement.options[0].selected = true;
      zipInput.style.display = '';
      multiLabel.innerHTML = switchLabel.dataset.on;
      return;
    }

    selectContainer.style.display = '';
    zipInput.style.display = 'none';
    zipInput.value = '';
    multiLabel.innerHTML = switchLabel.dataset.off;
    
  },
  createEditElements : function(element, cmp) {
    var parentRow = this.findAncestorByType(element, 'tr');

    var marketSelect = document.getElementById('market-select').cloneNode(true);
    var categorySelect = document.getElementById('category-select').cloneNode(true);
    var zipInput = document.getElementById('zipInput').cloneNode(true);
    var repInputArea = document.querySelector('.search-result-area').cloneNode(true);

    var errorArea = repInputArea.querySelector('.slds-form-element__help');
    errorArea.parentNode.removeChild(errorArea);

    marketSelect.className += ' animated fadeIn';
    categorySelect.className += ' animated fadeIn';
    zipInput.className += ' animated fadeIn';
    repInputArea.className += ' animated fadeIn';

    // Reset display to visible
    zipInput.style.display = '';
    zipInput.style.paddingLeft = '12px';
    marketSelect.style.display = '';
    repInputArea.value = '';

    if(typeof parentRow.cells[2].dataset.recordid !== 'undefined' && parentRow.cells[2].dataset.recordid !== '') {
      marketSelect.value = parentRow.cells[2].dataset.recordid;
    } else {
      marketSelect.value = 'none';
    }
    
    parentRow.cells[2].dataset.previousValue = parentRow.cells[2].innerHTML;
    parentRow.cells[2].innerHTML = '';
    parentRow.cells[2].appendChild(marketSelect);

    if(typeof parentRow.cells[3].dataset.recordid !== 'undefined' && parentRow.cells[3].dataset.recordid !== '') {
      categorySelect.value = parentRow.cells[3].dataset.recordid;
    } else {
      categorySelect.value = 'none';
    }

    parentRow.cells[3].dataset.previousValue = parentRow.cells[3].innerHTML;
    parentRow.cells[3].innerHTML = '';
    parentRow.cells[3].appendChild(categorySelect);

    zipInput.value = parentRow.cells[4].innerHTML;
    parentRow.cells[4].dataset.previousValue = parentRow.cells[4].innerHTML;
    parentRow.cells[4].innerHTML = '';
    parentRow.cells[4].appendChild(zipInput);


    parentRow.cells[5].dataset.previousValue = parentRow.cells[5].innerHTML;
    var repInput = repInputArea.querySelector('input');
    repInput.value = parentRow.cells[5].innerHTML.replace(' (Inactive)', '');
    repInput.dataset.selectedid = parentRow.cells[5].dataset.recordid;
    parentRow.cells[5].innerHTML = '';
    parentRow.cells[5].appendChild(repInputArea);
  },
  cancelEdit : function(parentRow, cmp) {
    // Populate previous values back into their respective cells
    for(var i = 2; i < 6; i++) {
      var currentCell = parentRow.cells[i];
      var previousValue = currentCell.dataset.previousValue;
      this.removeChildNodes(currentCell);
      currentCell.innerHTML = previousValue;
    }

    // Remove the save error high lightning if it exists on cancel edit
    if(parentRow.className.indexOf(' save-error') > -1) {
      parentRow.className = parentRow.className.replace(' save-error', '');
    }
  },
  switchRuleLineActions : function(element, cmp, isEditMode) {
    var parentRow = element;
    if(parentRow.tagName.toLowerCase() !== 'tr') {
      parentRow = this.findAncestorByType(parentRow, 'tr');  
    }

    // Action cell is the last cell
    var actionCell = parentRow.cells[parentRow.cells.length - 1];

    var editIcon = actionCell.querySelector('.edit-icon');
    var saveIcon = actionCell.querySelector('.save-icon');
    var cancelIcon = actionCell.querySelector('.cancel-icon');

    if(isEditMode) {
      if(parentRow.className.indexOf('error-row') < 0) {
        parentRow.style.backgroundColor = '#f1f1f1';
        parentRow.style.color = 'black';
      }
      
      editIcon.style.display = 'none';
      saveIcon.style.display = '';
      cancelIcon.style.display = '';

      return;
    }

    // Not edit mode
    this.cancelEdit(parentRow, cmp);
    parentRow.style.backgroundColor = '';
    editIcon.style.display = '';
    saveIcon.style.display = 'none';
    cancelIcon.style.display = 'none';
    
  },
  prepareAndSaveRule : function(element, cmp) {
    var parentRow = this.findAncestorByType(element, 'tr');
    var saveType = 'edit';
    if(typeof parentRow === 'undefined' || parentRow === null) {
      parentRow = this.findAncestorByClassName(element, 'slds-grid');
      saveType = 'create';
    }

    var marketSelect = parentRow.querySelector('#market-select');
    var categorySelect = parentRow.querySelector('#category-select');
    var zipInput = parentRow.querySelector('#zipInput');
    var searchInput = parentRow.querySelector('#searchInput');

    // Create Assignment Rule SObject
    var assignmentRule = {};
    assignmentRule.Id = parentRow.dataset.recordid;
    assignmentRule.Market__c = marketSelect[marketSelect.selectedIndex].value;
    assignmentRule.Category__c = categorySelect[categorySelect.selectedIndex].value;
    assignmentRule.Zip_Code__c = zipInput.value;
    assignmentRule.Sales_Rep__c = searchInput.dataset.selectedid;

    var action = cmp.get('c.saveAssignmentRule');

    action.setParams({
      'saveObject': JSON.stringify(assignmentRule)
    });

    action.setCallback(this, function(response) {
      this.hideButtonSpinner();
      if(saveType === 'edit') {
        this.hideEditSpinner(element);
      }

      var returnValue = response.getReturnValue();
      var state = response.getState();
      
      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null || returnValue !== 'SUCCESS') {
        if(parentRow.className.indexOf(' save-error') < 0) {
          parentRow.className += parentRow.className + ' save-error';  
        }

        if(response.error.length > 0) {
          this.displayError(response.error, cmp);
          return;
        }

        var errorObject = {};
        errorObject.message = returnValue;
        this.displayError([errorObject], cmp);
        return;
      }

      if(saveType === 'edit') {
        this.editSuccess(parentRow, cmp, marketSelect, categorySelect, zipInput, searchInput, assignmentRule);
        return;
      }

      // Create logic
      this.createSuccess(marketSelect, categorySelect, zipInput, searchInput);
    });

    $A.enqueueAction(action);
  },
  editSuccess : function(parentRow, cmp, marketSelect, categorySelect, zipInput, searchInput, assignmentRule) {
    // Market cell
    var marketText = marketSelect.options[marketSelect.selectedIndex].text;
    if(marketText === '-- None --') {
      marketText = '';  
    }

    var nameText = '';

    parentRow.cells[2].innerHTML = marketText;
    parentRow.cells[2].dataset.previousValue = marketText;
    parentRow.cells[2].dataset.recordid = assignmentRule.Market__c;
    if(marketText !== '') {
      nameText += marketText;
    } else if(zipInput.value !== '') {
      nameText += zipInput.value;
    }

    // Category Cell
    var categoryText = categorySelect.options[categorySelect.selectedIndex].text;
    if(categoryText === '-- None --') {
      categoryText = '';
    } else {
      nameText += nameText.length > 0 ? ' - ' + categoryText : categoryText;
    }
    parentRow.cells[3].innerHTML = categoryText;
    parentRow.cells[3].dataset.previousValue = categoryText;
    parentRow.cells[3].dataset.recordid = assignmentRule.Category__c;

    // Zipcode cell
    parentRow.cells[4].innerHTML = zipInput.value;
    parentRow.cells[4].dataset.previousValue = zipInput.value;

    // User cell
    parentRow.cells[5].innerHTML = searchInput.value;
    parentRow.cells[5].dataset.previousValue = searchInput.value;
    parentRow.cells[5].dataset.recordid = assignmentRule.Sales_Rep__c;
    nameText += nameText.length > 0 ? ' - ' + searchInput.value : searchInput.value;

    parentRow.cells[1].innerHTML = nameText;

    if(parentRow.className.indexOf(' save-error') > -1) {
      parentRow.className = parentRow.className.replace(' save-error', '');
    }
    
    this.switchRuleLineActions(parentRow, cmp, false);
  },
  createSuccess : function(marketSelect, categorySelect, zipInput, searchInput) {
    var searchButton = document.getElementById('search-button');
    searchButton.click();

    marketSelect.value = 'none';
    categorySelect.value = 'none';
    zipInput.value = '';
    searchInput.value = '';
    searchInput.dataset.selectedid = '';
  },
  determineCreateEligibility : function(cmp) {
    this.removeTextError();
    var zipInput = document.getElementById('zipInput');
    var marketSelectContainer = document.getElementById('market-select-container');
    var marketSelect = document.getElementById('market-select');
    var categorySelect = document.getElementById('category-select');
    var searchInput = document.getElementById('searchInput');

    var sldsFormElement = this.findAncestorByClassName(searchInput, 'slds-form-element ');
    var errorText = sldsFormElement.querySelector('.slds-form-element__help');

    var eligible = true;
    // Search Input error
    if(searchInput.value === '' || typeof searchInput.dataset.selectedid === 'undefined' || searchInput.dataset.selectedid === '') {
      if(sldsFormElement.className.indexOf(' slds-has-error') < 0) {
        sldsFormElement.className += ' slds-has-error';  
      }
      errorText.innerHTML = 'Invalid or no representative selection.';
      eligible = false;
    }

    var switchFormElement = this.findAncestorByClassName(zipInput, 'slds-form-element ');
    var catFormElement = this.findAncestorByClassName(categorySelect, 'slds-form-element ');
    if(((zipInput.style.display !== 'none' && zipInput.value === '') || (marketSelectContainer.style.display !== 'none' && marketSelect.value === 'none')) && categorySelect.value === 'none') {
      if(switchFormElement.className.indexOf(' slds-has-error') < 0) {
        switchFormElement.className += ' slds-has-error';
      }

      if(catFormElement.className.indexOf(' slds-has-error') < 0) {
        catFormElement.className += ' slds-has-error';
      }
      
      var catFormErrorText = catFormElement.querySelector('.slds-form-element__help');
      catFormErrorText.innerHTML = (zipInput.style.display !== 'none' ? 'Zipcode' : 'Market') + ' or Category must have a value to create a rule.';

      eligible = false;
    }

    return eligible;
  },
  removeTextError : function() {
    var errorElements = document.querySelectorAll('.slds-has-error');
    var errorTextElements = document.querySelectorAll('.slds-form-element__help');

    for(var i = 0; i < errorElements.length; i++) {
      errorElements[i].className = errorElements[i].className.replace(' slds-has-error', '');
    }

    for(var i = 0; i < errorTextElements.length; i++) {
      errorTextElements[i].innerHTML = '';
    }
  },
  switchInputSearchState : function(element) {
    if(element.className.indexOf(' search') > -1) {
      element.className = this.removeClassName(element.className, ' search');
      element.className += ' input-loading';
      return;
    }

    element.className = this.removeClassName(element.className, ' input-loading');
    element.className += ' search';
  },
  beginSort : function(headerElement, fieldName, cmp) {
    var assignmentRules = cmp.get('v.assignmentRules');
    var primaryFieldName, relationFieldName;

    var currentSortedHeader = document.querySelector('.is-sorted');
    if(currentSortedHeader != headerElement && currentSortedHeader !== null) {
      currentSortedHeader.className = currentSortedHeader.className.replace(new RegExp(/(\b is-sorted\b|\b asc\b|\b desc\b)/ig), '');
      currentSortedHeader.dataset.direction = -1;
    }

    var direction = headerElement.dataset.direction * -1;

    // Split relation field name if needed
    if(fieldName.indexOf('__r') > -1) {
      var splitName = fieldName.split('.');
      primaryFieldName = splitName[0];
      relationFieldName = splitName[1];
    } else {
      primaryFieldName = fieldName;
      relationFieldName = '';
    }
    // Begin sort functionality
    assignmentRules.sort(function(a, b) {
      var valueA, valueB;
      if(relationFieldName !== '') {
        if(typeof a[primaryFieldName] !== 'undefined') {
          valueA = a[primaryFieldName][relationFieldName];
        } else {
          valueA = '';
        }

        if(typeof b[primaryFieldName] !== 'undefined') {
          valueB = b[primaryFieldName][relationFieldName];
        } else {
          valueB = '';
        }
      } else {
        valueA = a[primaryFieldName];
        valueB = b[primaryFieldName];
      }

      valueA = valueA.toLowerCase();
      valueB = valueB.toLowerCase();

      if(valueA < valueB) {
        return -1 * direction;
      } else if(valueA > valueB) {
        return 1 * direction;
      }

      return 0;
    });

    headerElement.dataset.direction = direction;
    if(headerElement.className.indexOf(' is-sorted') < 0) {
      headerElement.className += ' is-sorted';
    }

    if(direction > 0) {
      headerElement.className = headerElement.className.replace(' asc', '');
      headerElement.className += ' desc';
    } else {
      headerElement.className = headerElement.className.replace(' desc', '');
      headerElement.className += ' asc';
    }

    cmp.set('v.assignmentRules', assignmentRules);
  },
  showButtonSpinner : function() {
    var buttonSpinner = document.getElementById('button-pending');
    buttonSpinner.style.display = 'inline-block';

    // Hide search area buttons
    this.modifyDisplay('.searchBtn', 'none');
    this.modifyDisplay('.addRuleBtn', 'none');
  },
  hideButtonSpinner : function() {
    var buttonSpinner = document.getElementById('button-pending');
    buttonSpinner.style.display = 'none';

    // Show search area buttons
    this.modifyDisplay('.searchBtn', 'inline-block');
    this.modifyDisplay('.addRuleBtn', 'inline-block');
  },
  displayEditSpinner : function(element) {
    var tdElement = this.findAncestorByType(element, 'td');
    var spinner = tdElement.querySelector('.edit-spinner');
    spinner.style.display = 'inline-block';

    var otherImgs = tdElement.querySelectorAll('img:not(.edit-spinner)');
    for(var i = 0; i < otherImgs.length; i++) {
      otherImgs[i].style.display = 'none';
    }
  },
  hideEditSpinner : function(element) {
    var tdElement = this.findAncestorByType(element, 'td');
    var spinner = tdElement.querySelector('.edit-spinner');
    spinner.style.display = 'none';

    var saveIcon = tdElement.querySelector('.save-icon');
    var cancelIcon = tdElement.querySelector('.cancel-icon');
    saveIcon.style.display = 'inline-block';
    cancelIcon.style.display = 'inline-block';
  },
  modifyDisplay : function(queryString, displayValue) {
    var element = document.querySelector(queryString);
    element.style.display = displayValue;
  },
  displayError : function(error, component) {
    component.set('v.errorMessage', error);
    var notifyContainer = document.querySelector('.slds-notify_container');
    notifyContainer.style.display = '';
  },
  hideError : function(component) {
    var notifyContainer = document.querySelector('.slds-notify_container');
    notifyContainer.className = notifyContainer.className.replace('fadeInDown', 'fadeOutUp');

    setTimeout(
      $A.getCallback(function() {
        component.set('v.errorMessage', null);
        notifyContainer.style.display = 'none';
        notifyContainer.className = notifyContainer.className.replace('fadeOutUp', 'fadeInDown');
      }), 1000);
  },
  determineMassAssign : function() {
    var checkedRows = document.querySelectorAll('td .input-checkbox:checked');
    
    var massAssignCountElement = document.getElementById('massAssignCount');

    massAssignCountElement.innerText = checkedRows.length + ' Assignment Rule(s) Selected';

    if(checkedRows === 'undefined' || checkedRows.length < 2) {
      this.setMassAssign(false);
      return;
    }

    this.setMassAssign(true);
    return;
  },
  setMassAssign : function(isEnabled) {
    var massAssignButton = document.getElementById('massAssignBtn');

    if(!isEnabled) {
      if(massAssignBtn.className.indexOf('disabled') > -1) {
        return;
      }

      massAssignBtn.className += ' disabled';
      massAssignBtn.disabled = true;
      return;
    }

    if(massAssignBtn.className.indexOf('disabled') > -1) {
      massAssignBtn.className = massAssignBtn.className.replace(' disabled', '');
    }

    massAssignBtn.disabled = false;
    return;
  },
  displayMassAssignmentBlock : function() {
    var filterGrid = document.querySelector('.filter-options-grid');
    var massAssignGrid = document.querySelector('.mass-assign-grid');

    // Hide Filter Grid
    filterGrid.style.display = 'none';

    // Show Mass Assign Grid
    massAssignGrid.style.display = 'flex';
  },
  displayFilterGridBlock : function() {
    var filterGrid = document.querySelector('.filter-options-grid');
    var massAssignGrid = document.querySelector('.mass-assign-grid');

    // Hide Mass Assign Grid
    massAssignGrid.style.display = 'none';

    // Show Filter Grid
    filterGrid.style.display = 'flex';
  },
  massAssignOwner : function(cmp) {
    var checkedBoxes = document.querySelectorAll('td .input-checkbox:checked');
    var massAssignInput = document.getElementById('massAssignInput');
    var formElementParent = this.findAncestorByClassName(massAssignInput, 'slds-form-element__control');
    var errorMessageElement = formElementParent.querySelector('.slds-form-element__help');

    if(massAssignInput.value === '' || massAssignInput.dataset.selectedid === 'undefined' || massAssignInput.dataset.selectedid === '') {
      if(formElementParent.className.indexOf('slds-has-error') < 0) {
        formElementParent.className += ' slds-has-error';
      }

      
      errorMessageElement.innerText = 'Invalid or no representative selection.';

      return;
    }

    // Remove error message highlighting class name
    if(formElementParent.className.indexOf('slds-has-error') > -1) {
      formElementParent.className = formElementParent.className.replace(' slds-has-error', '');
    }
    // Ensure that the error message is removed
    errorMessageElement.innerText = '';

    // Create an assignment rule list to send to the server for update
    var assignmentRuleList = [];

    // Loop through all checked rows and build an assignment rule object then add to assignment rule list
    for(var i = 0; i < checkedBoxes.length; i++) {
      
      var parentRow = this.findAncestorByType(checkedBoxes[i], 'tr');

      // Create Assignment Rule SObject
      var assignmentRule = {};
      assignmentRule.sobjectType = 'Local_Sales_Rep_Assignment__c';
      assignmentRule.Id = parentRow.dataset.recordid;
      assignmentRule.Sales_Rep__c = massAssignInput.dataset.selectedid;
      assignmentRuleList.push(assignmentRule);
    }

    // Create action from massSaveAssignmentRules server method
    var action = cmp.get('c.massSaveAssignmentRules');

    action.setParams({
      'assignmentRuleList': assignmentRuleList
    });

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {
        this.displayError(response.error, cmp);
        return;
      }

      // Simulate user click on the cancel button to go back to Filter Options
      var cancelAssignElement = document.getElementById('cancelAssignBtn');
      cancelAssignElement.click();

      // Simulate user click on the search button to research with selected filters
      var searchButtonElement = document.getElementById('search-button');
      searchButtonElement.click();
    });

    $A.enqueueAction(action);
  },
  removeClassName : function(className, classToRemove) {
    if(className.indexOf(classToRemove) < 0) {
      return className;
    }

    return className.replace(classToRemove, '');
  },
  removeChildNodes : function(parentNode) {
    while(parentNode.firstChild) {
      parentNode.removeChild(parentNode.firstChild);
    }
  },
  findAncestorByClassName : function(element, strClass) {
    while((element = element.parentElement) && element.className.indexOf(strClass) < 0);
    return element;
  },
  findAncestorByType : function(element, strType) {
    while((element = element.parentElement) && element.tagName.toLowerCase().indexOf(strType) < 0);
    return element;
  }
})
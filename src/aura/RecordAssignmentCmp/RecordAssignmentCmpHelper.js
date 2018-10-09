({
  retrieveObjectFilters : function(objectName, component, firstPageLoad) {
    component.set('v.selectedObject', objectName);
    var action = component.get('c.getObjectFilters');

    action.setParams({
      'objectName' : objectName,
      'firstPageLoad' : firstPageLoad
    });
 
    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not try to execute setup code
      if(state !== 'SUCCESS' || returnValue === null) {

        this.displayError(response.error, component);
        return;
      }

      var filterList = returnValue;

      var filterSelect = document.getElementById('filter-select');
      this.removeChildNodes(filterSelect);

      var defaultOption = document.createElement('option');
      defaultOption.value = 'none';
      defaultOption.text = 'Choose a ' + objectName + ' filter..';
      filterSelect.appendChild(defaultOption);

      // Create additonal filter object
      var additionalFilterObject = {};
      for(var i = 0, len = filterList.length; i < len; i++) {
        var currentFilter = filterList[i];
        var selectOption = document.createElement('option');
        selectOption.value = currentFilter.objectFilter;
        selectOption.text = currentFilter.value;
        selectOption.setAttribute('data-filterType', currentFilter.filterType);
        if(typeof currentFilter.additionalFilterOptions !== 'undefined' && currentFilter.additionalFilterOptions !== null) {
          // Add the additional filter option map to an object which ties it to the field it belongs to
          additionalFilterObject[currentFilter.objectFilter] = currentFilter.additionalFilterOptions;
        }

        filterSelect.appendChild(selectOption);
      }

      component.set('v.additionalFilters', additionalFilterObject);
    });

    // Enqueue action to run
    $A.enqueueAction(action);
  },
  createFilter : function(selectedOption, component) {
    if(typeof selectedOption.dataset.filtertype === 'undefined' || selectedOption.dataset.filtertype === null) {
      console.log('DANGER WILL ROBINSON');
      return;
    }

    var filterArea = document.querySelector('.filterArea');
    var filterLabel = filterArea.querySelector('.filter-label');
    var filterInputArea = filterArea.querySelector('.filter-input-area');
    var filterButton = filterArea.querySelector('.add-filter');

    var activeInput = filterArea.querySelector('.active');
    if(activeInput !== null && activeInput.className.indexOf(' active') > -1) {
      activeInput.className = activeInput.className.replace(' active', '');
    }

    filterLabel.innerHTML = selectedOption.text;
    filterLabel.style.display = '';
    filterInputArea.style.display = '';

    var inputText = filterInputArea.querySelector('input');
    var selectOptionParent = filterInputArea.querySelector('.slds-select_container');
    var datePickParent = filterInputArea.querySelector('.slds-form-element__control');

    var filterType = selectedOption.dataset.filtertype;
    // Add filter type to the input area for later use
    filterInputArea.setAttribute('data-filterType', filterType);

    component.set('v.selectedFilterValue', selectedOption.value);

    // filterType for lookup field or text field like previous owner in Lead and Account object
    if(filterType === 'textSearch') {
      inputText.style.display = '';
      datePickParent.style.display = 'none';
      inputText.className += ' active';
      if(inputText.className.indexOf(' search') < 0) {
        inputText.className += ' search';
      }
      selectOptionParent.style.display = 'none';
      filterButton.style.display = 'none';
      return;
    } 
    // filterType for String field
    else if(filterType === 'text') {

      inputText.style.display = '';
      inputText.className = this.removeClassName(inputText.className, ' search');
      inputText.className += ' active';
      selectOptionParent.style.display = 'none';
      filterButton.style.display = '';
      datePickParent.style.display = 'none';
      return;
    } 
    // filter Type for picklist or checkbox field type
    else if(filterType === 'picklist' || filterType === 'checkbox') {

      inputText.style.display = 'none';
      datePickParent.style.display = 'none';
      inputText.className = this.removeClassName(inputText.className, ' search');
      selectOptionParent.style.display = '';
      selectOptionParent.className += ' active';
      var selectElement = selectOptionParent.querySelector('select');
      this.removeChildNodes(selectElement);
      filterButton.style.display = '';

      var options = component.get('v.additionalFilters')[selectedOption.value];
      var keySize = 0;
      for(var key in options) {
        // Only check keys which are not part of the default _proto_
        if(!options.hasOwnProperty(key)) {
          continue;
        }

        // Increment the keySize - this is used later to set the size of the select element
        keySize++;
        var newOption = document.createElement('option');
        newOption.value = options[key];
        newOption.text = key;
        selectElement.appendChild(newOption);
      }

      selectElement.size = keySize < 3 ? keySize : 3;
    }
    // CSP-1852 Assignment Tool Data Points added date type for filtering
    else if(filterType === 'datepicker'){

      inputText.style.display = 'none';
      inputText.className = this.removeClassName(inputText.className, ' search');
      selectOptionParent.style.display = 'none';
      datePickParent.style.display = '';
      filterButton.style.display = '';
      console.log(datePickParent.querySelector('.date-range-search'));
      var dPickerInput = datePickParent.querySelector('.date-range-search');
      console.log(dPickerInput);
      dPickerInput.className += ' active';

    }
  },
  initiateInputQuery : function(element, component) {
    var filterInputArea = this.findAncestorByClassName(element, 'filter-input-area');
    var filterType = filterInputArea.getAttribute('data-filterType');
    if(filterType !== 'textSearch') {
      return;
    }

    var objectSelected = component.get('v.selectedObject');
    var filterValue = component.get('v.selectedFilterValue');

    // Text Search Logic
    this.queryInputData(element, component, '.filter-input-area .search-input-results', objectSelected, filterValue, false);
  },
  initiateUserQuery : function(element, component) {
    this.queryInputData(element, component, '.user-input-results', 'User', 'OwnerId', true);
  },
  queryInputData : function(element, component, resultAreaQuery, objectSelected, filterValue, checkUserActive) {
    var inputValue = element.value;
    // Get DOM result area to append new child results
    var resultArea = document.querySelector(resultAreaQuery);

    if(inputValue === '' || inputValue === null) {
      this.switchInputSearchState(element);

      // Remove all current search results
      this.removeChildNodes(resultArea);
      resultArea.style.display = 'none';
      return;
    }

    var action = component.get('c.getInputQueryData');

    // String objectName, String fieldQuery, String queryData
    action.setParams({
      'objectName': objectSelected,
      'fieldQuery': filterValue,
      'queryData': inputValue,
      'checkUserActive' : checkUserActive
    });

    action.setCallback(this, function(response) {
      this.switchInputSearchState(element);

      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {

        this.displayError(response.error, component);
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

    // Enqueue action to run
    $A.enqueueAction(action);
  },

  spawnFilter : function(inputId, textValue, filterValue, filterType, filterLabel) {
    var filterSection = document.querySelector('.filter-section');

    var filterLabelSection = document.querySelector('.' + filterLabel.replace(' ', '_'));

    var pillGroup;
    if(typeof filterLabelSection === 'undefined' || filterLabelSection === null) {
      filterLabelSection = document.createElement('span');
      filterLabelSection.className = 'filter-grouping ' + filterLabel.replace(' ', '_');

      var labelHeader = document.createElement('span');
      labelHeader.className = 'label-header';
      labelHeader.innerHTML = filterLabel;

      filterLabelSection.appendChild(labelHeader);

      pillGroup = document.createElement('span');
      pillGroup.className = 'pill-group';

      filterLabelSection.appendChild(pillGroup);

      filterSection.appendChild(filterLabelSection);
    } else {
      pillGroup = filterLabelSection.querySelector('.pill-group');
    }

    for(var i = 0; i < textValue.length; i++) {
      var pill = document.createElement('span');
      pill.className = 'slds-pill pill-element ' + filterType + ' ' + filterValue;
      pill.setAttribute('data-filter-type', filterType);
      pill.setAttribute('data-filter-value', filterValue);

      var switchContainer = document.createElement('label');
      switchContainer.className = 'slds-checkbox--toggle';

      var checkInput = document.createElement('input');
      checkInput.type = 'checkbox';
      checkInput.checked = true;
      switchContainer.appendChild(checkInput);

      var fauxSpan = document.createElement('span');
      fauxSpan.className = 'slds-checkbox--faux';
      fauxSpan.dataset.checkOn = '+';
      fauxSpan.dataset.checkOff = '-';
      switchContainer.appendChild(fauxSpan);

      pill.appendChild(switchContainer);

      var pillAnchor = document.createElement('a');
      pillAnchor.className = 'slds-pill__label';
      pillAnchor.href = 'javascript:void(0);';
      pillAnchor.id = inputId[i];
      pillAnchor.title = textValue[i];
      pillAnchor.innerHTML = textValue[i];
      pillAnchor.setAttribute('data-filter-value', filterValue);

      var pillButton = document.createElement('button');
      pillButton.className = 'slds-button slds-button--icon slds-pill__remove';

      var buttonImg = document.createElement('img');
      buttonImg.className = 'slds-button__icon remove-filter-button';
      buttonImg.src = '/resource/slds100/assets/icons/utility/close_60.png';
      pillButton.appendChild(buttonImg);

      var assistText = document.createElement('span');
      assistText.className = 'slds-assistive-text';
      assistText.innerHTML = 'Remove';
      pillButton.appendChild(assistText);

      pill.appendChild(pillAnchor);
      pill.appendChild(pillButton);

      pillGroup.appendChild(pill);
    }
  },
  retrieveUserInformation : function(element, component) {
    var userId = element.id;

    var action = component.get('c.getUserInformation');

    action.setParams({
      'userId' : userId
    });

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {

        return;
      }

      var userInputResults = document.querySelector('.user-input');
      userInputResults.style.display = 'none';

      var userInfo = document.querySelector('.userInfoContainer');
      userInfo.style.display = '';

      component.set('v.selectedUser', returnValue);

    });

    $A.enqueueAction(action);
  },
  resetUserSelection : function(component) {
    var userInfo = document.querySelector('.userInfoContainer');
    var userInput = document.querySelector('.user-input');

    userInfo.style.display = 'none';
    userInput.style.display = '';
  },
  prepareAndSearch: function(component) {
    var filterElements = document.getElementsByClassName('slds-pill');
    if(filterElements.length < 1) {
      return;
    }

    var loadingSearch = document.getElementById('search-loading');
    var searchButton = document.getElementById('search-filter');
    loadingSearch.style.display = '';
    searchButton.style.display = 'none';

    // New Object - JSLint prefers {} vs new Object() for Object literals - Explanation here: https://jslinterrors.com/the-object-literal-notation-is-preferrable
    // Using Object.create(null) as we don't need an object literal but instead just a simple key-value pair
    var filterData = Object.create(null);
    for(var i = 0, len = filterElements.length; i < len; i++) {
      var currentFilter = filterElements[i];
      var filterType = currentFilter.getAttribute('data-filter-type');
      var filterValue = currentFilter.getAttribute('data-filter-value');
      var inputCheck = currentFilter.querySelector('input[type="checkbox"]');
      
      // CSP-1852 Assignment Tool Data Points
      // previous Owner field is text field so need to pass the name to query.
      var searchValue;
      if(filterValue == 'PreviousOwner__c'){
        searchValue = currentFilter.querySelector('a').title;
      }
      else{
        searchValue = currentFilter.querySelector('a').id;

      }

      var searchParams = {};
      searchParams.userInput = searchValue;
      searchParams.include = inputCheck.checked;

      if(typeof filterData[filterType] === 'undefined') {
        filterData[filterType] = Object.create(null);
        filterData[filterType][filterValue] = [searchParams];
        continue;
      } else if(typeof filterData[filterType][filterValue] === 'undefined') {
        // Add new filterValue type with a newly created array of search values
        filterData[filterType][filterValue] = [searchParams];
        continue;
      }

      filterData[filterType][filterValue].push(searchParams);

    }

    var action = component.get('c.queryWithFilters');

    console.log('result');
    console.log(filterData);
    action.setParams({
      'filterJSON': JSON.stringify(filterData),
      'objectName': component.get('v.selectedObject')
    });

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {

        loadingSearch.style.display = 'none';
        searchButton.style.display = '';
        component.set('v.errorMessage', response.error);
        component.set('v.resultSize', 0 + ' Result(s)');
        return;
      }

      var fieldResponseArray = returnValue.fields;

      var objectArray = returnValue.values;

      component.set('v.resultSize', objectArray.length + ' Result(s)');

      var tableHeaderRow = document.querySelector('.header-row');
      this.removeChildNodes(tableHeaderRow);
      var tableBody = document.querySelector('.table-body');
      this.removeChildNodes(tableBody);

      var noResults = document.getElementById('no-results-found');
      if(objectArray.length < 1) {
        noResults.style.display = '';
        loadingSearch.style.display = 'none';
        searchButton.style.display = '';
        return;
      }

      noResults.style.display = 'none';

      // Hidden checkbox which will used to clone and create new checkboxes(SLDS-Checkbox)
      var hiddenCheckbox = document.querySelector('.input-checkbox-container');

      this.determineAssignState(component, false);

      // Create select all checkbox
      var checkboxHeader = document.createElement('th');
      checkboxHeader.className = 'checkbox-header';
      checkboxHeader.appendChild(this.cloneCheckbox(hiddenCheckbox, 'check-all', 'check-all'));
      tableHeaderRow.appendChild(checkboxHeader);

      // Create name column(always there)
      var nameHeader = document.createElement('th');
      nameHeader.className = 'slds-truncate slds-is-sortable name-header';
      nameHeader.scope = 'col';
      nameHeader.innerHTML = component.get('v.selectedObject') + ' Name';
      tableHeaderRow.appendChild(nameHeader);



      for(var i = 0; i < fieldResponseArray.length; i++) {
        var currentFieldResponse = fieldResponseArray[i];

        var tableHeader = document.createElement('th');
        tableHeader.className = 'slds-truncate slds-is-sortable';
        tableHeader.scope = 'col';
        tableHeader.innerHTML = currentFieldResponse.displayName;

        tableHeaderRow.appendChild(tableHeader);
      }

      for(var i = 0; i < objectArray.length; i++) {
        var currentObject = objectArray[i];
        var bodyRow = document.createElement('tr');
        bodyRow.className = 'body-row animated fadeIn';

        // Create checkbox for line item
        var checkboxTd = document.createElement('td');
        checkboxTd.appendChild(this.cloneCheckbox(hiddenCheckbox, currentObject.Id, currentObject.Id));
        bodyRow.appendChild(checkboxTd);

        // Create name table data
        var nameTableData = document.createElement('td');
        nameTableData.className = 'slds-truncate name-data';
        nameTableData.setAttribute('data-label', component.get('v.selectedObject') + ' Name');
        var recordAnchor = document.createElement('a');
        recordAnchor.href = '/' + currentObject.Id;
        recordAnchor.target = '_blank';
        recordAnchor.innerHTML = currentObject.Name;
        nameTableData.appendChild(recordAnchor);
        bodyRow.appendChild(nameTableData);

        for(var j = 0; j < fieldResponseArray.length; j++) {
          var currentFieldResponse = fieldResponseArray[j];

          var tableData = nameTableData.cloneNode(false);
          // class="slds-truncate" data-label="{!currentField.displayName}"
          tableData.className = 'slds-truncate';
          tableData.setAttribute('data-label', currentFieldResponse.displayName);
          if(currentFieldResponse.fieldName.indexOf('.') > -1) {
            var splitRelation = currentFieldResponse.fieldName.split('.');
            var baseField = currentObject[splitRelation[0]];
            if(typeof baseField === 'undefined' || baseField === null) {
              tableData.innerHTML = '';
            } else {
              tableData.innerHTML = currentObject[splitRelation[0]][splitRelation[1]];  
            }
          } else {
            tableData.innerHTML = currentObject[currentFieldResponse.fieldName];  
          }
        
          bodyRow.appendChild(tableData);
        }

        tableBody.appendChild(bodyRow);
      }
      
      loadingSearch.style.display = 'none';
      searchButton.style.display = '';
    });

    $A.enqueueAction(action);
  },
  cloneCheckbox : function(checkboxToClone, inputId, spanId) {
    var newCheckbox = checkboxToClone.cloneNode(true);
    newCheckbox.style.display = '';

    var inputElement = newCheckbox.querySelector('.input-checkbox');
    inputElement.id = inputId;
    if(inputElement.id != 'check-all') {
      inputElement.className = ' single-checkbox';
    }

    var spanFaux = newCheckbox.querySelector('.slds-checkbox--faux');
    spanFaux.id = spanId;

    return newCheckbox;
  },
  enableSearchButton : function(component) {
    var searchFilterButton = document.getElementById('search-filter');
    searchFilterButton.disabled = false;
    searchFilterButton.className = searchFilterButton.className.replace(' disabled', '');
  },
  hideFilterInputs : function(component) {
    var filterLabel = document.querySelector('.filter-label');
    var filterInputArea = document.querySelector('.filter-input-area');
    var filterInputElement = filterInputArea.querySelector('.slds-input');
    var filterAddButton = document.querySelector('.add-filter');

    filterInputElement.value = '';

    filterLabel.style.display = 'none';
    filterInputArea.style.display = 'none';
    filterAddButton.style.display = 'none';
  },
  resetSelectedFilterValue : function(component) {
    component.set('v.selectedFilterValue', '');
  },
  resetSearchButton : function(component) {
    var searchFilterButton = document.getElementById('search-filter');
    searchFilterButton.disabled = true;
    if(searchFilterButton.className.indexOf(' disabled') < 0) {
      searchFilterButton.className += ' disabled';  
    }
  },
  resetFilters : function(component) {
    var currentFilters = document.getElementsByClassName('filter-grouping');
    if(currentFilters.length < 1) {
      return;
    }

    // Remove all current filter elements
    while(currentFilters.length > 0) {
      // When removing a filter it also removes it from the array of elements - so next element is always INDEX 0
      var currentFilter = currentFilters[0];
      currentFilter.parentElement.removeChild(currentFilter);
    }
  },
  resetObjectResultTable : function(component) {
    var tableHeaderRow = document.querySelector('.header-row');
    this.removeChildNodes(tableHeaderRow);
    var tableBody = document.querySelector('.table-body');
    this.removeChildNodes(tableBody);
    var noResults = document.getElementById('no-results-found');
    noResults.style.display = 'none';
  },
  checkAll : function(element, component) {
    var checkAll = element.checked;

    var checkboxElements = document.querySelectorAll('.single-checkbox');
    var rowElements = document.querySelectorAll('.body-row');

    for(var i = 0, len = checkboxElements.length; i < len; i++) {
      var currentCheckElement = checkboxElements[i];
      var currentBodyRow = rowElements[i];

      currentBodyRow.className = currentBodyRow.className.replace(new RegExp(/(\b false\b|\b true\b)/ig), '');
      currentBodyRow.className += ' ' + checkAll;

      currentCheckElement.checked = checkAll;
      currentCheckElement.className = currentCheckElement.className.replace(new RegExp(/(\b false\b|\b true\b)/ig), '');
      currentCheckElement.className += ' ' + checkAll;
    }

    this.determineAssignState(component, true);
  },
  singleSelect : function(element, component) {
    var checked = element.checked;
    var parentBodyRow = this.findAncestorByClassName(element, 'body-row');

    element.className = element.className.replace(' ' + !checked, '');
    element.className += ' ' + checked;

    parentBodyRow.className = parentBodyRow.className.replace(' ' + !checked, '');
    parentBodyRow.className += ' ' + checked;

    if(!checked) {
      var checkAllElement = document.getElementById('check-all');
      checkAllElement.checked = checked;  
    }

    this.determineAssignState(component, false);
  },
  determineAssignState : function(component, allChecked) {
    var assignButton = document.getElementById('assign-button');
    var selectedRows = document.querySelectorAll('.record-table input[type="checkbox"]:checked');
    var rowSelectedElement = document.querySelector('.row-selected-text');

    if(selectedRows.length === 0 || selectedRows === null) {
      if(assignButton.className.indexOf(' disabled') < 0) {
        assignButton.className += ' disabled';
        assignButton.disabled = true;
      }

      rowSelectedElement.innerHTML = '';

      return;
    }

    var numSelectedRows = selectedRows.length;
    // Decrement from selectedRows to account for "select all" checkbox
    if(allChecked) {
      numSelectedRows--;
    }

    rowSelectedElement.innerHTML = numSelectedRows + ' Row(s) Selected';

    if(assignButton.className.indexOf(' disabled') > -1) {
      assignButton.className = assignButton.className.replace(' disabled' , '');
      assignButton.disabled = false;
    }
  },
  assignRecords : function(element, component, helper) {
    var assignButton = document.getElementById('assign-button');
    var assignLoading = document.getElementById('assign-loading');
    assignButton.style.display = 'none';
    assignLoading.style.display = '';

    var currentObject = component.get('v.selectedObject');
    var currentSelectedUser = component.get('v.selectedUser');
    var i;

    var selectedCheckboxes = document.querySelectorAll('.single-checkbox.true');
    var objectIds = [];
    for(i = 0, len = selectedCheckboxes.length; i < len; i++) {
      var currentSelection = selectedCheckboxes[i];
      objectIds.push(currentSelection.id);
    }

    var errorIdArray;

    i = 80;
    if(i > objectIds.length) {
      i = objectIds.length;
    }

    this.performUpdate(component, objectIds, i, objectIds.slice(0, i), currentSelectedUser.Id, currentObject, (i === objectIds.length));
  },
  performUpdate : function(cmp, fullObjectIdList, currentIteration, objectIds, currentUserId, currentObjectName, isFinished) {
    
    var action = cmp.get('c.assignOwner');

    action.setParams({
      'sobjectIds': objectIds,
      'newOwnerId': currentUserId,
      'objectName': currentObjectName
    });

    action.setCallback(this, function(response) {

      var currentPercentDone = (currentIteration / fullObjectIdList.length) * 100;
      
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS') {

        assignButton.style.display = '';
        assignLoading.style.display = 'none';
        this.displayError(response.error, component);
        return;
      }

      var i, len, currentRow;

      var errorIdArray = cmp.get('v.errorIdArray');
      if(errorIdArray === null) {
        errorIdArray = [];
      }

      if(returnValue !== null) {

        for(i = 0, len = returnValue.length; i < len; i++) {

          var currentError = returnValue[i];

          errorIdArray.push(currentError.failedObject.Id);
        }
      }

      var progressBar = document.getElementById('progress-bar');
      var progressBarContainer = progressBar.parentElement;
      if(currentPercentDone !== 100) {
        if(progressBarContainer.style.display === 'none') {
          progressBarContainer.style.display = 'block';
        }
        progressBar.style.width = currentPercentDone + '%';
      } else {
        if(progressBarContainer.style.display !== 'none') {
          progressBar.style.width = currentPercentDone + '%';
          setTimeout(
            $A.getCallback(function() {
              progressBarContainer.style.display = 'none';
              progressBar.width = '0%';
            }), 1000);
        }
      }

      cmp.set('v.errorIdArray', errorIdArray);

      if(isFinished) {
        this.processResults(cmp, currentObjectName);
      } else {
        var previousI = currentIteration;
        currentIteration += 80;
        if(currentIteration > fullObjectIdList.length) {
          currentIteration = fullObjectIdList.length;
        }

        var currentPercentDone = (currentIteration / fullObjectIdList.length) * 100;

        this.performUpdate(cmp, fullObjectIdList, currentIteration, fullObjectIdList.slice(previousI, currentIteration), currentUserId, currentObjectName, (currentIteration === fullObjectIdList.length), currentPercentDone);
      }
    });

    $A.enqueueAction(action);
  },
  processResults : function(cmp, currentObjectName) {
    var errorIdArray = cmp.get('v.errorIdArray');

    var successNotification = document.querySelector('.success-container');
    var successMessage = successNotification.querySelector('.slds-text-heading--small');
    var highlightedRows;

    var errorArray = [];
    // Errors Exist - Do special logic
    for(i = 0; i < errorIdArray.length; i++) {
      var currentErrorId = errorIdArray[i];

      var inputElement = document.getElementById(currentErrorId);
      // Uncheck element
      inputElement.click();
      var parentRow = this.findAncestorByClassName(inputElement, 'body-row');
      parentRow.className += ' failure slds-theme--error slds-theme--alert-texture';
      var errorObject = {};
      errorObject.pageErrors = [];
      errorObject.pageErrors[0] = {};
      errorObject.pageErrors[0].id = currentErrorId;
      errorObject.pageErrors[0].statusCode = currentObjectName + ' Assignment Error';
      errorObject.pageErrors[0].message = currentError.errorMessageList[0];

      errorArray.push(errorObject);
    }

    highlightedRows = document.querySelectorAll('.body-row.true');

    successNotification.style.display = 'inline-block';
    successMessage.innerHTML = highlightedRows.length + ' record(s) have been successfully reassigned.';

    for(i = 0, len = highlightedRows.length; i < len; i++) {
      currentRow = highlightedRows[i];
      currentRow.className += ' animated fadeOutRight';
    }

    if(errorArray.length > 0) {
      this.displayError(errorArray, component);  
    }
    

    setTimeout(
        $A.getCallback(function() {
          successNotification.className = successNotification.className.replace('fadeInDown', 'fadeOutUp');
          setTimeout(
            $A.getCallback(function() {
              successNotification.style.display = 'none';
              successNotification.className = successNotification.className.replace('fadeOutUp', 'fadeInDown');
          }),1000);
        }), 2000);

    setTimeout(
      $A.getCallback(function() {
        for(var i = 0, len = highlightedRows.length; i < len; i++) {
          var currentRow = highlightedRows[i];
          currentRow.parentElement.removeChild(currentRow);
        }

        var assignButton = document.getElementById('assign-button');
        var assignLoading = document.getElementById('assign-loading');

        assignButton.style.display = '';
        assignButton.disabled = true;
        assignButton.className += ' disabled';
        assignLoading.style.display = 'none';
      }), 1000);
  },
  displayError : function(error, component) {
    component.set('v.errorMessage', error);
    var notifyContainer = document.querySelector('.error-container');
    notifyContainer.style.display = '';
  },
  hideError : function(component) {
    var notifyContainer = document.querySelector('.error-container');
    notifyContainer.className = notifyContainer.className.replace('fadeInDown', 'fadeOutUp');

    setTimeout(
      $A.getCallback(function() {
        component.set('v.errorMessage', null);
        notifyContainer.style.display = 'none';
        notifyContainer.className = notifyContainer.className.replace('fadeOutUp', 'fadeInDown');
      }), 1000);
  },
  sortTable : function(element, component) {
    var colIndex = event.target.cellIndex;
    if(colIndex < 1) {
      return;
    }

    var currentSortedHeader = document.querySelector('.is-sorted');
    if(element != currentSortedHeader && currentSortedHeader !== null) {
      currentSortedHeader.className = currentSortedHeader.className.replace(new RegExp(/(\b is-sorted\b|\b asc\b|\b desc\b)/ig), '');
      currentSortedHeader.setAttribute('data-direction', -1);
    }

    var direction = element.getAttribute('data-direction');
    if(direction === null) {
      direction = 1;
    } else {
      direction = -1 * direction;
    }

    var tableBody = document.getElementById('result-table-body');

    var rows = tableBody.rows, rlen = rows.length, arr = [], i, j, cells, clen;

    // fill the array with values from the table
    for(i = 0; i < rlen; i++) {
      cells = rows[i].cells;
      clen = cells.length;
      arr[i] = {
        tdArray : [],
        nodeValue : rows[i]
      };
      for(j = 0; j < clen; j++){
        arr[i].tdArray[j] = {
          compareValue : cells[j].innerHTML.toLowerCase(),
          nodeValue : cells[j]
        };
        //arr[i][j] = cells[j].innerHTML;
      }
    }

    // sort the array by the specified column number (colIndex) and order (direction)
    arr.sort(function(a, b){
      var aCompare = a.tdArray[colIndex].compareValue;
      var bCompare = b.tdArray[colIndex].compareValue;
      // Additional logic needed for TD elements with other elements inside - only accounts for one level deep
      if(aCompare.indexOf('</') > -1) {
        aCompare = aCompare.substring(aCompare.indexOf('>') + 1, aCompare.indexOf('</'));
        bCompare = bCompare.substring(bCompare.indexOf('>') + 1, bCompare.indexOf('</'));
      }
      return (aCompare == bCompare) ? 0 : ((aCompare > bCompare) ? direction : -1*direction);
    });

    var newTableBody = document.createElement('tbody');
    for(i = 0; i < rlen; i++){
      newTableBody.appendChild(arr[i].nodeValue);
    }

    // Set the newly sorted table body into the old table body innerHTML
    tableBody.innerHTML = newTableBody.innerHTML;

    // Get all current checked elements
    var checkedElements = document.querySelectorAll('input.true');
    // Used to "recheck" elements which were previously checked after sorting. During reorder with the sort process
    // the checked attribute gets reset
    for(var i = 0, len = checkedElements.length; i < len; i++) {
      checkedElements[i].checked = true;
    }

    element.setAttribute('data-direction', direction);
    if(direction > 0) {
      if(element.className.indexOf('asc') > -1) {
        element.className = element.className.replace(' asc', ' desc');
        return;
      }
      
      element.className += ' is-sorted desc';
    } else {
      element.className = element.className.replace(' desc', ' asc');
    }
  },
  addErrorToInput : function(inputElement) {
    if(inputElement.className.indexOf('error') < 0) {
      inputElement.className += ' error';      
    }
  },
  removeErrorOnInput : function(inputElement) {
    inputElement.className = inputElement.className.replace(' error', '');
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
  switchInputSearchState : function(element) {
    if(element.className.indexOf(' search') > -1) {
      element.className = this.removeClassName(element.className, ' search');
      element.className += ' input-loading';
      return;
    }

    element.className = this.removeClassName(element.className, ' input-loading');
    element.className += ' search';
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
({
  retrieveSupportRoleMap : function(cmp) {
    var action = cmp.get('c.getUserPicklists');

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS' || returnValue === null) {
        this.displayError(response.error, cmp);
        return;
      }
      var i, option;

      var arrSelect = document.querySelector('.arr-select');
      var arrValues = returnValue['ARR'];
      for(i = 0; i < arrValues.length; i++) {
        var currentArr = arrValues[i];
        option = document.createElement('option');
        option.value = currentArr.value;
        option.text = currentArr.label;
        arrSelect.appendChild(option);
      }
 
      var rsdrsrSelect = document.querySelector('.rsr-rsd-select');
      var rsdValues = returnValue['RSD'];
      for(i = 0; i < rsdValues.length; i++) {
        var currentRsd = rsdValues[i];
        option = document.createElement('option');
        option.value = currentRsd.value;
        option.text = currentRsd.label;
        rsdrsrSelect.appendChild(option);
      }

      var sspsSelect = document.querySelector('.ss-ps-select');
      var ssValues = returnValue['Strategy Specialist'];
      for(i = 0; i < ssValues.length; i++) {
        var currentSs = ssValues[i];
        option = document.createElement('option');
        option.value = currentSs.value;
        option.text = currentSs.label;
        sspsSelect.appendChild(option);
      }

      var sorSelect = document.querySelector('.sor-select');
      var sorValues = returnValue['SOR'];
      for(i = 0; i < sorValues.length; i++) {
        var currentSor = sorValues[i];
        option = document.createElement('option');
        option.value = currentSor.value;
        option.text = currentSor.label;
        sorSelect.appendChild(option);
      }

      this.buildColumnSortSelect();
    });

    $A.enqueueAction(action);
  },
  buildColumnSortSelect : function() {
    var roleSelect = document.getElementById('column-filter-select');

    var thElements = document.querySelectorAll('table th');
    for(var i = 0; i < thElements.length; i++) {
      var currentElement = thElements[i];
      if(currentElement.dataset.headerValue === null || typeof currentElement.dataset.headerValue === 'undefined') {
        continue;
      }

      var newOption = document.createElement('option');
      newOption.value = i;
      newOption.text = currentElement.dataset.headerValue;

      roleSelect.appendChild(newOption);
    }
  },
	generateSupportEdit : function(element, cmp) {
    var parentCell = XOjs.findAncestorByType(element, 'td');
    var parentRow = XOjs.findAncestorByType(element, 'tr');

    var headerRow = document.querySelector('.user-table thead tr');
    var columnIndexes = cmp.get('v.columnIndex');

    var arrContainer = document.querySelector('.arr-container');
    var rsrContainer = document.querySelector('.rsr-rsd-container');
    var ssContainer = document.querySelector('.ss-ps-container');
    var sorContainer = document.querySelector('.sor-container');

    var selContainerArray = [null, rsrContainer, arrContainer, rsrContainer, ssContainer, ssContainer, sorContainer];

    for(var i = 0; i < parentRow.cells.length; i++) {
      var currentCell = parentRow.cells[i];
      if(currentCell.dataset.cellDesc === 'none') {
        continue;
      }

      var inputLabel = document.createElement('label');
      inputLabel.className = 'slds-form-element__label';
      inputLabel.for = 'support-search';
      inputLabel.innerHTML = columnIndexes[i];

      var elementControl = document.createElement('div');
      elementControl.className = 'slds-form-element__control';

      var currentSelectCont = selContainerArray[i].cloneNode(true);
      currentSelectCont.style.display = '';

      if(typeof currentCell.dataset.recordid !== 'undefined' && currentCell.dataset.recordid !== '') {
        var selectOption;
        for(var j = 0; j < currentSelectCont.childNodes.length; j++) {
          if(currentSelectCont.childNodes[j].tagName.toLowerCase() === 'select') {
            selectOption = currentSelectCont.childNodes[j];
            break;
          }
        }

        // Only set select option if the user is actually available in the list
        if(typeof selectOption !== 'undefined') {
          selectOption.value = 'none';
          for(var j = 0; j < selectOption.options.length; j++) {
            if(selectOption.options[j].value === currentCell.dataset.recordid) {
              selectOption.value = currentCell.dataset.recordid;
              break;
            }
          }
        }
      }

      elementControl.appendChild(currentSelectCont);

      currentCell.dataset.previousValue = currentCell.innerHTML;
      currentCell.innerHTML = '';
      currentCell.appendChild(inputLabel);
      currentCell.appendChild(elementControl);
    }
	},
  generateSaveSupportEdit: function(element, cmp) {
    var parentRow = XOjs.findAncestorByType(element, 'tr');
    var fieldMap = cmp.get('v.columnFieldMap');

    var userRecord = {};
    userRecord.Id = parentRow.dataset.recordid;

    for(var i = 0; i < parentRow.cells.length; i++) {
      var currentCell = parentRow.cells[i];
      if(typeof currentCell.dataset.cellDesc === 'undefined' || currentCell.dataset.cellDesc === 'none') {
        continue;
      }

      var selectOption = currentCell.querySelector('select');
      if(typeof selectOption === 'undefined' || selectOption === null) {
        continue;
      }

      userRecord[fieldMap[currentCell.dataset.cellDesc]] = selectOption.value !== 'none' ? selectOption.value : null;
    }

    var action = cmp.get('c.updateUser');

    action.setParams({
      'userParam' : userRecord
    });

    action.setCallback(this, function(response) {
      var returnValue = response.getReturnValue();
      var state = response.getState();

      // If the response is not successful do not continue
      if(state !== 'SUCCESS') {
        this.displayError(response.error, cmp);
        return;
      } else if(returnValue.length > 0) {
        var errorArray = [];
        for(var i = 0, len = returnValue.length; i < len; i++) {
          var currentError = returnValue[i];
          var failedRow = document.getElementById(currentError.failedObject.Id);
          failedRow.className += ' failure slds-theme--error slds-theme--alert-texture';
          var errorObject = {};
          errorObject.pageErrors = [];
          errorObject.pageErrors[0] = {};
          errorObject.pageErrors[0].id = currentError.failedObject.Id;
          errorObject.pageErrors[0].statusCode = 'Support Assignment Error';
          errorObject.pageErrors[0].message = currentError.errorMessageList[0];

          errorArray.push(errorObject);
        }

        this.displayError(errorArray, cmp);
        return;
      }

      this.supportSaveSuccess(element, parentRow);
    });
    

    $A.enqueueAction(action);
  },
  supportSaveSuccess : function(element, parentRow) {
    parentRow.style.backgroundColor = 'lightgreen';
    setTimeout(
      $A.getCallback(function() {
        parentRow.style.backgroundColor = '';
      }), 500);

    for(var i = 0; i < parentRow.cells.length; i++) {
      var currentCell = parentRow.cells[i];

      var selectElement = currentCell.querySelector('select');
      if(typeof selectElement === 'undefined' || selectElement === null) {
        continue;
      }

      var selectValue = selectElement.options[selectElement.selectedIndex].value;
      var textValue = selectElement.options[selectElement.selectedIndex].text;
      if(selectValue === 'none') {
        selectValue = '';
        textValue = '';
      }

      currentCell.dataset.recordid = selectValue;
      currentCell.dataset.previousValue = textValue;
      currentCell.innerHTML = textValue;
    }

    this.switchRowState(element, 'save');
  },
  switchRowState : function(element, rowState) {
    var parentCell = XOjs.findAncestorByType(element, 'td');
    var parentRow = XOjs.findAncestorByType(element, 'tr');

    if(rowState === 'edit') {
      this.editMode(parentCell, element);
    } else if(rowState === 'cancel') {
      this.cancelSupportEdit(parentCell, element);
    } else if(rowState === 'save') {
      this.cancelSupportEdit(parentCell, null);
    }
  },
  editMode : function(buttonCell, editButton) {
    var cancelButton = buttonCell.querySelector('.cancel-icon');
    var saveButton = buttonCell.querySelector('.save-icon');

    cancelButton.style.display = 'inline-block';
    saveButton.style.display = 'inline-block';
    
    this.displayDefaultButtons(buttonCell, false);
  },
  cancelSupportEdit : function(buttonCell, cancelButton) {
    var saveButton = buttonCell.querySelector('.save-icon');
    if(cancelButton === null) {
      cancelButton = buttonCell.querySelector('.cancel-icon');
    }

    cancelButton.style.display = 'none';
    saveButton.style.display = 'none';

    this.displayDefaultButtons(buttonCell, true);

    var parentRow = XOjs.findAncestorByType(buttonCell, 'tr');
    if(parentRow.className.indexOf(' failure slds-theme--error slds-theme--alert-texture') > -1) {
      parentRow.className = parentRow.className.replace(' failure slds-theme--error slds-theme--alert-texture', '');
    }

    for(var i = 0; i < parentRow.cells.length; i++) {
      var currentCell = parentRow.cells[i];
      if(currentCell.dataset.cellDesc === 'none') {
        continue;
      }

      if(typeof currentCell.dataset.previousValue !== 'undefined') {
        currentCell.innerHTML = currentCell.dataset.previousValue;
      } else {
        currentCell.innerHTML = '';
      }
      
    }
  },
  displayDefaultButtons : function(buttonCell, showButtons) {
    var defaultButtons = buttonCell.querySelectorAll('.button-default');

    for(var i = 0; i < defaultButtons.length; i++) {
      if(showButtons) {
        defaultButtons[i].style.display = 'inline-block';
        continue;
      }
      
      defaultButtons[i].style.display = 'none';
    }
  },
  switchInputSearchState : function(element) {
    if(element.className.indexOf(' search') > -1) {
      element.className = element.className.replace(' search', '');
      element.className += ' input-loading';
      return;
    }

    element.className = element.className.replace(' input-loading', '');
    element.className += ' search';
  },
  filterTable : function(cmp, inputElement, columnIndex) {
    var tableRows = document.querySelectorAll('.user-table tbody tr');
    var i, currentRow;
    if(inputElement.value === null || inputElement === '') {
      for(i = 0; i < tableRows.length; i++) {
        currentRow = tableRows[i];
        currentRow.style.display = '';
      }

      return;
    }

    var inputValueLower = inputElement.value.toLowerCase();

    for(i = 0; i < tableRows.length; i++) {
      currentRow = tableRows[i];
      var currentCellInnerLower = currentRow.cells[columnIndex].innerHTML.toLowerCase();


      if(currentCellInnerLower.indexOf(inputValueLower) > -1) {
        currentRow.style.display = '';
        continue;
      }

      currentRow.style.display = 'none';
    }
  },
  displayError : function(error, cmp) {
    cmp.set('v.errorMessage', error);
    var notifyContainer = document.querySelector('.slds-notify_container');
    notifyContainer.style.display = '';
  },
  hideError : function(cmp) {
    var notifyContainer = document.querySelector('.slds-notify_container');
    notifyContainer.className = notifyContainer.className.replace('fadeInDown', 'fadeOutUp');

    setTimeout(
      $A.getCallback(function() {
        cmp.set('v.errorMessage', null);
        notifyContainer.style.display = 'none';
        notifyContainer.className = notifyContainer.className.replace('fadeOutUp', 'fadeInDown');
      }), 1000);
  }
})
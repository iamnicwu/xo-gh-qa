({
	getCallbacks : function(component, page) {
		// Create the action
		var action = component.get('c.getCallbacks');

		var ownerSelectElement = document.getElementById('owner-select');
		var ownerFilter;
		// Set owner filter to 'mine' for first load - DOM not loaded yet and as such element does not exist
		if(ownerSelectElement === null || typeof ownerSelectElement === 'undefined') {
			ownerFilter = 'Mine';
		} else {
			ownerFilter = ownerSelectElement.value;
		}		

		var typeSelectElement = document.getElementById('type-select');
		var typeFilter;
		// Set type filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(typeSelectElement === null || typeof typeSelectElement === 'undefined') {
			typeFilter = 'All';
		} else {
			typeFilter = typeSelectElement.value;
		}

		var statusSelectElement = document.getElementById('status-select');
		var statusFilter;
		// Set status filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(statusSelectElement === null || typeof statusSelectElement === 'undefined') {
			statusFilter = 'All Open';
		} else {
			statusFilter = statusSelectElement.value;
		}

		var marketSelectElement = document.getElementById('market-select');
		var marketFilter;
		// Set market filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(marketSelectElement === null || typeof marketSelectElement === 'undefined') {
			marketFilter = 'All';
		} else {
			marketFilter = marketSelectElement.value;
		}

		var categorySelectElement = document.getElementById('category-select');
		var categoryFilter;
		// Set category filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(categorySelectElement === null || typeof categorySelectElement === 'undefined') {
			categoryFilter = 'All';
		} else {
			categoryFilter = categorySelectElement.value;
		}

		var accountVIPStatusSelectElement = document.getElementById('account-vip-status-select');
		var accountVIPStatusFilter;
		// Set Account VIP Status filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(accountVIPStatusSelectElement === null || typeof accountVIPStatusSelectElement === 'undefined') {
			accountVIPStatusFilter = 'All';
		} else {
			accountVIPStatusFilter = accountVIPStatusSelectElement.value;
		}

		var accountNameSearchElement = document.getElementById('account-name-search');
		var accountNameFilter;
		// Set Account Name filter to an empty string for first load - DOM not loaded yet and as such element does not exist
		if(accountNameSearchElement === null || typeof accountNameSearchElement === 'undefined') {
			accountNameFilter = '';
		} else {
			accountNameFilter = accountNameSearchElement.value;
		}

		var subscriptionNumberSearchElement = document.getElementById('subscription-number-search');
		var subscriptionNumberFilter;
		// Set Subscription Number filter to an empty string for first load - DOM not loaded yet and as such element does not exist
		if(subscriptionNumberSearchElement === null || typeof subscriptionNumberSearchElement === 'undefined') {
			subscriptionNumberFilter = '';
		} else {
			subscriptionNumberFilter = subscriptionNumberSearchElement.value;
		}

		var startingDateRangeFilterElement = document.getElementById('callback-date-range-starting-date');
		var startingDateRangeFilter;
		// Set Starting Date Range filter to an empty string for first load - DOM not loaded yet and as such element does not exist
		if(startingDateRangeFilterElement === null || typeof startingDateRangeFilterElement === 'undefined') {
			startingDateRangeFilter = '';
		} else {
			startingDateRangeFilter = startingDateRangeFilterElement.value;
		}

		var endingDateRangeFilterElement = document.getElementById('callback-date-range-ending-date');
		var endingDateRangeFilter;
		// Set Ending Date Range filter to an empty string for first load - DOM not loaded yet and as such element does not exist
		if(endingDateRangeFilterElement === null || typeof endingDateRangeFilterElement === 'undefined') {
			endingDateRangeFilter = '';
		} else {
			endingDateRangeFilter = endingDateRangeFilterElement.value;
		}

		var possibleRenewalSelectElement = document.getElementById('possible-renewal-select');
		var possibleRenewalFilter;
		// Set market filter to 'all' for first load - DOM not loaded yet and as such element does not exist
		if(possibleRenewalSelectElement === null || typeof possibleRenewalSelectElement === 'undefined') {
			possibleRenewalFilter = 'All';
		} else {
			possibleRenewalFilter = possibleRenewalSelectElement.value;
		}		
		
		// get the order statement
		var orderStatement = this.getOrderStatement(component);

		// Set params
		action.setParams({
			'pageNumber': page,
			'ownerFilter' : ownerFilter,
			'typeFilter' : typeFilter,
			'statusFilter' : statusFilter,
			'marketFilter' : marketFilter,
			'categoryFilter' : categoryFilter,
			'accountVIPStatusFilter' : accountVIPStatusFilter,
			'orderStatement' : orderStatement,
			'accountNameFilter' : accountNameFilter,
			'subscriptionNumberFilter' : subscriptionNumberFilter,
			'startingDateRangeFilter' : startingDateRangeFilter,
			'endingDateRangeFilter' : endingDateRangeFilter,
			'possibleRenewalFilter' : possibleRenewalFilter
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var result = response.getReturnValue();
				component.set('v.recordCount', result.recordCount);
				component.set('v.callbacks', result.callbacks);
				var numberOfPages = Math.ceil(result.recordCount/25);
				if (numberOfPages === 0) {
					numberOfPages = 1;
				}
				component.set('v.pages', numberOfPages);
				component.set('v.page', result.page);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	getStatusPicklistValues : function(component) {
		// Create the action
		var action = component.get('c.getStatusPicklistValues');

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var statusPicklistValues = response.getReturnValue();
				component.set('v.statusPicklistValues', statusPicklistValues);
				var statusSelect = document.getElementById('status-select');
				this.populateOptions(statusPicklistValues, statusSelect);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	getMarketPicklistValues : function(component) {
		// Create the action
		var action = component.get('c.getMarketPicklistValues');

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var marketPicklistValues = response.getReturnValue();
				//component.set('v.statusPicklistValues', statusPicklistValues);
				var marketSelect = document.getElementById('market-select');
				this.populateOptions(marketPicklistValues, marketSelect);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	getCategoryPicklistValues : function(component) {
		// Create the action
		var action = component.get('c.getCategoryPicklistValues');

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var categoryPicklistValues = response.getReturnValue();
				//component.set('v.statusPicklistValues', statusPicklistValues);
				var categorySelect = document.getElementById('category-select');
				this.populateOptions(categoryPicklistValues, categorySelect);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	getStrategySpecialistPicklistValues : function(component) {
		// Create the action
		var action = component.get('c.getStrategySpecialistPicklistValues');

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var strategySpecialistPicklistValues = response.getReturnValue();
				//component.set('v.statusPicklistValues', statusPicklistValues);
				var ownerSelect = document.getElementById('owner-select');
				this.populateOptions(strategySpecialistPicklistValues, ownerSelect);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	updateCallbackStatus : function(component, event) {
		// Create the action
		var action = component.get('c.updateCallbackStatus');

		var statusPicklistId = event.target.id;
		var statusValue = event.target.value;
		var callbackRecordId = statusPicklistId.substring(16, statusPicklistId.length);
		var statusSelectElement = document.getElementById('status-select');
		var parentTableRowElement = this.findAncestorByClassName(event.target, 'slds-hint-parent');

		// display the "update notification" table row
		var updateNotificationElement = document.getElementById('update-notification-' + callbackRecordId);
		updateNotificationElement.style.display = 'table-row';

		// display the loading spinner icon
		var loadingSpinnerElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .slds-spinner');
		loadingSpinnerElement[0].style.display = 'block';

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId,
			'callbackStatus' : statusValue
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var callbackUpdateSuccess = response.getReturnValue();

				// hide the spinner icon
				loadingSpinnerElement[0].style.display = 'none';

				var updateSuccessElement;

				if (callbackUpdateSuccess) {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-success');
					console.log('callbackUpdateSuccess!');

					// CSP-1753 | hide the table row
					if (statusSelectElement.value !== 'All' && (statusValue === 'Cancelled' || statusValue === 'Complete')) {
						parentTableRowElement.style.display = 'none';
					}
				}
				else {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-failure');
					console.log('callbackUpdateFailure =(');
				}

				// display the success or failure message
				updateSuccessElement[0].style.display = 'block';
				// update notification row animation
				setTimeout(function() {				
					updateNotificationElement.className = updateNotificationElement.className + ' bounceOut animated';
					setTimeout(function() {
						updateNotificationElement.className = 'update-notification';
						updateNotificationElement.style = 'display: none;';
						updateSuccessElement[0].style.display = 'none';		// TODO: make these consistent			
					}, 700);
				}, 1000);								
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	getOwnerPicklistValues : function(component) {
		// Create the action
		var action = component.get('c.getOwnerPicklistValues');

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var ownerPicklistValues = response.getReturnValue();
				component.set('v.ownerPicklistValues', ownerPicklistValues);
				console.log(ownerPicklistValues);
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	updateCallbackOwner : function(component, event) {
		// Create the action
		var action = component.get('c.updateCallbackOwner');

		var ownerPicklistId = event.target.id;
		var callbackRecordId = ownerPicklistId.substring(15, ownerPicklistId.length);

		// display the "update notification" table row
		var updateNotificationElement = document.getElementById('update-notification-' + callbackRecordId);
		updateNotificationElement.style.display = 'table-row';

		// display the loading spinner icon
		var loadingSpinnerElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .slds-spinner');
		loadingSpinnerElement[0].style.display = 'block';

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId,
			'callbackOwnerId' : event.target.value
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var callbackUpdateSuccess = response.getReturnValue();

				// hide the spinner icon
				loadingSpinnerElement[0].style.display = 'none';

				var updateSuccessElement;

				if (callbackUpdateSuccess) {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-success');
					console.log('callbackUpdateSuccess!');
				}
				else {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-failure');
					console.log('callbackUpdateFailure =(');
				}

				// display the success or failure message
				updateSuccessElement[0].style.display = 'block';
				// update notification row animation
				setTimeout(function() {				
					updateNotificationElement.className = updateNotificationElement.className + ' bounceOut animated';
					setTimeout(function() {
						updateNotificationElement.className = 'update-notification';
						updateNotificationElement.style = 'display: none;';
						updateSuccessElement[0].style.display = 'none';		// TODO: make these consistent			
					}, 700);
				}, 1000);								
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	updateCallbackDate : function(component, event) {
		// CSP-1751 | if invalid value submitted, don't update
		var dateRegEx = /2\d\d\d-\d{1,2}-\d{1,2}/;
		if (event.target.value === null || event.target.value === '' || !dateRegEx.test(event.target.value)) {
			return;
		}

		// Create the action
		var action = component.get('c.updateCallbackDate');

		var dateSelectorId = event.target.id;
		var callbackRecordId = dateSelectorId.substring(14, dateSelectorId.length);

		// display the "update notification" table row
		var updateNotificationElement = document.getElementById('update-notification-' + callbackRecordId);
		updateNotificationElement.style.display = 'table-row';

		// display the loading spinner icon
		var loadingSpinnerElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .slds-spinner');
		loadingSpinnerElement[0].style.display = 'block';

		// create object of browser details for debugging purposes
		var browserDetails = this.generateBrowserDetailsObject();

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId,
			'callbackDate' : event.target.value,
			'browserDetails' : browserDetails
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var callbackUpdateSuccess = response.getReturnValue();

				// hide the spinner icon
				loadingSpinnerElement[0].style.display = 'none';

				var updateSuccessElement;

				if (callbackUpdateSuccess) {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-success');
					console.log('callbackUpdateSuccess!');
				}
				else {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-failure');
					console.log('callbackUpdateFailure =(');
				}

				// display the success or failure message
				updateSuccessElement[0].style.display = 'block';
				// update notification row animation
				setTimeout(function() {				
					updateNotificationElement.className = updateNotificationElement.className + ' bounceOut animated';
					setTimeout(function() {
						updateNotificationElement.className = 'update-notification';
						updateNotificationElement.style = 'display: none;';
						updateSuccessElement[0].style.display = 'none';		// TODO: make these consistent			
					}, 700);
				}, 1000);								
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},	
	// injects a style class into the document head
	// originally created because the ui:inputDate (a.k.a. the date picker) styling is messed up as of October 21, 2016
	/*
	injectStylingOverrides : function() {
		var styleOverrides = document.createElement('style');
		styleOverrides.innerHTML = '.assistiveText {display: none;} .monthYear {margin: 0;}';
		document.getElementsByTagName('head')[0].appendChild(styleOverrides);
	},
	*/
	updateCallbackNotes : function(component, event) {
		// Create the action
		var action = component.get('c.createCallbackNote');
		
		var callbackNotesId = event.target.id;
		var callbackTextAreaId = callbackNotesId.replace('button', 'textarea');
		var callbackRecordId = callbackTextAreaId.substring(24, callbackTextAreaId.length);
		var callbackTextAreaElement = document.getElementById(callbackTextAreaId);
		var callbackNotesTableId = 'callback-notes-table-' + callbackRecordId;
		var callbackNotesViewHideNotesLinkId = callbackNotesId.replace('callback-notes-button', 'view-notes-link');

		// CSP-1753 | hide the callback notes section
		var viewHideNotesLink = document.getElementById(callbackNotesViewHideNotesLinkId);
		viewHideNotesLink.click();

		// display the "update notification" table row
		var updateNotificationElement = document.getElementById('update-notification-' + callbackRecordId);
		updateNotificationElement.style.display = 'table-row';

		// display the loading spinner icon
		var loadingSpinnerElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .slds-spinner');
		loadingSpinnerElement[0].style.display = 'block';

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId,
			'body' : callbackTextAreaElement.value
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var callbackNoteRecord = response.getReturnValue();

				// hide the spinner icon
				loadingSpinnerElement[0].style.display = 'none';

				var updateSuccessElement;

				if (callbackNoteRecord) {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-success');
					
					// Create an empty <tr> element and append it to the table
					var table = document.getElementById(callbackNotesTableId);
					var row = table.insertRow(-1);

					// Insert new cells (<td> elements)
					var cell1 = row.insertCell(0);
					var cell2 = row.insertCell(1);
					var cell3 = row.insertCell(2);

					// Add some text to the new cells
					cell1.innerHTML = callbackNoteRecord.Body;
					cell2.innerHTML = callbackNoteRecord.CreatedBy.Name;
					cell3.innerHTML = callbackNoteRecord.CreatedDate.substring(0, 10);

					// Clear the text area
					callbackTextAreaElement.value = '';

					console.log('callbackUpdateSuccess!');
				}
				else {
					updateSuccessElement = document.querySelectorAll('#update-notification-' + callbackRecordId + ' .update-failure');
					console.log('callbackUpdateFailure =(');
				}

				// display the success or failure message
				updateSuccessElement[0].style.display = 'block';
				// update notification row animation
				setTimeout(function() {				
					updateNotificationElement.className = updateNotificationElement.className + ' bounceOut animated';
					setTimeout(function() {
						updateNotificationElement.className = 'update-notification';
						updateNotificationElement.style = 'display: none;';
						updateSuccessElement[0].style.display = 'none';		// TODO: make these consistent			
					}, 700);
				}, 1000);								
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	viewOrHideCallbackNotes : function(component, event) {
		var viewOrHideNotesLinkElement = event.target;
		var callbackRecordId = event.target.id.substring(16, event.target.id.length);
		var callbackNotesSectionElement = document.getElementById('callback-notes-section-' + callbackRecordId);
		var callbackNotesTableId = 'callback-notes-table-' + callbackRecordId;

		// hide section if already visible
		if (viewOrHideNotesLinkElement.innerHTML !== 'View/Edit Notes') {
			callbackNotesSectionElement.style.display = 'none';
			viewOrHideNotesLinkElement.innerHTML = 'View/Edit Notes';
			return;
		}

		// else if table already populated but currently hidden, just display the table
		if (callbackNotesSectionElement.hasAttribute('data-callback-notes-populated')) {
			callbackNotesSectionElement.style.display = 'table-row';
			viewOrHideNotesLinkElement.innerHTML = 'Hide Notes';
			return;
		}

		// Lastly, if table currently hidden and not already populated, populate and display the table
		// Create the action
		var action = component.get('c.getCallbackNotes');

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var callbackNotesArray = response.getReturnValue();
				var table = document.getElementById(callbackNotesTableId);
				
				for (var i = 0; i < callbackNotesArray.length; i++) {
					var callbackNoteRecord = callbackNotesArray[i];

					// Create an empty <tr> element and add it to the 2nd position of the table
					var row = table.insertRow(i + 1);

					// Insert new cells (<td> elements)
					var cell1 = row.insertCell(0);
					var cell2 = row.insertCell(1);
					var cell3 = row.insertCell(2);

					// Add some text to the new cells
					cell1.innerHTML = callbackNoteRecord.Body;
					cell2.innerHTML = callbackNoteRecord.CreatedBy.Name;
					cell3.innerHTML = callbackNoteRecord.CreatedDate.substring(0, 10);
				}

				callbackNotesSectionElement.style.display = 'table-row';
				callbackNotesSectionElement.dataset.callbackNotesPopulated = true;
				viewOrHideNotesLinkElement.innerHTML = 'Hide Notes';
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	viewOrHideContactDetails : function(component, event) {

		var contactDetailsButtonId = event.target.id;
		var contactDetailsSectionId = contactDetailsButtonId.replace('contact-details-', 'contact-details-section-');
		var contactDetailsTableId = contactDetailsButtonId.replace('contact-details-', 'contact-details-table-');
		var callbackRecordId = contactDetailsButtonId.replace('contact-details-', '');
		var contactDetailsSectionElement = document.getElementById(contactDetailsSectionId);

		// if table currently displayed, just hide the table
		if (event.target.innerHTML === '-') {
			contactDetailsSectionElement.style.display = 'none';
			event.target.innerHTML = '+';
		}

		// otherwise display the table
		else {
			contactDetailsSectionElement.style.display = 'table-row';
			event.target.innerHTML = '-';
		}
	},
	viewOrHideSubscriptionDetails : function(component, event) {

		var subscriptionDetailsButtonId = event.target.id;
		var subscriptionDetailsSectionId = subscriptionDetailsButtonId.replace('sub-details-', 'sub-details-section-');
		var subscriptionDetailsTableId = subscriptionDetailsButtonId.replace('sub-details-', 'sub-details-table-');
		var callbackRecordId = subscriptionDetailsButtonId.replace('sub-details-', '');
		var subscriptionDetailsSectionElement = document.getElementById(subscriptionDetailsSectionId);

		// if table currently displayed, just hide the table
		if (event.target.innerHTML === '-') {
			subscriptionDetailsSectionElement.style.display = 'none';
			event.target.innerHTML = '+';
			return;
		}

		// else if table already populated but currently hidden, just display the table
		if (subscriptionDetailsSectionElement.hasAttribute('data-subscription-details-populated')) {
			subscriptionDetailsSectionElement.style.display = 'table-row';
			event.target.innerHTML = '-';
			return;
		}

		// Lastly, if table currently hidden and not already populated, populate and display the table
		// Create the action
		var action = component.get('c.getSubscriptionDetails');

		// Set params
		action.setParams({
			'callbackRecordId': callbackRecordId
		});

		// Add callback behavior for when the response is received
		action.setCallback(this, function(response) {
			var state = response.getState();
			// Check to make sure component is still valid and that the response was a success
			if (component.isValid() && state === 'SUCCESS') {
				var subscriptionDetailArray = response.getReturnValue();
				var table = document.getElementById(subscriptionDetailsTableId);
				
				for (var i = 0; i < subscriptionDetailArray.length; i++) {
					var subscriptionDetailRecord = subscriptionDetailArray[i];

					// Create an empty <tr> element and add it to the 2nd position of the table
					var row = table.insertRow(i + 1);

					// Insert new cells (<td> elements)
					var cell1 = row.insertCell(0);
					var cell2 = row.insertCell(1);
					var cell3 = row.insertCell(2);

					// Add some text to the new cells
					cell1.innerHTML = subscriptionDetailRecord.Zuora__RatePlanName__c;
					cell2.innerHTML = subscriptionDetailRecord.Zuora__Subscription__r.Zuora__TermStartDate__c;
					cell3.innerHTML = subscriptionDetailRecord.Zuora__Subscription__r.Zuora__TermEndDate__c;
				}

				subscriptionDetailsSectionElement.style.display = 'table-row';
				subscriptionDetailsSectionElement.dataset.subscriptionDetailsPopulated = true;
				event.target.innerHTML = '-';
			}
			else {
				console.log('Failed with response state: ' + state);
			}
		});

		// Send action off to be executed
		$A.enqueueAction(action);
	},
	setOrderStatement : function(component, orderStatement) {
		if (component.isValid()) {
			component.set('v.orderStatement', orderStatement);
		}	
	},	
	getOrderStatement : function(component) {
		if (component.isValid()) {
			var orderStatement = component.get('v.orderStatement');
			console.log('orderStatementadsfdasfdasf');
			console.log(orderStatement);
			return orderStatement;
		}
		// if component is not valid, go ahead and return the default order statement
		return 'Callback_Date__c DESC, Account__r.Name ASC ';		
	},	
	populateOptions : function(optionList, selectParent) {
		var parentContainer = this.findAncestorByClassName(selectParent, 'slds-col');
		for (var i = 0; i < optionList.length; i++) {
			var currentMarket = optionList[i];
			var newOption = document.createElement('option');
			newOption.value = currentMarket;
			newOption.text = currentMarket;
			selectParent.appendChild(newOption);
		}
	},
	generateBrowserDetailsObject : function() {
		var browserDetails = new Object();
		if ('appCodeName' in window.navigator) {
			browserDetails.appCodeName = window.navigator.appCodeName;
		}
		if ('appName' in window.navigator) {
			browserDetails.appName = window.navigator.appName;
		}
		if ('appVersion' in window.navigator) {
			browserDetails.appVersion = window.navigator.appVersion;
		}
		if ('language' in window.navigator) {
			browserDetails.language = window.navigator.language;
		}
		if ('platform' in window.navigator) {
			browserDetails.platform = window.navigator.platform;
		}
		if ('product' in window.navigator) {
			browserDetails.product = window.navigator.product;
		}
		if ('productSub' in window.navigator) {
			browserDetails.productSub = window.navigator.productSub;
		}
		if ('userAgent' in window.navigator) {
			browserDetails.userAgent = window.navigator.userAgent;
		}
		if ('vendor' in window.navigator) {
			browserDetails.vendor = window.navigator.vendor;
		}
		return browserDetails;
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
({
	getSummaryData : function(cmp) {
		// Get account Id from component
		var accountId = cmp.get('v.accountId');
		// Grab action handler to call server method
		var action = cmp.get('c.getSummaryData');
		// Grab status select filte
		var statusSelectElement = document.getElementById('status-select');
		var statusFilter;
		// Set status filter to 'active' for first load - DOM not loaded yet and as such element does not exist
		if(statusSelectElement === null || typeof statusSelectElement === 'undefined') {
			statusFilter = 'active';
		} else {
			statusFilter = statusSelectElement.value;
		}

		// Add parameters to action handler that are being sent to server controller
		action.setParams({
			'accountId' : accountId,
			'statusFilter' : statusFilter.toLowerCase()
		});

		// Setup callback function for action handler
		action.setCallback(this, function(response) {
			var returnValue = response.getReturnValue();
			var state = response.getState();

			// If the response is not successful do not try to execute setup code
			if(state !== 'SUCCESS' || returnValue === null) {
				return;
			}

			// Set component attributes based upon response return values
			cmp.set('v.currentAccount', returnValue.Account);
			cmp.set('v.subscriptions', returnValue.Subscriptions);
			cmp.set('v.billingAccounts', returnValue.Billing);

			// Grab markets from response return value and populate picklist values
			var markets = returnValue.Markets;
			var marketSelect = document.getElementById('market-select');
			this.populateOptions(markets, marketSelect);
			// Grab category from response return value and populate picklist values
			var categories = returnValue.Categories;
			var categorySelect = document.getElementById('category-select');
			categorySelect.disabled = true;
			this.populateOptions(categories, categorySelect);
		});
		// Enqueue action to run
		$A.enqueueAction(action);
	},
	setTab : function(element, scopedItem) {
		// Grab the current active element
		var activeElement = document.querySelector('.slds-active > a');
		// Set the attribute aria-selected to false
		activeElement.setAttribute('aria-selected', 'false');
		// Remove the slds-active classname
		activeElement.parentElement.className = activeElement.parentElement.className.replace('slds-active', '');
		// Get the tab contents element Id needed to get the related content element
		var contentsId = activeElement.getAttribute('aria-controls');
		// Get the content element
		var contentElement = document.getElementById(contentsId);
		// Replace the slds-show with slds-hide classname
		contentElement.className = contentElement.className.replace('slds-show', 'slds-hide');
		// If the current element is does not have the class slds-tabs--scoped__link find parent
		if(element.className.indexOf('slds-tabs--scoped__link') < 0) {
			element = this.findAncestorByClassName(element, 'slds-tabs--scoped__link');
		}
		// Use same process as before to show tab content and set tab to active
		contentsId = element.getAttribute('aria-controls');
		contentElement = document.getElementById(contentsId);
		contentElement.className = contentElement.className.replace('slds-hide', 'slds-show');
		
		element.setAttribute('aria-selected', 'true');
		element.parentElement.className += ' slds-active';
	},
	displayInvoices : function(element, parentRow) {
		// Determine if there are any current invoices being shown. If there are then hide those invoices
		var currentShownInvoices = document.querySelector('tr.invoices-shown');
		if(currentShownInvoices !== null && typeof currentShownInvoices !== 'undefined') {
			this.hideDisplayInvoices(currentShownInvoices);
		}

		// Add classname to parent which indicates it has invoices being shown
		parentRow.className += ' invoices-shown';
		// Grab invoice row(always the next sibling)
		var invoiceRow = parentRow.nextSibling;
		// Remove the 'none' display from sibling row
		invoiceRow.style.display = '';
	},
	hideDisplayInvoices : function(parentRow) {
		// Grab sibling row(invoice row) from parent
		var currentInvoiceRow = parentRow.nextSibling;
		// Remove invoices shown from parent row
		parentRow.className = parentRow.className.replace('invoices-shown', '');
		// Swap fade in animation class names to begin fadeOutRight animation
		currentInvoiceRow.className = currentInvoiceRow.className.replace('fadeInRight', 'fadeOutRight');
		// Create 1 second timeout to allow fadeOutRight animation to finish before hiding and reapplying fadeInRight class 
		// name for next display.
		setTimeout(function() {
			currentInvoiceRow.style.display = 'none';
			currentInvoiceRow.className = currentInvoiceRow.className.replace('fadeOutRight', 'fadeInRight');
		}, 1000);
	},
	populateOptions : function(optionList, selectParent) {
		this.clearOptions(selectParent);

		var parentContainer = this.findAncestorByClassName(selectParent, 'slds-col');
		if(optionList === null || optionList.length < 1) {
				parentContainer.style.display = 'none';
		} else {
			parentContainer.style.display = 'block';

			for(var i = 0; i < optionList.length; i++) {
				var currentMarket = optionList[i];
				var newOption = document.createElement('option');
				newOption.value = currentMarket;
				newOption.text = currentMarket;
				selectParent.appendChild(newOption);
			}
		}
	},
	clearOptions : function(selectParent) {
		while(selectParent.firstChild) {
			selectParent.removeChild(selectParent.firstChild);
		}

		var allNode = document.createElement('option');
		allNode.value = 'none';
		allNode.text = 'All';
		selectParent.appendChild(allNode);
	},
	filterMarketRows : function(tdIndex, rowList, filterValue) {
		var categoryString = 'none,';
		var categorySelect = document.getElementById('category-select');
		categorySelect.value = 'none';
		categorySelect.disabled = false;
		var i;

		for(i = 0; i < rowList.length; i++) {
			var currentRow = rowList[i];
			var tdElement = currentRow.childNodes[tdIndex];

			if(tdElement.innerHTML === filterValue) {
				currentRow.style.display = 'table-row';
				categoryString += currentRow.childNodes[parseInt(tdIndex, 10) + 1].innerHTML + ', ';
				continue;
			}

			currentRow.style.display = 'none';
		}

		for(i = 0; i < categorySelect.childNodes.length; i++) {
			var catOption = categorySelect.childNodes[i];
			if(categoryString.indexOf(catOption.value) > -1) {
				catOption.style.display = 'block';
				continue;
			}

			catOption.style.display = 'none';
		}
	},
	filterCategoryRows : function(tdIndex, rowList, filterValue) {
		var marketSelect = document.getElementById('market-select');

		for(var i = 0; i < rowList.length; i++) {
			var currentRow = rowList[i];
			var tdElement = currentRow.childNodes[tdIndex];
			var secondElement = currentRow.childNodes[marketSelect.dataset.index];
			if(filterValue === 'none' && secondElement.innerHTML === marketSelect.value) {
				currentRow.style.display = 'table-row';
				continue;
			} else if(tdElement.innerHTML === filterValue && secondElement.innerHTML === marketSelect.value) {
				currentRow.style.display = 'table-row';
				continue;
			}

			currentRow.style.display = 'none';
		}
	},
	showAllRows : function(rowList) {
		for(var i = 0; i < rowList.length; i++) {
			var currentRow = rowList[i];
			if(currentRow.style.display === 'table-row') {
				continue;
			}

			currentRow.style.display = 'table-row';
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
({
	doInit : function(component, event, helper) {
		// Call function to retrieve summary data from server
		helper.getSummaryData(component);
	},
	subscriptionSearch : function(component, event, helper) {
		// Call function to retrieve summary data from server
		helper.getSummaryData(component);
	},
	selectTab : function(component, event, helper) {
		// Get scope-item parent
		var scopedItem = helper.findAncestorByClassName(event.target, 'slds-tabs--scoped__item');
		// If the current scope-item parent has the slds active class - jump out
		if(scopedItem.className.indexOf('slds-active') > -1) {
			return;
		}

		// Begin logic to change tab
		helper.setTab(event.target, scopedItem);
	},
	showInvoices : function(component, event, helper) {
		// Determine parent row for clicked invoice link
		var parentRow = helper.findAncestorByClassName(event.target, 'slds-hint-parent');

		// If the parent row is currently showing invoices then hide them
		if(parentRow.className.indexOf('invoices-shown') > -1) {
			// Call function to hide invoices
			helper.hideDisplayInvoices(parentRow);
			return;
		}

		// Call function to display invoices
		helper.displayInvoices(event.target, parentRow);
	},
	sortProductRatePlan : function(component, event, helper) {
		// Get table header parent of element clicked
		var thElement = helper.findAncestorByType(event.target, 'th');
		// Grab subscriptions from component object
		var subscriptions = component.get('v.subscriptions');
		// Determine data that needs to be sorte
		var sortData = thElement.id;
		// Determine direction to sort
		var sortDirection = thElement.className.indexOf('asc') > -1 ? 'asc' : 'desc';
		// Determine opposite direction
		var reverseDirection = sortDirection.indexOf('asc') > -1 ? 'desc' : 'asc';
		
		// Use sort method to sort object by field
		subscriptions.sort(function(a, b) {
			// If a or b have a null value then set it to a blank string for comparison
			if(a.quoteRatePlan.zqu__ProductRatePlan__r[sortData] == null) {
				a.quoteRatePlan.zqu__ProductRatePlan__r[sortData] = '';
			}

			if(b.quoteRatePlan.zqu__ProductRatePlan__r[sortData] == null) {
				b.quoteRatePlan.zqu__ProductRatePlan__r[sortData] = '';
			}

			if(a.quoteRatePlan.zqu__ProductRatePlan__r[sortData] > b.quoteRatePlan.zqu__ProductRatePlan__r[sortData]) {
				return sortDirection === 'asc' ? 1 : -1;
			}

			if(a.quoteRatePlan.zqu__ProductRatePlan__r[sortData] < b.quoteRatePlan.zqu__ProductRatePlan__r[sortData]) {
				return sortDirection === 'asc' ? -1 : 1;
			}

			return 0;
		});

		// Set the direction of the current sort on the table header element
		thElement.className = thElement.className.replace(sortDirection, reverseDirection);
		// Add sorted subscriptions object back into component
		component.set('v.subscriptions', subscriptions);
	},
	// this function was added to handle the sorting for the product type under subscriptions 
    sortProductType : function(component, event, helper) {
		// Get table header parent of element clicked
		var thElement = helper.findAncestorByType(event.target, 'th');
		// Grab subscriptions from component object
		var subscriptions = component.get('v.subscriptions');
		// Determine data that needs to be sorte
		var sortData = thElement.id;
		// Determine direction to sort
		var sortDirection = thElement.className.indexOf('asc') > -1 ? 'asc' : 'desc';
		// Determine opposite direction
		var reverseDirection = sortDirection.indexOf('asc') > -1 ? 'desc' : 'asc';
		
		// Use sort method to sort object by field
		subscriptions.sort(function(a, b) {
			
			// If a or b have a null value then set it to a blank string for comparison
			if(a.subProdCharge[sortData] == null) {
	      		a.subProdCharge[sortData] = '';
	      	}
      
			if(b.subProdCharge[sortData] == null) {
				b.subProdCharge[sortData] = '';
			}

			if(a.subProdCharge[sortData] > b.subProdCharge[sortData]) {
				return sortDirection === 'asc' ? 1 : -1;
			}

			if(a.subProdCharge[sortData] < b.subProdCharge[sortData]) {
				return sortDirection === 'asc' ? -1 : 1;
			}

			return 0;
		});

		// Set the direction of the current sort on the table header element
		thElement.className = thElement.className.replace(sortDirection, reverseDirection);
		// Add sorted subscriptions object back into component
		component.set('v.subscriptions', subscriptions);
	},
	filterMarket : function(component, event, helper) {
		// Grab filter value from event
		var filterValue = event.target.value;
		// Get cellIndex from dataset index attribute
		var cellIndex = event.target.dataset.index;
		
		// Grab all subscription rows to prepare for loop
		var subscriptionRows = document.getElementsByClassName('subscription-row');
		// If the filter value selected is 'none'(All) then show all rows and disable category select
		if(filterValue === 'none') {
			helper.showAllRows(subscriptionRows);
			var categorySelect = document.getElementById('category-select');
			categorySelect.disabled = true;
			categorySelect.value = 'none';
			return;
		}

		// Call function to filter market rows and populate category picklist
		helper.filterMarketRows(cellIndex, subscriptionRows, filterValue);
	},
	filterCategory : function(component, event, helper) {
		// Grab category filter value
		var catFilter = event.target.value;
		// Grab category index from dataset index attribute
		var catIndex = event.target.dataset.index;
		// Grab all subscriptions rows to prepare for loop
		var subscriptionRows = document.getElementsByClassName('subscription-row');
		// Call function to filter category rows
		helper.filterCategoryRows(catIndex, subscriptionRows, catFilter);
	}
})
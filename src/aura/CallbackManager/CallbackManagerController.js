({
	doInit : function(component, event, helper) {
		helper.setOrderStatement(component, 'Callback_Date__c ASC, Account__r.Name ASC ');
		helper.getStrategySpecialistPicklistValues(component);		
		helper.getStatusPicklistValues(component);
		helper.getMarketPicklistValues(component);
		helper.getCategoryPicklistValues(component);
		helper.getOwnerPicklistValues(component);
		helper.getCallbacks(component, 1);
	},
	callbackSearch : function(component, event, helper) {
		helper.getCallbacks(component, 1);
	},
	pageChangePrevious : function(component, event, helper) {
		var page = component.get('v.page'); // this button should only be visible on pages > 1
		page = (page - 1);
		helper.getCallbacks(component, page);
	},
	pageChangeNext : function(component, event, helper) {
		var page = component.get('v.page') || 1;
		page = (page + 1);
		helper.getCallbacks(component, page);
	},
	callbackStatusUpdate : function(component, event, helper) {
		helper.updateCallbackStatus(component, event);
	},
	callbackOwnerUpdate : function(component, event, helper) {
		helper.updateCallbackOwner(component, event);
	},
	callbackDateUpdate : function(component, event, helper) {
		helper.updateCallbackDate(component, event);
	},
	callbackNotesUpdate : function(component, event, helper) {
		helper.updateCallbackNotes(component, event);
	},
	viewOrHideNotesClick : function(component, event, helper) {
		helper.viewOrHideCallbackNotes(component, event);
	},
	viewOrHideContactDetailsClick : function(component, event, helper) {
		helper.viewOrHideContactDetails(component, event);
	},
	clickNavigate : function(component, event, helper) {
		var targetElement = event.target;
		var navigationUrl = event.target.dataset.url;

		if(navigationUrl === null) {
			return;
		}

		if(sforce.console.isInConsole()) {
			sforce.console.openPrimaryTab(null, navigationUrl, true);
		} else {
			window.open(navigationUrl, '_blank');
		}
	},
	viewOrHideSubscriptionDetailsClick : function(component, event, helper) {
		helper.viewOrHideSubscriptionDetails(component, event);
	},
	sortCallbacks : function(component, event, helper) {
		// Get table header parent of element clicked
		var thElement = helper.findAncestorByType(event.target, 'th');
		// Determine data that needs to be sorte
		var sortData = thElement.id;
		// Determine direction to sort
		var sortDirection = thElement.className.indexOf('asc') > -1 ? 'asc' : 'desc';
		// Determine opposite direction
		var reverseDirection = sortDirection.indexOf('asc') > -1 ? 'desc' : 'asc';
		// Set the direction of the current sort on the table header element
		thElement.className = thElement.className.replace(sortDirection, reverseDirection);
		// Set the order statement
		var orderStatement = sortData + ' ' + sortDirection.toUpperCase() + ' ';
		helper.setOrderStatement(component, orderStatement);
		// Get callback records
		helper.getCallbacks(component, 1);
	}
})
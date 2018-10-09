/*
 author: Steve O'Neal
 date: 4/25/2015
 purpose: allows an admin to search for all fields related to a user and reassign them
 Custom Settings dependencies:
 	 - ReassignOwnershipControllerField__c ("Reassign User - Fields to Ignore") 
 	 	- Contains a list of field (api) names that should be exclude
 	 	  when searching to reassign a User in the Reassign User app

 	 - ReassignOwnershipControllerNonUser__c ("Reassign User - Non-Lookup User Fields") 
 	 	- List of objects and their related fields that aren't mapped directly to a User via a lookup. 
 	 	  Examples would be dropdowns where you choose a user. Because this will return metadata and not 
 	 	  records, they cannot be updated directly, instead it is an informational search.

 	 - ReassignOwnershipControllerObject__c ("Reassign User - Objects to Ignore") 
 	 	- Contains a list of object (api) names that should be excluded when searching to 
 	 	  reassign a User in the Reassign User app

 	 - ReassignOwnershipControllerOpenClosedObj__c ("Reassign User - Open and Closed Objects") 
 	 	- List of objects that are defined as "open" and "closed", like cases and opportunities, 
 	 	  and what defines them as such
 */
public with sharing class ReassignOwnershipController {
	
	public Account ownerHolder {get;set;}
	private List<Schema.SObjectType> objectTypeList;
	private boolean searched;
	private List<Schema.sObjectType> LookupsToUserField;
	
	private Map<string, ReassignOwnershipControllerObject__c> objectsThatCannotBeSearched;
	private Map<string, ReassignOwnershipControllerField__c> userFieldsToIgnore;
	private Map<string, ReassignOwnershipControllerOpenClosedObj__c> limitSearchOpenClosed;
	private Map<string, ReassignOwnershipControllerNonUser__c> nonUserFields;
	
	public string parentQuery {get;set;}
	public string searchBy {get;set;}
	private string lclSelectedObject;
	public String selectedObject
	{
		get
		{
			return lclSelectedObject;
		}
		set
		{
			lclSelectedObject = value;
			System.Debug('obj type:' + lclSelectedObject);
			selectedObjectType = null;
			// find the object in the list
			for (sObjectType tmpObjType : objectTypeList)
			{
				if (tmpObjType.getDescribe().getName() == lclSelectedObject)
				{
					selectedObjectType = tmpObjType;
					break;
				}
			}
		}
	}
	private sObjectType selectedObjectType;
	public String selectedField {get;set;}
	public String selectedOperator {get;set;}
	public String selectedValue {get;set;}
	
	public String errSelectedObject {get;set;}
	public String errSelectedField {get;set;}
	public String errSelectedOperator {get;set;}
	public String errSelectedValue {get;set;}
	public String errParentQuery {get;set;}
	
	public List<SearchableField> allObjects {get;set;}
	private integer queryCount = 0;
	public integer maxQueries {get;set;}
	
	public boolean SearchOnlyOwnershipFields {get;set;}
	public boolean SearchClosedRecords {get;set;}
	public boolean SearchOpenRecords {get;set;}
	
	private string logSuccessFolderName = 'ReassignUserLogSuccess';
	private string logFailureFolderName = 'ReassignUserLogFailure';
	
	private Folder logSuccessFolder;
	private Folder logFailureFolder;
	private Folder logFolder;
	
	private String parentIds;
	
	public boolean istest {get;set;}
	
	public String getNow()
	{
		return String.ValueOF(DateTime.Now());
	}
	
	public String getCurrentSearchBy()
	{
		return searchBy;
	}
	
	public boolean ShowNoResults{
		get
		{
			return (searched && allObjects.size() == 0);
		}
	}
	
	public boolean ShowResults{
		get
		{
			return (allObjects.size() > 0);
		}
	}
	
	// build the list of objects that can be searched against
	public List<SelectOption> getSearchableObjects()
	{
		List<SelectOption> retVal = new List<SelectOption>();
		retVal.add(new SelectOption('',''));
		
		List<string> objectNameList = new List<string>();
		for (Schema.SObjectType objectType : objectTypeList)
		{
			// is the object searchable/updateable?
			if (ObjectIsSearchable(objectType))
			{
				objectNameList.add(objectType.getDescribe().getName());
			}
		}	
		
		
		objectNameList.sort();
		
		for (string sortedObjectName : objectNameList)
		{
			for (Schema.SObjectType objectType : objectTypeList)
			{
				string tmpObjName = objectType.getDescribe().getName();
				string tmpObjLabel = objectType.getDescribe().getLabel();
				if (tmpObjName == sortedObjectName)
				{
					retVal.add(new SelectOption(tmpObjName, tmpObjName));				
				}
			}	
		}
		
		return retVal;	
	}
	
	
	private boolean ObjectIsSearchable(sobjectType objectType)
	{
		boolean retVal = false;
		
		if (!objectsThatCannotBeSearched.containsKey(objectType.getDescribe().getName()))
		{
			// ignore some objects based on their name ending - they are system created cannot be reassigned
			if(   !objectType.getDescribe().getName().endswith('Share')
			   && !objectType.getDescribe().getName().endswith('Feed')
			   && !objectType.getDescribe().getName().endswith('History')
			   && !objectType.getDescribe().getName().endswith('ContactRole')
			   && !objectType.getDescribe().getName().endswith('Stage')
			   && !objectType.getDescribe().getName().endswith('Status')
			   )
			   {
					return true;
			   }
		}
		return retVal;
	}


	private boolean FieldIsSearchable(sObjectType sourceObject, string fieldName)
	{
		if (!userFieldsToIgnore.containsKey(fieldName) 
			&& ObjectIsSearchable(sourceObject)
			&& ((SearchOnlyOwnershipFields && fieldName == 'OwnerId') || !SearchOnlyOwnershipFields) // search only Owner fields / search all fields based on user selection
			)
			{
				return true;
			}
		
		return false;		
	}
	
	public List<SelectOption> getSearchableFields()
	{
		List<String> fieldNames = new List<String>();
		List<SelectOption> retVal = new List<SelectOption>();
		retVal.add(new SelectOption('',''));
		
		if (selectedObjectType != null)
		{
			// fill the list of field names so they can be sorted
			Map<String,Schema.SObjectField> objFieldMap = selectedObjectType.getDescribe().fields.getMap();
			fieldNames.addAll(objFieldMap.keyset());
			fieldNames.sort();
			
			for (String fieldName : fieldNames)
			{
				// is the object searchable/updateable?
				if (FieldIsSearchable(selectedObjectType, fieldName))
				{
					retVal.add(new SelectOption(fieldName, objFieldMap.get(fieldName).getDescribe().getLabel()));				
				}
			}
		}
		
		return retVal;	
	}
	
	
	public List<SelectOption> getOperators()
	{
		List<SelectOption> retVal = new List<SelectOption>();
		retVal.add(new SelectOption('=', 'equals'));
		retVal.add(new SelectOption('<>', 'not equal to'));

		if (selectedObjectType != null && selectedField != null)
		{
			Map<String,Schema.SObjectField> objFieldMap = selectedObjectType.getDescribe().fields.getMap();
			sObjectField objSelectedField = objFieldMap.get(selectedField);

			if (objSelectedField.getDescribe().getType() == DisplayType.Boolean)
			{
				// no additional fields
				return retVal;
			}

			retVal.add(new SelectOption('<', 'less than'));
			retVal.add(new SelectOption('>', 'greater than'));
			retVal.add(new SelectOption('<=', 'less or equal'));
			retVal.add(new SelectOption('>=', 'greater or equal'));

			if (objSelectedField.getDescribe().getType() == DisplayType.Currency 
				|| objSelectedField.getDescribe().getType() == DisplayType.Date
				|| objSelectedField.getDescribe().getType() == DisplayType.DateTime
				|| objSelectedField.getDescribe().getType() == DisplayType.Integer
				|| objSelectedField.getDescribe().getType() == DisplayType.Percent
				|| objSelectedField.getDescribe().getType() == DisplayType.Time
				|| objSelectedField.getDescribe().getType() == DisplayType.Double)
			{
				// any remaining non-string fields, return results
				return retVal;
			}

			retVal.add(new SelectOption('contains', 'contains'));
			retVal.add(new SelectOption('does not contain', 'does not contain'));
			retVal.add(new SelectOption('starts with', 'starts with'));
			retVal.add(new SelectOption('ends with', 'ends with'));
		}

		return retVal;	
	}

	public ReassignOwnershipController()
	{
		maxQueries = 94;
		isTest = false;
		initialize();
		LoadConfiguration();
	}
	
	private void initialize()
	{
		System.Debug('Initializing');
		
		searchBy = 'User';
		LookupsToUserField = new List<schema.sObjectType>();
		objectTypeList = Schema.getGlobalDescribe().Values(); 
		ownerHolder = new Account();
		allObjects = new List<SearchableField>();
		searched = false;
		SearchOnlyOwnershipFields = false;
		SearchClosedRecords = false;
		SearchOpenRecords = true;
		
		selectedObject = '';
		selectedObjectType = null;
		selectedField = '';
		selectedOperator = '=';
		selectedValue = '';
		parentQuery = '';

		
		// get log folders
		try
		{
			logSuccessFolder = [select id, name from Folder where name=:logSuccessFolderName LIMIT 1];
		}
		catch (Exception noSuccessFolder) {	throw new ApplicationException('Please create a folder in Documents with the name ' + logSuccessFolderName + ' so that log files can be created');}

		try
		{
			logFailureFolder = [select id, name from Folder where name=:logFailureFolderName LIMIT 1];
		}
		catch (Exception noSuccessFolder) {	throw new ApplicationException('Please create a folder in Documents with the name ' + logFailureFolderName + ' so that log files can be created');}
		
		
	}
	
	
	
	public void LoadConfiguration()
	{
		// add objects that we don't care to search/cannot be searched
		objectsThatCannotBeSearched = ReassignOwnershipControllerObject__c.getAll();
		System.Debug('Objects to ignore:' + objectsThatCannotBeSearched.size());
		 
		// add fields we don't want to reassign
		userFieldsToIgnore = ReassignOwnershipControllerField__c.getAll();
		System.Debug('Fields to ignore:' + userFieldsToIgnore.size());
		
		// get definitions for open/closed objects
		limitSearchOpenClosed = ReassignOwnershipControllerOpenClosedObj__c.getAll();
		System.Debug('Open/Closed objects:' + limitSearchOpenClosed.size());
		
		// get the definitions of any non-user fields related to user
		nonUserFields = ReassignOwnershipControllerNonUser__c.getAll();
		System.Debug('Non-user lookup fields:' + nonUserFields.size());
	}
	
	
	public void searchRecords()
	{
		System.Debug('Entering searchRecords');
		
		
		parentIds = '';

		/*********************
		VALIDATION
		*********************/
		if (searchBy == 'User')
		{
			if (ownerHolder.OwnerID == null)
			{
				ownerHolder.OwnerId.addError('Enter a user');
				return;
			}
			
			selectedObject = 'User';
			selectedObjectType = User.getSObjectType();
			selectedField = 'Id';
			selectedOperator = '=';
			selectedValue = ownerHolder.OwnerId;
		}
		else
		{
			if (selectedObjectType == null)
			{
				errSelectedObject = 'Select an Object to search against';
				return;
			}
	
			if (selectedField == '' || selectedField == null)
			{
				errSelectedField = 'Select a Field to search against';
				return;
			}
			
		}
		
		Map<String,Schema.SObjectField> objFieldMap = selectedObjectType.getDescribe().fields.getMap();
		searched = true;
		allObjects = new List<SearchableField>();

		/*********************
		GET PARENT OBJECT DETAILS
		*********************/
		if (parentQuery == '')
		{
			parentQuery = getObjectQuery(selectedObjectType, objFieldMap.get(selectedField), selectedOperator, selectedValue, null);
		}
		queryCount++;
		System.Debug(parentQuery);
		List<sObject> parentObjects = new List<sObject>();
		
		try
		{
			errParentQuery = '';
			parentObjects = database.query(parentQuery);
		}
		catch (Exception e)
		{
			errParentQuery = e.getMessage();
			return;
		}
		
		/*********************
		GET PARENT OBJECT IDS INTO A STRING
		These are used later to query against the child objects
		*********************/
		string comma = '';
		for (sObject parent : parentObjects)
		{
			parentIds += comma + '\'' + parent.Id + '\'';
			comma = ',';
		}
		
		if (searchBy == 'User')
		{
			ownerHolder.Owner = (User)parentObjects[0];
		}
		else
		{
			// when searching against a non-user object, make sure to include the parent as the first option for reassignment

			for (String userFieldName : objFieldMap.keySet())
			{
				if (FieldIsSearchableLookup(selectedObjectType, objFieldMap.get(userFieldName).getDescribe(), User.getSObjectType()))
				{
					allObjects.addAll(ConvertSearchResultsToSearchableField(parentObjects, selectedObjectType, parentQuery, 'These are the parent ' + selectedObjectType.getDescribe().getLabelPlural(), objFieldMap.get(userFieldName).getDescribe()));
				}
			}
		}
		
		
		/*********************
		SEARCH OBJECTS WITH FIELDS THAT LOOKUP TO PARENTS
		*********************/
		for (Schema.SObjectType objectType : objectTypeList)
		{
			// is the object searchable/updateable?
			if (ObjectIsSearchable(objectType))
			{
				// spider through the collection of fields and find any that point to user
				Map<String,Schema.SObjectField> tmpObjFieldMap = objectType.getDescribe().fields.getMap();

				for (String fieldName : tmpObjFieldMap.keySet())
				{
					if (FieldIsSearchableLookup(objectType, tmpObjFieldMap.get(fieldName).getDescribe(), selectedObjectType))
					{
						
						// The main distiction between searching by user and searching by object is that when searching by user,
						// the field used to identify the records is the same record that is going to be updated.
						// When searching by object, you must loop through both the lookups to the main object, then query for every user field.
						// We need to run the query for each user field to avoid accidentally updating the same record twice and overwriting changes.

						if (queryCount >= maxQueries)
						{
							break;
						}

						string query = '';
						List<sObject> searchResults = new List<sObject>();
						try
						{
							queryCount++;
							// non-lookup user records need to be built special
							if (selectedObjectType == User.getSObjectType() && FieldIsNonUserLookup(objectType, tmpObjFieldMap.get(fieldName).getDescribe()))
							{
								query = getObjectQuery(objectType, tmpObjFieldMap.get(fieldName), '=', (string)ownerHolder.Owner.get(getNonUserLookupFieldUserFieldTarget(objectType, tmpObjFieldMap.get(fieldName).getDescribe())), null);
							}
							else
							{
								query = getObjectQuery(objectType, tmpObjFieldMap.get(fieldName), 'in', '(' + parentIds + ')', null);
							}
							searchResults = database.Query(query);
						}
						catch (Exception queryException)
						{
							System.Debug(queryException);
							System.Debug(query);
						}

						
						if (searchResults.size() > 0)
						{
							for (String userFieldName : tmpObjFieldMap.keySet())
							{
								
								boolean updateableField = false;
								if (selectedObjectType == User.getSObjectType())
								{
									if (userFieldName == fieldName)
									{
										updateableField = true;
									}
								}
								else if (FieldIsSearchableLookup(objectType, tmpObjFieldMap.get(userFieldName).getDescribe(), User.getSObjectType()))
								{
									updateableField = true;
								}
								
								if (updateableField)
								{
									// build the placeholder and add it to the list
									allObjects.addAll(ConvertSearchResultsToSearchableField(searchResults, objectType, query, 'These child ' + objectType.getDescribe().getLabelPlural() + ' were found via ' + tmpObjFieldMap.get(fieldName).getDescribe().getLabel(), tmpObjFieldMap.get(userFieldName).getDescribe()));
								}
							}
						}
					}
				}
			}
		}		
	}
	
	
	private List<SearchableField> ConvertSearchResultsToSearchableField(List<sObject> searchResults, SObjectType objType, string query, string additionalMessage, DescribeFieldResult userField)
	{
		List<SearchableField> retVal = new List<SearchableField>();

		// don't waste cycles processing the search results if there were no records found
		if (searchResults.size() == 0)
		{
			return retVal;
		}
		
		if (FieldIsSearchableLookup(objType, userField, User.getSObjectType()))
		{
			SearchableField tmpSearchableField = new SearchableField();
			tmpSearchableField.fieldLabel = userField.getLabel();
			tmpSearchableField.fieldName = userField.getName();
			tmpSearchableField.objectName = objType.getDescribe().getLabel();
			tmpSearchableField.objectList = searchResults;
			tmpSearchableField.SOQLStatement = query;
			
			if (userField.getReferenceTo().size() == 0)
			{
				// this is just a text value, not a true lookup to user.  Display a text field to enter values.
				tmpSearchableField.textField = true;
				if (String.ValueOf(userField.getType()).ToLowerCase().Contains('picklist'))
				{
					tmpSearchableField.alertMessage += 'This is a picklist field.  If the values being replaced are no longer a valid selection, an administrator must replace them.<br/><br/>';
				}
			}
			
			if (additionalMessage != null)
			{
				tmpSearchableField.alertMessage += additionalMessage + '\n';
			}
				

			retVal.add(tmpSearchableField);
		}

		return retVal;
	}
	
	private string getObjectQuery(sObjectType objType, sObjectField objField, string strOperator, string strValue, string strAdditionalTargetField)
	{
		errSelectedValue = '';
		//System.Debug('Entering getObjectQuery');
		//System.Debug(strObject + ',' + strField + ',' + strOperator + ',' + strValue);

		// sets are case-sensitive, so to avoid SOQL errors make sure you only add lowercase field names!
		Set<string> objFieldsSet = new Set<string>();
		
		// add any "always required" fields
		objFieldsSet.addAll(getDefaultSelectFields(objType));
		
		// at a minimum, we will need search fields
		objFieldsSet.add(objField.getDescribe().getName().toLowerCase());
		
		if (strAdditionalTargetField != null)
		{
			// get the additional field
			objFieldsSet.add(strAdditionalTargetField.toLowerCase());
		}

		// build a querystring from the list of fields
		string comma = '';
		string objectQuery = 'select ';
		for (string strObjField : objFieldsSet)
		{
			objectQuery += comma + strObjField;
			comma = ',';
		}
		objectQuery += ' from ' + objType.GetDescribe().getName();
		
		// add additional criteria
		objectQuery += ' where ';
		
		DescribeFieldResult descField = objField.getDescribe();
		
		try
		{
			
			if (strOperator == 'starts with')
			{
				objectQuery += descField.getName() + ' like ' + formatForQuery(strValue + '%', descField);
			}
			else if (strOperator == 'ends with')
			{
				objectQuery += descField.getName() + ' like ' + formatForQuery('%' + strValue, descField);
			}
			else if (strOperator == 'contains')
			{
				objectQuery += descField.getName() + ' like ' + formatForQuery('%' + strValue + '%', descField);
			}
			else if (strOperator == 'does not contain')
			{
				objectQuery += '(NOT ' + descField.getName() + ' like ' + formatForQuery('%' + strValue + '%', descField) + ')';
			}
			else if (strOperator == 'in')
			{
				// assume that the value has already been encoded - this may change if "in" becomes a selectable value to the user!
				objectQuery += '(' + descField.getName() + ' in ' + strValue + ')';
			}
			else
			{
				objectQuery += descField.getName() + ' ' + strOperator + formatForQuery(strValue, descField);
			}
		}
		catch (Exception queryException)
		{
			errSelectedValue = queryException.getMessage();
			return '';
		}
		
		// add filter for open/closed objects, where applicable
		objectQuery += BuildOpenCloseQueryPart(objType.GetDescribe().getName());

		// limit results during testing to speed it up
		if (istest) {objectQuery += ' limit 1';}

		return objectQuery;
	}
	
	
	
	// formats a string into SOQL syntax
	private String formatForQuery(string val, DescribeFieldResult field)
	{
		string retVal = '';
		
		if (field.getType() == DisplayType.DateTime)
		{
			retVal = DateTime.Parse(val + ' 12:00 AM').format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
		}
		else if (field.getType() == DisplayType.Date)
		{
			retVal = DateTime.Parse(val +  ' 12:00 AM').format('yyyy-MM-dd');
		}
		else if (field.getType() == DisplayType.Time)
		{
			retVal = DateTime.ValueOf(val).format('hh:mm:ss\'z\'');
		}
		else if (field.getType() == DisplayType.Boolean 
			  || field.getType() == DisplayType.Double
			  || field.getType() == DisplayType.Integer
			  || field.getType() == DisplayType.Percent)
		{
			retVal = val;
		}
		else
		{
			retVal = '\'' + String.escapeSingleQuotes(val) + '\'';
		}
		
		return retVal;
	}

	
	
	// determines if the lookup field could potentially reference the parent object
	private boolean FieldIsSearchableLookup(sObjectType sourceObject, DescribeFieldResult sourceField, sObjectType targetObject)
	{
		
		string fieldName = sourceField.getName().toLowerCase();
		
		if (!FieldIsSearchable(sourceObject, fieldName))
		{
			return false;	
		}
		
		if (FieldIsNonUserLookupToTarget(sourceObject, sourceField, targetObject))
		{
			return true;
		}

		for (sObjectType referenceToSObj : sourceField.getReferenceTo())
		{
			if (referenceToSObj == targetObject && FieldIsSearchable(sourceObject, fieldName))
				{
					return true;
				}
		}
		
		return false;
	}
	
	
	private string getNonUserLookupFieldUserFieldTarget(sObjectType sourceObject, DescribeFieldResult sourceField)
	{
		for (ReassignOwnershipControllerNonUser__c nonUserFieldItem : nonUserFields.values())
		{
			if (nonUserFieldItem.Object_Name__c.toLowerCase() == sourceObject.getDescribe().getName().toLowerCase() && nonUserFieldItem.Object_Field_Name__c.toLowerCase() == sourceField.getName().toLowerCase())
			{
				return nonUserFieldItem.User_Field_Name__c;
			}
		}
		return '';
	}
	
	
	private boolean FieldIsNonUserLookup(sObjectType sourceObject, DescribeFieldResult sourceField)
	{
		for (ReassignOwnershipControllerNonUser__c nonUserFieldItem : nonUserFields.values())
		{
			if (nonUserFieldItem.Object_Name__c.toLowerCase() == sourceObject.getDescribe().getName().toLowerCase() && nonUserFieldItem.Object_Field_Name__c.toLowerCase() == sourceField.getName().toLowerCase())
			{
				return true;
			}
		}
		
		return false;
	}
	
	
	private boolean FieldIsNonUserLookupToTarget(sObjectType sourceObject, DescribeFieldResult sourceField, sObjectType targetObject)
	{
		if (FieldIsNonUserLookup(sourceObject, sourceField) && targetObject == User.getSObjectType())
		{
			return true;
		}
		
		return false;
	}
	
	
	
	private string BuildOpenCloseQueryPart(string objectName)
	{
		string query = '';
		if (limitSearchOpenClosed.containsKey(objectName))
		{
			query += ' and (';

			if (SearchOpenRecords)
			{
				query += '(' + limitSearchOpenClosed.get(objectName).Open_SOQL_Statement__c + ')';
				
				if (SearchClosedRecords)
				{
					query += ' or ';
				}
			}
									
			if (SearchClosedRecords)
			{
				query += '(' + limitSearchOpenClosed.get(objectName).Closed_SOQL_Statement__c + ')';
			}
									
			query += ')';
		}
		
		return query;
		
	}
	

	/*********************
	SEARCH FOR OBJECTS BASED ON THE USER-MODIFIED QUERIES
	*********************/
	public void requeryFillObjectMap()
	{
		System.Debug('Entering requeryFillObjectMap');
		List<SearchableField> tmpObjects = new List<SearchableField>();
		
		for (SearchableField field : allObjects)
		{
			tmpObjects.add(field);

			try
			{
				System.Debug(field.SOQLStatement);
				List<sObject> searchResults = database.Query(field.SOQLStatement);
				field.objectList = searchResults;
			} 
			catch (Exception queryException)
			{
				System.Debug('*** Query exception ***');
				System.Debug(queryException);
				field.selectedUserHolder.OwnerId.addError(queryException);
				field.selectedUserHolder.Name.addError(queryException);
				
			}
		}
		
		allObjects = tmpObjects;
	}
	
	public class SearchableField
	{
		public String fieldName {get;set;}
		public String fieldLabel {get;set;}
		public String objectName {get;set;}
		public List<sObject> objectList {get;set;}
		public Account selectedUserHolder {get;set;}
		public String SOQLStatement {get;set;}
		public Boolean textField {get;set;}
		public String alertMessage {get;set;}
		
		public SearchableField()
		{
			textField = false;
			System.Debug('Instantiating SearchableField');
			objectList = new List<sObject>();
			selectedUserHolder = new Account();
			alertMessage = '';
			SOQLStatement = '';
			objectName = '';
			fieldLabel = '';
			fieldName = '';
		}
	}
	
	private Set<string> getDefaultSelectFields(sObjectType sObjType)
	{
		Set<string> retVal = new Set<string>();
		Map<String,Schema.SObjectField> objFieldMap = sObjType.getDescribe().fields.getMap();
		string targetObjectName = sObjType.getDescribe().getName().toLowerCase();
		
		
		for(String fieldName : objFieldMap.keyset())
		{
			if (!fieldName.toLowerCase().startsWith('userpreferences') && !fieldName.toLowerCase().startsWith('afield'))
			{
				Schema.DescribeFieldResult describeResult = objFieldMap.get(fieldName).getDescribe();
				//IF FIELD IS CREATEABLE AND IS NOT NILLABLE AND IS NOT DEFAULTED ON CREATE THEN ITS REQUIRED
				// ignore very large fields - they will break the query
				if (describeResult.getType() != DisplayType.base64 && describeResult.getType() != DisplayType.EncryptedString && describeResult.getType() != DisplayType.TextArea)
				{
					if ((fieldName.toLowerCase() == 'id') || (describeResult.isCreateable() && !describeResult.isNillable() && !describeResult.isDefaultedOnCreate()))
					{
						retVal.add(fieldName.toLowerCase());
					}
					
					// add any lookups that reference the parent object
					if (FieldIsSearchableLookup(sObjType, objFieldMap.get(fieldName).getDescribe(), selectedObjectType) || FieldIsSearchableLookup(sObjType, objFieldMap.get(fieldName).getDescribe(), User.getSObjectType()))
					{
						retVal.add(fieldName.toLowerCase());
					}
				}
			}
		}
		
		// add the non-lookup user fields
		for (ReassignOwnershipControllerNonUser__c nonUserFieldItem : nonUserFields.values())
		{
			if (targetObjectName == 'user')
			{
				retVal.add(nonUserFieldItem.User_Field_Name__c.toLowerCase());
			}
		}
		
		// special addition for contact and user - add first name manually - non required but useful in debugging
		if (targetObjectName == 'user' || targetObjectName == 'contact')
		{
			retVal.add('firstname');
		}
		
		return retVal;
	}
	
	public Void Save()
	{
		System.Debug('Entering Save');
		string logDelim = ',';
		string logEscape = '"';
		string logNewline = '\n';
		
		for (SearchableField field : allObjects)
		{
			// build a log and set the new values at the same time
			string logFileName = dateTime.Now().format() + '-' + field.objectName + '-' + field.fieldName + '.csv';
			// start the body of the file with a header
			string logAllRows = 'id,object,field,oldvalue,newvalue' + logNewline;
			string logRowValue = '';
			
			boolean saveRecords = false;
			
			string oldValue = '';
			string newValue = '';

			if (field.textField && field.selectedUserHolder.Name != null)
			{
				saveRecords = true;
				newValue = field.selectedUserHolder.Name;
			}
			else if (!field.textField && field.selectedUserHolder.OwnerId != null)
			{
				saveRecords = true;
				newValue = String.Valueof(field.selectedUserHolder.OwnerId);
			}
			
			if (saveRecords)
			{
				System.Debug('User reference change for ' + field.objectName + '.' + field.fieldName + ' - new value:' + newValue);
				for (sObject obj : field.objectList)
				{
					oldValue = String.Valueof(obj.get(field.fieldName));
					
					if (oldValue == null) { oldValue = ''; }

					logRowValue = obj.Id; // id
					logRowValue += logDelim + logEscape + field.objectName.Replace(logEscape, logEscape + logEscape) + logEscape; // object
					logRowValue += logDelim + logEscape + field.fieldName.Replace(logEscape, logEscape + logEscape) + logEscape; // field
					logRowValue += logDelim + logEscape + oldValue.Replace(logEscape, logEscape + logEscape) + logEscape; // oldvalue
					logRowValue += logDelim + logEscape + newValue.Replace(logEscape, logEscape + logEscape) + logEscape; // newvalue
					
					logAllrows += logRowValue + logNewline;
					System.Debug(obj.Id + ' *** ' + field.FieldName + ' *** ' + newValue);
					try
					{
						obj.put(field.fieldName, newValue);
					} catch (Exception e) {}
				}

				try
				{
					update field.objectList;
					logFolder = logSuccessFolder;
				}
				catch (Exception updateException)
				{
					// add to both places because depending on the type of field, either may be displayed
					field.selectedUserHolder.OwnerId.addError(updateException);
					field.selectedUserHolder.Name.addError(updateException);
					logFolder = logFailureFolder;
				}
				finally
				{
					SaveLogFile(logFileName, logAllRows, logFolder);
				}
			}
		}
		
		requeryFillObjectMap();
	}
	
	
	public void SaveLogFile(string fileName, string fileBody, Folder targetFolder)
	{
		try
		{
			System.Debug('Saving log ' + fileName + ' to ' + targetFolder.Name);
			Document d = new Document(); 
			d.Name = fileName; 
			d.Body = Blob.valueOf(fileBody); 
			d.ContentType = 'text/plain';
			d.Type = 'csv';
			d.folderId = targetFolder.Id;
			insert d;			
		}
		catch (Exception e)
		{
			System.Debug(e);
		}
	}
}
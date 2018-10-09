public with sharing class NVM_Embedded_Player_Controller {
	public Boolean allowedToViewRecordings {get; private set;}
	public Boolean systemAdmin {get; private set;}

	private static final String OBJECT_QUERY = 'SELECT '
																							+	'Id, '
																							+	'OwnerId '
																							+ '{OBJECTFIELD}'
																						+	' FROM '
																							+	'{OBJECTTYPE}'
																						+	' WHERE '
																							+	'{WHERECLAUSE}';

	public NVM_Embedded_Player_Controller(ApexPages.StandardController stdController) {
		Id currentObjectId = stdController.getId();
		String objectType = String.valueOf(currentObjectId.getSobjectType());
		Id ownerId;
		systemAdmin = false;
		String taskResourceType;
		
		try {
			String objectQuery = OBJECT_QUERY.replace('{OBJECTTYPE}', objectType);
			objectQuery = objectQuery.replace('{WHERECLAUSE}', 'Id = :currentObjectId');
			
			if (objectType == 'TASK') {
		    objectQuery = objectQuery.replace('{OBJECTFIELD}', ', TaskResourceType__c');
			}else{
				objectQuery = objectQuery.replace('{OBJECTFIELD}', '');
			}

			SObject currentObject = Database.query(objectQuery);

			ownerId = (Id)currentObject.get('OwnerId');
			if (objectType == 'TASK') {
				taskResourceType = (String)currentObject.get('TaskResourceType__c');
			}
		} catch(Exception e) {
			allowedToViewRecordings = false;
			systemAdmin = false;
			return;
		}
		
		String ownerObjectType = String.valueOf(ownerId.getSObjectType());

		if(ownerObjectType == 'User') {
			// Do validtion logic for current user
			Map<Id, User> userIdMap = getUserRecord(new List<Id>{UserInfo.getUserId(), ownerId});

			User currentUser;
			if(userIdMap.containsKey(UserInfo.getUserId())) {
				currentUser = userIdMap.get(UserInfo.getUserId());
			}

			User objectOwner;
			if(userIdMap.containsKey(ownerId)) {
				objectOwner = userIdMap.get(ownerId);
			}

			if(currentUser == null || objectOwner == null) {
				allowedToViewRecordings = false;
				systemAdmin = false;
			}

			/*
				Either the current running User is the Owner of the Object or they are the manager of the owner of the Object
			 */
			if(currentUser.Id == objectOwner.Id || currentUser.Id == objectOwner.Manager.Id) {
				// for ticket CSP-2353, user can only view the VoiceMail record on task
				// allowedToViewRecordings = true;
				systemAdmin = false;
				
				if (objectType == 'Task' && taskResourceType != 'VoiceMail'){
					allowedToViewRecordings = false;
				}else{
					allowedToViewRecordings = true;
				}
			} else if(currentUser.Profile.Name == 'System Administrator') {
				allowedToViewRecordings = true;
				systemAdmin = true;
			} else {
				allowedToViewRecordings = false;
				systemAdmin = false;
			}
		} else {
			// Group owned?
			allowedToViewRecordings = false;
		}
	}

	public static Map<Id, User> getUserRecord(List<Id> userIdSet) {
		if(userIdSet == null || userIdSet.isEmpty()) {
			return null;
		}

		Map<Id, User> currentUserMap;
		try {
			currentUserMap = new Map<Id, User>([SELECT Id, Name, Manager.Id, Profile.Name FROM User WHERE Id IN :userIdSet]);
		} catch(DmlException e) {
			// User does not exist in the system or bad Id sent
			currentUserMap = null;
		}

		return currentUserMap;
	}
}
public without sharing class LocalSalesRepTeamAssignmentController {
	public List<User> salesRepList {get; set;}

	public LocalSalesRepTeamAssignmentController() {
		salesRepList = [select Id, FirstName, LastName, ManagerId, ARR__c, RSR__c, Strategy_Specialist__c, Print_Specialist__c, SOR__c from User where UserRole.Name like '%Local Core Account Executive%' and IsActive = true order by FirstName];
	}

	public void saveSalesRepRecord(){
		Map<Id, User> oldValue = new Map<Id, User>();
		for(User record : [select Id, FirstName, LastName, ManagerId, ARR__c, RSR__c, Strategy_Specialist__c, Print_Specialist__c, SOR__c from User where UserRole.Name like '%Local Core Account Executive%' and IsActive = true order by FirstName]){
			oldValue.put(record.Id, record);
		}

		List<User> updateUserList = new List<User>();
		for(User record : salesRepList){
			if(record.ManagerId != oldValue.get(record.Id).ManagerId || record.ARR__c != oldValue.get(record.Id).ARR__c || record.RSR__c != oldValue.get(record.Id).RSR__c || record.Strategy_Specialist__c != oldValue.get(record.Id).Strategy_Specialist__c || record.Print_Specialist__c != oldValue.get(record.Id).Print_Specialist__c || record.SOR__c != oldValue.get(record.Id).SOR__c){
				updateUserList.add(record);
			}
		}

		update updateUserList;

		salesRepList = [select Id, FirstName, LastName, ManagerId, ARR__c, RSR__c, Strategy_Specialist__c, Print_Specialist__c, SOR__c from User where UserRole.Name like '%Local Core Account Executive%' and IsActive = true order by FirstName];
	}
}
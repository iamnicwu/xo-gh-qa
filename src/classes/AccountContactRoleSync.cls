global class AccountContactRoleSync  implements Database.batchable<sObject>{
	Date dt = System.today();
	String dateTimeStr = DateTime.newInstance(2016,7,28).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
	String query;
	String role;
	
	global AccountContactRoleSync(Date dateNew,String roleNew){
		Time timeNew = Time.newInstance(0, 0, 0, 0);
		role = roleNew;
		dateTimeStr = DateTime.newInstance(dateNew, timeNew).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
	}
	
	global Database.QueryLocator start(Database.BatchableContext context){
		query = 'SELECT id,isPrimary,role,contactId,AccountId from AccountContactRole where role=\''+role+ '\' and (CreatedDate >'+dateTimeStr+' OR LastModifiedDate >'+dateTimeStr+')';
		System.debug(query);
		return Database.getQueryLocator(query);
	}
	
    global void execute(Database.BatchableContext context, List<sObject> scope){
    	List<AccountContactRole> accountContactRoles = new List<AccountContactRole>();
    	List<Id> contactIdsList = new List<Id>();
    	List<Contact> contactList = new List<Contact>();    	
    	for(sobject s: scope){    		
    		AccountContactRole acr = (AccountContactRole)s;
    		contactIdsList.add(acr.ContactId);
    	}
    	if(contactIdsList.size() > 0){
	    	for(Contact con : [SELECT id,name,Primary__c from contact where id in : contactIdsList]){
	    	//Update Primary should go here	
				con.Primary__c = true;	
				contactList.add(con);
	    	}
		   try{ 	
	  			update contactList;
		   }catch(System.DmlException ex){
		   	throw ex;
		   }
    	}
    }
    
    global void finish(Database.BatchableContext context){
    }
}
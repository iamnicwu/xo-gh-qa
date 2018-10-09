global class LeadAccountAutoAssignBatch implements Database.Batchable<sObject> {
	
	// USED TO RE-ASSIGN LEAD OWNERS, ACCOUNT OWNERS, OR ACCOUNT METRO AREAS

	private String query;
	private String assign;
	private static Map<String, String> autoAssignMap;
	
	global LeadAccountAutoAssignBatch(String queryString, String assignType) {
		query = queryString;
		assign = assignType;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		if(assign == 'accountOwner'){
			accountAutoAssign(scope);
		}else if(assign == 'leadOwner'){
			leadAutoAssign(scope);
		}else if(assign == 'accountMetro'){
			assignMetro(scope);
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	private static void assignMetro(List<Account> scope){
		Map<String,ID> BillZipmap = new Map<String,ID>();
	    Set<String> BillZipCodeList = new Set<String>();
	    Map<String,ID> ShipZipmap = new Map<String,ID>();
	    Set<String> ShipZipCodeList = new Set<String>();

	    for(Account acc : scope){
		    if(String.isNotBlank(acc.ShippingPostalCode) && acc.ShippingCountryCode == 'US'){
	            ShipZipCodeList.add(acc.ShippingPostalCode.left(5));
	        }
	        if (String.isNotBlank(acc.BillingPostalCode) && acc.BillingCountryCode == 'US') {
	            BillZipCodeList.add(acc.BillingPostalCode.left(5));
	        }
	    }

	    if(ShipZipCodeList.size()>0 || BillZipCodeList.size()>0){
	        List<Zip__c> ShipZipList = new List<Zip__c>();
	        List<Zip__c> BillZipList = new List<Zip__c>();
	        if (ShipZipCodeList.size()>0) {
	            ShipZipList = [select ID,ZipCode__c,MetroArea__c from Zip__c where ZipCode__c in :ShipZipCodeList];
	        }
	        if(BillZipCodeList.size()>0) {
	            BillZipList = [select ID,ZipCode__c,MetroArea__c from Zip__c where ZipCode__c in :BillZipCodeList];
	            
	        }

	        if (ShipZipList.size()>0) {
	            for (Zip__c z : ShipZipList) {
	                ShipZipmap.put(z.ZipCode__c,z.ID);
	            }
	        }
	        if (BillZipList.size()>0) {
	            for (Zip__c z : BillZipList) {
	                BillZipmap.put(z.ZipCode__c,z.ID);
	            }
	            
	        }
	 
	        List<Account> updateList = new List<Account>();
        	List<String> allIdList = new List<String>();

	        for (Account acc : scope) {
	        
	            if (acc.ShippingPostalCode != null && ShipZipmap.containsKey(acc.ShippingPostalCode.left(5) )) {
	                acc.Zip__c = ShipZipmap.get(acc.ShippingPostalCode.left(5));
	                updateList.add(acc);
	                allIdList.add(acc.Id);
	            }else if(acc.BillingPostalCode != null && BillZipmap.containsKey(acc.BillingPostalCode.left(5))) {
	                acc.Zip__c = BillZipmap.get(acc.BillingPostalCode.left(5));
	                updateList.add(acc);
	                allIdList.add(acc.Id);
	            }else{
	                //acc.addError(errMessage); per Steve, we will not throw an error and create a report that shows all Accounts with blank Zips
	            }
	        }

	        List<Database.SaveResult> upResult = Database.update(updateList, false);

        	sendResultEmail(allIdList, upResult);
	    }
	}

	private static void accountAutoAssign(List<Account> scope){
		Set<String> zipSet = new Set<String>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<Id> marketIdSet = new Set<Id>();
        for(Account record : scope){
            if(String.isNotBlank(record.Local_Sales_Market__c)){
                marketIdSet.add(record.Local_Sales_Market__c);
            }
            if(String.isNotBlank(record.Primary_Category__c)){
                categoryIdSet.add(record.Primary_Category__c);
            }
            if(String.isNotBlank(record.ShippingPostalCode)){
                zipSet.add(record.ShippingPostalCode);
                if(record.ShippingPostalCode.length() > 5){
                    zipSet.add(record.ShippingPostalCode.left(5));
                }
            }
            if(String.isNotBlank(record.BillingPostalCode)){
                zipSet.add(record.BillingPostalCode);
                if(record.BillingPostalCode.length() > 5){
                    zipSet.add(record.BillingPostalCode.left(5));
                }
            }
        }

        autoAssignMap = new Map<String, String>();
        for(Local_Sales_Rep_Assignment__c record : [select Id, Zip_Code__r.ZipCode__c, Sales_Rep__c, Sales_Rep__r.Strategy_Specialist__c, 
                                                            Category__c, Market__c from Local_Sales_Rep_Assignment__c 
                                                            where Sales_Rep__c != null
                                                            AND ((Zip_Code__r.ZipCode__c IN: zipSet AND Category__c IN: categoryIdSet AND Market__c = null)
                                                                OR (Market__c IN: marketIdSet AND Category__c IN: categoryIdSet AND Zip_Code__c = null)
                                                                OR (Category__c IN: categoryIdSet AND Market__c = null and Zip_Code__c = null)
                                                                OR (Zip_Code__r.ZipCode__c IN: zipSet AND Category__c = null and Market__c = null)
                                                                OR (Market__c IN: marketIdSet AND Category__c = null and Zip_Code__c = null))]){
            if(record.Zip_Code__c != null && record.Category__c != null && record.Market__c == null){
                autoAssignMap.put(record.Zip_Code__r.ZipCode__c + record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c != null && record.Market__c != null){
                autoAssignMap.put(record.Market__c + '' + record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c != null && record.Market__c == null){
                autoAssignMap.put(record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c != null && record.Category__c == null && record.Market__c == null){
                autoAssignMap.put(record.Zip_Code__r.ZipCode__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c == null && record.Market__c != null){
                autoAssignMap.put(record.Market__c, record.Sales_Rep__c);
            }
        }

        List<Account> updateList = new List<Account>();
        List<String> allIdList = new List<String>();
        for(Account record : scope){
        	String ownerId = ownerMatch(record.Local_Sales_Market__c, record.Primary_Category__c, record.ShippingPostalCode, record.ShippingCountryCode, record.BillingPostalCode, record.BillingCountryCode);
        	if(String.isNotBlank(ownerId)){
        		record.OwnerId = ownerId;
        		updateList.add(record);
        		allIdList.add(record.Id);
        	}
        }

        List<Database.SaveResult> upResult = Database.update(updateList, false);

        sendResultEmail(allIdList, upResult);

        /*String header = 'Record Id, Success, Error Message \n';
        String finalStr = header;

        for(Database.SaveResult record : upResult){
        	if(record.isSuccess()){
        		finalStr += record.getId() + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}else{
        		finalStr += allIdList.get(0) + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}
        	allIdList.remove(0);
        }
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		blob csvBlob = Blob.valueOf(finalstr);
		string csvname= 'Results.csv';
		csvAttc.setFileName(csvname);
		csvAttc.setBody(csvBlob);

        Messaging.SingleEmailMessage sendResult = new Messaging.SingleEmailMessage();
        sendResult.setTargetObjectId(UserInfo.getUserId());
        sendResult.setSubject('Auto Assign Batch Result');
        sendResult.setPlainTextBody('');
        sendResult.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        sendResult.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { sendResult });*/
	}

	private static void leadAutoAssign(List<Lead> scope){
		Set<String> zipSet = new Set<String>();
        Set<Id> categoryIdSet = new Set<Id>();
        Set<Id> marketIdSet = new Set<Id>();
        for(Lead record : scope){
            if(String.isNotBlank(record.Local_Sales_Market__c)){
                marketIdSet.add(record.Local_Sales_Market__c);
            }
            if(String.isNotBlank(record.Primary_Category__c)){
                categoryIdSet.add(record.Primary_Category__c);
            }
            if(String.isNotBlank(record.PostalCode)){
                zipSet.add(record.PostalCode);
                if(record.PostalCode.length() > 5){
                    zipSet.add(record.PostalCode.left(5));
                }
            }
        }

        autoAssignMap = new Map<String, String>();
        for(Local_Sales_Rep_Assignment__c record : [select Id, Zip_Code__r.ZipCode__c, Sales_Rep__c, Sales_Rep__r.Strategy_Specialist__c, 
                                                            Category__c, Market__c from Local_Sales_Rep_Assignment__c 
                                                            where Sales_Rep__c != null
                                                            AND ((Zip_Code__r.ZipCode__c IN: zipSet AND Category__c IN: categoryIdSet AND Market__c = null)
                                                                OR (Market__c IN: marketIdSet AND Category__c IN: categoryIdSet AND Zip_Code__c = null)
                                                                OR (Category__c IN: categoryIdSet AND Market__c = null and Zip_Code__c = null)
                                                                OR (Zip_Code__r.ZipCode__c IN: zipSet AND Category__c = null and Market__c = null)
                                                                OR (Market__c IN: marketIdSet AND Category__c = null and Zip_Code__c = null))]){
            if(record.Zip_Code__c != null && record.Category__c != null && record.Market__c == null){
                autoAssignMap.put(record.Zip_Code__r.ZipCode__c + record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c != null && record.Market__c != null){
                autoAssignMap.put(record.Market__c + '' + record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c != null && record.Market__c == null){
                autoAssignMap.put(record.Category__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c != null && record.Category__c == null && record.Market__c == null){
                autoAssignMap.put(record.Zip_Code__r.ZipCode__c, record.Sales_Rep__c);
            }else if(record.Zip_Code__c == null && record.Category__c == null && record.Market__c != null){
                autoAssignMap.put(record.Market__c, record.Sales_Rep__c);
            }
        }

        List<Lead> updateList = new List<Lead>();
        List<String> allIdList = new List<String>();
        for(Lead record : scope){
        	String ownerId = ownerMatch(record.Local_Sales_Market__c, record.Primary_Category__c, record.PostalCode, record.CountryCode, null, null);
        	if(String.isNotBlank(ownerId)){
        		record.OwnerId = ownerId;
        		updateList.add(record);
        		allIdList.add(record.Id);
        	}
        }

        List<Database.SaveResult> upResult = Database.update(updateList, false);

        sendResultEmail(allIdList, upResult);

        /*String header = 'Record Id, Success, Error Message \n';
        String finalStr = header;

        for(Database.SaveResult record : upResult){
        	if(record.isSuccess()){
        		finalStr += record.getId() + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}else{
        		finalStr += allIdList.get(0) + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}
        	allIdList.remove(0);
        }
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		blob csvBlob = Blob.valueOf(finalstr);
		string csvname= 'Results.csv';
		csvAttc.setFileName(csvname);
		csvAttc.setBody(csvBlob);

        Messaging.SingleEmailMessage sendResult = new Messaging.SingleEmailMessage();
        sendResult.setTargetObjectId(UserInfo.getUserId());
        sendResult.setSubject('Auto Assign Batch Result');
        sendResult.setPlainTextBody('');
        sendResult.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        sendResult.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { sendResult });*/

	}

	private static String ownerMatch(String mkt, String cat, String zip1, String country1, String zip2, String country2){
		String ownId = '';
		if(String.isNotBlank(cat) && String.isNotBlank(zip1) && autoAssignMap.containsKey(zip1 + cat)){
            ownId = autoAssignMap.get(zip1 + cat);
        }else if(String.isNotBlank(cat) && String.isNotBlank(zip1) && country1 == 'US' && zip1.length() > 5 && autoAssignMap.containsKey(zip1.left(5) + cat)){
            ownId = autoAssignMap.get(zip1.left(5) + cat);
        }else if(String.isNotBlank(cat) && String.isNotBlank(zip2) && autoAssignMap.containsKey(zip2 + cat)){
            ownId = autoAssignMap.get(zip2 + cat);
        }else if(String.isNotBlank(cat) && String.isNotBlank(zip2) && country2 == 'US' && zip2.length() > 5 && autoAssignMap.containsKey(zip2.left(5) + cat)){
            ownId = autoAssignMap.get(zip2.left(5) + cat);
        }else if(String.isNotBlank(cat) && String.isNotBlank(mkt) && autoAssignMap.containsKey(mkt + '' + cat)){
            ownId = autoAssignMap.get(mkt + '' + cat);
        }else if(String.isNotBlank(cat) && autoAssignMap.containsKey(cat)){
            ownId = autoAssignMap.get(cat);
        }else if(String.isNotBlank(zip1) && autoAssignMap.containsKey(zip1)){
            ownId = autoAssignMap.get(zip1);
        }else if(String.isNotBlank(zip1) && country1 == 'US' && zip1.length() > 5 && autoAssignMap.containsKey(zip1.left(5))){
            ownId = autoAssignMap.get(zip1.left(5));
        }else if(String.isNotBlank(zip2) && autoAssignMap.containsKey(zip2)){
            ownId = autoAssignMap.get(zip2);
        }else if(String.isNotBlank(zip2) && country2 == 'US' && zip2.length() > 5 && autoAssignMap.containsKey(zip2.left(5))){
            ownId = autoAssignMap.get(zip2.left(5));
        }else if(String.isNotBlank(mkt) && autoAssignMap.containsKey(mkt)){
            ownId = autoAssignMap.get(mkt);
        }

		return ownId;
	}

	private static void sendResultEmail(List<String> allIdList, List<Database.SaveResult> upResult){
		String header = 'Record Id, Success, Error Message \n';
        String finalStr = header;

        for(Database.SaveResult record : upResult){
        	if(record.isSuccess()){
        		finalStr += record.getId() + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}else{
        		finalStr += allIdList.get(0) + ',' + record.isSuccess() + ',' + record.getErrors() + '\n';
        	}
        	allIdList.remove(0);
        }
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
		blob csvBlob = Blob.valueOf(finalstr);
		string csvname= 'Results.csv';
		csvAttc.setFileName(csvname);
		csvAttc.setBody(csvBlob);

        Messaging.SingleEmailMessage sendResult = new Messaging.SingleEmailMessage();
        sendResult.setTargetObjectId(UserInfo.getUserId());
        sendResult.setSubject('Auto Assign Batch Result');
        sendResult.setPlainTextBody('');
        sendResult.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        sendResult.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { sendResult });
	}
	
}
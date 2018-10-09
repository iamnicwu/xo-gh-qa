/* 
<class>
  <name>SubscriptionCreatorQueuedJob</name>
  <purpose>For recording which Salesforce user created a Zuora Subscription</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/27/2015</date>
    <ticket>SF-602</ticket>
  </created>
</class>
*/
public class SubscriptionCreatorQueuedJob implements Queueable, Database.AllowsCallouts {
    /* 
    <method>
      <name>execute</name>
      <purpose>The "execute" method is used in Queueable jobs to run logic</purpose>
	  <created>
	    <by>Jonathan Satterfield</by>
	    <date>7/27/2015</date>
	    <ticket>SF-602</ticket>
	  </created>
    </method>
    */    
    public void execute(QueueableContext context) {
        List<Zuora__Subscription__c> subList = [SELECT Id, Name, Zuora__Zuora_Id__c, Product_Line__c, NeedToUpdateSubscriptionCreator__c, OriginalSalesforceQuoteID__c, CreatingSalesforceQuoteID__c, SubscriptionCreator__c, SubscriptionCreatorSalesforceID__c, Zuora__Version__c FROM Zuora__Subscription__c WHERE NeedToUpdateSubscriptionCreator__c = True AND OriginalSalesforceQuoteID__c != '' AND Product_Line__c != '' LIMIT 50];
		if (!subList.isEmpty()) {
		    String createdInZuoraString = 'Created in Zuora';
		    String createdInZuoraId = 'N/A';
		    Map<String,Zuora__Subscription__c> subMap = new Map<String,Zuora__Subscription__c>();
		    Set<String> subNameSet = new Set<String>();
		    Set<Id> originalQuoteIdSet = new Set<Id>();
		    
		    // populate this map to use later when linking NEW Quotes with Subscriptions
		    Map<String,String> quoteIdToSubscriptionNameMap = new Map<String,String>();
		    for (Zuora__Subscription__c sub : subList) {
		        // if this is the original version of a Subscription and it was generated from Zuora,
		        // set the fields below to note that it was created in Zuora
		        if ((sub.OriginalSalesforceQuoteID__c == '' || sub.OriginalSalesforceQuoteID__c == null) && sub.Zuora__Version__c == 1) {
		            sub.SubscriptionCreator__c = 'Created in Zuora';
		            sub.SubscriptionCreatorSalesforceID__c = createdInZuoraId;
		        }
		        // if this is the original version of a Subscription and it was generated from Salesforce (Zuora Quotes),
		        // set the fields below to note that it was created in Salesforce
		        else if (sub.Zuora__Version__c == 1) {
		            originalQuoteIdSet.add((Id)sub.OriginalSalesforceQuoteID__c);
		            quoteIdToSubscriptionNameMap.put(sub.OriginalSalesforceQuoteID__c,sub.Name);
		            subMap.put(sub.Name+'Version'+String.valueOf(sub.Zuora__Version__c),sub);
		        }
		        // if this isn't the original version of a Subscription, also set the fields below
		        else {
		            subMap.put(sub.Name+'Version'+String.valueOf(sub.Zuora__Version__c),sub);
		            subNameSet.add(sub.Name);
		            
		        }
		    }
		    
		    
		    if (!subMap.isEmpty()) {
		        Map<String,zqu__Quote__c> subscriptionNameAndVersionToQuoteMap = new Map<String,zqu__Quote__c>();
		        List<zqu__Quote__c> quoteList = [SELECT Id, CreatedBy.Name, CreatedById, NumberOfQuoteAmendmentRecords__c, zqu__SubscriptionVersion__c, zqu__Subscription_Name__c FROM zqu__Quote__c WHERE zqu__Subscription_Name__c IN :subNameSet OR Id IN :originalQuoteIdSet];
		        for (zqu__Quote__c q : quoteList) {
						            
		            // If it's a NEW Quote (aka not an Amendment) then SubscriptionName and SubscriptionVersion
		            // won't have values. In order to map the Subscription to the Quote we need to get the 
		            // SubscriptionName from the quoteIdToSubscriptionNameMap we populated above; SubscriptionVersion
		            // will be 1
		            if ((q.zqu__Subscription_Name__c == '' || q.zqu__Subscription_Name__c == null) && q.zqu__SubscriptionVersion__c == null) {
		                String subName = quoteIdToSubscriptionNameMap.get((String)q.Id);
		                subName = subName + 'Version1';
		                subscriptionNameAndVersionToQuoteMap.put(subName,q);
		            }
		            else {
		                // Quote Version has to have 1 added to it in order to properly sync with Subscription Version
		                //subscriptionNameAndVersionToQuoteMap.put(q.zqu__Subscription_Name__c+'Version'+String.valueOf(q.zqu__SubscriptionVersion__c+1),q);
		            
		                // JPS NOTE 8-28-15: I found a problem with how Subscription "Version" is numbered in the case of an
		                // Amendment Quote. Instead of adding 1 to the Quote Version, we need to add the number of Quote Amendment records
		                // associated to the Quote record -- we accomplish this through the zqu__Quote__c.NumberOfQuoteAmendmentRecords__c
		                // count rollup summary field.
		                subscriptionNameAndVersionToQuoteMap.put(q.zqu__Subscription_Name__c+'Version'+String.valueOf(q.zqu__SubscriptionVersion__c+q.NumberOfQuoteAmendmentRecords__c),q);
		            }
		            
		        }
		        
		        for (String subName : subMap.keySet()) {
		            Zuora__Subscription__c zSub = subMap.get(subName);
		            zqu__Quote__c tempQuote = subscriptionNameAndVersionToQuoteMap.get(subName);
		            // if tempQuote is equal to null then the Subscription originated in Zuora
		            if (tempQuote != null) {
		                zSub.SubscriptionCreator__c = tempQuote.CreatedBy.Name;
		                zSub.SubscriptionCreatorSalesforceID__c = tempQuote.CreatedById;
		                zSub.CreatingSalesforceQuoteID__c = tempQuote.Id;
		            }
		            else {
		                zSub.SubscriptionCreator__c = 'Created in Zuora';
		                zSub.SubscriptionCreatorSalesforceID__c = createdInZuoraId;
		                zSub.CreatingSalesforceQuoteID__c = createdInZuoraId;
		            }
		        }
		    }
		    
		    // Do API callouts and, if successful, add the Subscription record to a list to update
		    // then update the subList
		    List<Zuora__Subscription__c> zuoraSubUpdateList = new List<Zuora__Subscription__c>();
		    
		    Zuora.ZApi zApiInstance = new Zuora.ZApi();
		    // skip the login call if this is a test
		    if (!Test.isRunningTest()) {
		    	Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
		    }
		    for (Zuora__Subscription__c zuoraSub : subList) {
		        try {
		            Zuora.zObject sub = new Zuora.zObject('Subscription');
		            sub.setValue('Id',zuoraSub.Zuora__Zuora_Id__c); //an existing account
		            //acc.setValue('Id','fake_id'); // test: make callout fail
		            sub.setValue('SubscriptionCreator__c',zuoraSub.SubscriptionCreator__c);
		            sub.setValue('SubscriptionCreatorSalesforceID__c',zuoraSub.SubscriptionCreatorSalesforceID__c);
		            sub.setValue('CreatingSalesforceQuoteID__c',zuoraSub.CreatingSalesforceQuoteID__c);
		            
		            if (String.isBlank(zuoraSub.Product_Line__c)) {
		            	System.debug('EMPTY PRODUCT LINE SUB ID');
		            	System.debug(zuoraSub.Id);
		            	//sub.setValue('Product_Line__c','Internet');
		            }
		            else {
		            	sub.setValue('Product_Line__c',zuoraSub.Product_Line__c);
		            }

		            List<Zuora.zObject> objs = new List<Zuora.zObject> {sub};
		            List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();

		            if (!Test.isRunningTest()) {
		            	results.addAll(zApiInstance.zupdate(objs));
		            }

		            if (Test.isRunningTest()) {
		            	// test Sucess
		            	Zuora.zApi.SaveResult testSuccessSalesResult = new Zuora.zApi.SaveResult();
						testSuccessSalesResult.Success = True;
		            	results.add(testSuccessSalesResult);
		            	// test Failure
		            	Zuora.zApi.SaveResult testFailSalesResult = new Zuora.zApi.SaveResult();
						testFailSalesResult.Success = False;
		            	results.add(testSuccessSalesResult);
		            }
		            
		            for (Zuora.zApi.SaveResult result : results) {
		                if (result.Success){
		                    // if success, clear the "need to update" flag on the Subscription,
		                    // then add the Subscription to the zuoraSubUpdateList
		                    zuoraSub.NeedToUpdateSubscriptionCreator__c = False;
		                    zuoraSubUpdateList.add(zuoraSub);
		                } 
		                else {
		                    //failure, get the errors
		                    
		                    System.debug('CALLOUT FAILED');
		                    Zuora.zObject[] errors = result.errors;
		                    for (Zuora.zObject error : errors) {
		                        String errorCode = (String)error.getValue('Code');
		                        String message = (String)error.getValue('Message');
		                        System.debug(errorCode + ' ' + message);
		                    }
		                    
		                }
		            }
		        }
		        catch (Exception e) {
		            // don't do anything
		        }
		    }
		    update zuoraSubUpdateList;		
		}
    }
}
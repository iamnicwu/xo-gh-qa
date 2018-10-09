trigger AccountSyncContactAddress on Account (after update) {
    // List<Contact> relatedContacts = new List<Contact>();
    // Map<Id, Account> affectedAccounts = new Map<Id, Account>();
    
    // for (Account a : Trigger.New)
    // {
    //     Account oldA = (Account)trigger.oldMap.get(a.Id);
    //     if (   a.BillingStreet != oldA.BillingStreet
    //         || a.BillingCity != oldA.BillingCity
    //         || a.BillingState != oldA.BillingState
    //         || a.BillingPostalCode != oldA.BillingPostalCode
    //         || a.BillingCountry != oldA.BillingCountry)
    //     {
    //         affectedAccounts.put(a.Id,a);
    //         System.Debug('Affected account: ' + a.Id + ' ' + a.Name);
    //     }
    // }
    
    // System.Debug('# accounts affected: ' + affectedAccounts.size());
    // if (affectedAccounts.size() > 0)
    // {
    //     relatedContacts = [Select ID, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, AccountId 
    //                        from Contact 
    //                        where AccountId in :affectedAccounts.keySet() and Same_Address_as_Account__c = true];
        
    //     for (Contact c : relatedContacts)
    //     {
    //         Account a = affectedAccounts.get(c.AccountId);
    //         c.MailingStreet = a.BillingStreet;
    //         c.MailingCity = a.BillingCity;
    //         c.MailingState = a.BillingState;
    //         c.MailingPostalCode = a.BillingPostalCode;
    //         c.MailingCountry = a.BillingCountry;
    //     }
        
    //     update relatedContacts;         
    // }
}
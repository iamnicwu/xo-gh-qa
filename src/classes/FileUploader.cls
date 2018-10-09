/*
Cliff had to delete several accounts which used to throw errors as accounts have quotes, quote rate plan charges, billing accounts, etc
associated with it which would prevent deletion.
This code first lets the user upload a csv file containing account ids. It first deletes child records and then deleted the account records.
Code only cares about the first column in the excel which should contain all the account ids.

ToDo:
- Refactoring code
- Error handling
- Documenting 
- Add new child objects to be deleted as reported by Cliff
*/

public class FileUploader 
{
    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    String[] filelines = new String[]{};
    List<Account> accstoupload;
    List<Account> accountsToBeDeleted;
    Set<Id> accountIdSet;
    Set<Id> billingAccountsIdSet;
    Set<Id> quoteRatePlanChargeIdSet;
    List<Zuora__CustomerAccount__c> customerAccountsToBeDeleted = new List<Zuora__CustomerAccount__c>();
    List<zqu__QuoteRatePlanCharge__c> quoteRatePlanChgsToBeDeleted = new List<zqu__QuoteRatePlanCharge__c>();
    List<Opportunity> opportunitiesToBeDeleted = new List<Opportunity>();
    List<zqu__Quote__c> quotesToBeDeleted = new List<zqu__Quote__c>();

    
    /***This function reads the CSV file and inserts records into the Account object. ***/
    public Pagereference ReadFile() {
        try{
            //Convert the uploaded file which is in BLOB format into a string
            nameFile =blobToString(contentFile,'ISO-8859-1'); 
            //Now sepatate every row of the excel file
            filelines = nameFile.split('\n');

            //Iterate through every line and create a Account record for each row
            accstoupload = new List<Account>();
            accountIdSet = new Set<Id>();

            system.debug('3333333 filelines ' + filelines);

            for (Integer i=1;i<filelines.size();i++) {
                String[] inputvalues = new String[]{};
                inputvalues = filelines[i].split(',');
                accountIdSet.add(Id.valueOf(inputvalues[0].replaceAll('\\s+', '')));
            }

            system.debug('3333333 accountIdSet ' + accountIdSet);

            if(!accountIdSet.isEmpty()) {
                deleteRecords(accountIdSet);
            }

         }
         catch(Exception e){
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured reading the CSV file'+e.getMessage());
            ApexPages.addMessage(errormsg);
         }       
        return null;
    }

    // this method currnet deleted billing accounts, quote rate plan charges, quotes, opportunities before deleting the accounts
    @future
    public static void deleteRecords(Set<ID> accountIdSet) { 
        
        system.debug('33333333 ' + accountIdSet);
        List<Zuora__CustomerAccount__c> customerAccountsToBeDeleted = [Select Id from Zuora__CustomerAccount__c where Zuora__Account__c IN: accountIdSet];
        List<zqu__QuoteRatePlanCharge__c> quoteRatePlanChgsToBeDeleted = [Select Id, Location_Vendor__c from zqu__QuoteRatePlanCharge__c where Location_Vendor__c IN: accountIdSet];
        List<Opportunity> opportunitiesToBeDeleted = [Select Id from Opportunity where AccountId IN: accountIdSet];
        List<zqu__Quote__c> quotesToBeDeleted = [Select Id from zqu__Quote__c where zqu__Account__c IN: accountIdSet];
        List<Account> accountsToBeDeleted = [Select Id from Account where Id IN: accountIdSet];

        try{
            if(!customerAccountsToBeDeleted.isEmpty()) {
                Database.delete(customerAccountsToBeDeleted, false);
            }
            if(!quoteRatePlanChgsToBeDeleted.isEmpty()) {
                Database.delete(quoteRatePlanChgsToBeDeleted, false);
            }
            if(!quotesToBeDeleted.isEmpty()) {
                Database.delete(quotesToBeDeleted, false);
            }
            if(!opportunitiesToBeDeleted.isEmpty()) {
                Database.delete(opportunitiesToBeDeleted, false);
            }
            if(!accountsToBeDeleted.isEmpty()) {
                Database.delete(accountsToBeDeleted, false);
            }
        } catch (Exception e) {
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Following errors were encountered: '+e.getMessage());
            ApexPages.addMessage(errormsg);
        }
    }
   
    /*
    This function converts the input CSV file in BLOB format into a string
    @param input:        Blob data representing correct string in @inCharset encoding
    @param inCharset:    encoding of the Blob data (for example 'ISO 8859-1')
    */
    public static String blobToString(Blob input, String inCharset){
        String hex = EncodingUtil.convertToHex(input);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), inCharset);
    }         
}
public class AccountStrategySpecialis{
    @future
    public static void createAccountStrategySpecialis(Set<Id> AccIds) {
        List<account> accList = [select id,OwnerId,Strategy_Specialist__c,Owner.Strategy_Specialist__c from Account where id in : AccIds];
        if(accList.size()>0){
            for(account acc: acclist){
                acc.Strategy_Specialist__c = acc.Owner.Strategy_Specialist__c;
            }
            update acclist;
        }
    }
    
}
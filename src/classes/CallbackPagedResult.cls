global class CallbackPagedResult {

    @AuraEnabled
    public Integer pageSize { get;set; }

    @AuraEnabled
    public Integer page { get;set; }

    @AuraEnabled
    public Integer recordCount { get;set; }

    @AuraEnabled
    public List<Callback__c> callbacks { get;set; }

}
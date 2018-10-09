public with sharing class RenewalDashboardController{
    public String ownershipScope{get;set;}//Renewal ship 
    public String subscriptionStatus{get;set;}// subscriptionStatus
    public String subscriptionProductLine{get;set;}// subscription product line
    public String subscriptionTermStatus{get;set;}// subscription Term Status
    public Date startDate{get;set;} //for show the date to page
    public Date endDate{get;set;} //for show the date to page

    public Integer listSize=100; //sets the page size or number of rows
    public Integer totalPage{get;set;}
    public Integer pageNumber{get;set;}
    public Boolean disablePrevious{get;set;}
    public Boolean disableNext{get;set;}
    public Boolean noResults{get;set;}
    public Boolean tooManyData{get;set;}
    public Boolean dateValidation{get;set;}
    /*public Boolean NoRenewalRep{get;set;}*/
    ///for sort
    public String keyWord{get;set;}// 
    public String columnName{get;set;}// 
    public String renewalRepName{get;set;}// 
    public String ascOrDesc{get;set;}// 
    public Map<String,sortData> sortMap{get;set;}

    // Add a Json string serialize from market map, key word is market ID, value is market name, 
    // this map is used for show the subscription product charge
    public String marketMapString{get;set;}

    // Add a Json string serialize from Category map, key word is Category ID, value is Category name, 
    // this map is used for show the subscription product charge
    public String categoryMapString{get;set;}

    // Siva Vankadaru 05/22/2018 added below line for 2690  -->
    public String vipCheckStatus{get;set;}


    public Opportunity opportunityInfos{    //Renewal Rep filter and Lost Reason picklist values
        get{
            if(opportunityInfos== null){
                opportunityInfos= new Opportunity();
            }
            return opportunityInfos;
        }
        set;
    }

    public zqu__Quote__c expiringDateQuote{    //Renewal Rep filter and Lost Reason picklist values
        get{
            if(expiringDateQuote== null){
                expiringDateQuote= new zqu__Quote__c();
            }
            return expiringDateQuote;
        }
        set;
    }

    public String subscriptionId{
        get;
        set{
            subscriptionId = value;
        }
    }

    public List<SELECTOption> getsubscriptionStatusList(){
        List<SELECTOption> options = new List<SELECTOption>();
        options.add(new SELECTOption('ALL','ALL'));
        options.add(new SELECTOption('Renewed','Renewed'));
        options.add(new SELECTOption('Removed','Removed'));
        options.add(new SELECTOption('Not Renewed','Not Renewed'));
        return options;
    }

    public List<SELECTOption> getsubscriptionProductLineList(){
        List<SELECTOption> options = new List<SELECTOption>();
        options.add(new SELECTOption('ALL','Internet + Print'));
        options.add(new SELECTOption('Internet','Internet'));
        options.add(new SELECTOption('Print','Print'));
        return options;
    }   

    public List<SELECTOption> getownershipScopeList(){
        List<SELECTOption> options = new List<SELECTOption>();
        /*options.add(new SELECTOption('',''));*/
        options.add(new SELECTOption('My subscriptions','My subscriptions'));
        options.add(new SELECTOption('My team\'s subscriptions','My team\'s subscriptions'));
        options.add(new SELECTOption('All subscriptions','All subscriptions'));
        return options;
    }

    public List<SELECTOption> getsubscriptionTermStatusList(){
        List<SELECTOption> options = new List<SELECTOption>();
        // The Label SubscriptionTermStatus is used for storing the filter value of Subscription Term Status.
        List<String> subscriptionTermStatusList = System.Label.SubscriptionTermStatus.split(',');
        if (!subscriptionTermStatusList.isEmpty()) {
            for (Integer i = 0; i< subscriptionTermStatusList.size() ; i++) {
                options.add(new SELECTOption(subscriptionTermStatusList[i],subscriptionTermStatusList[i]));
            }    
        }
        return options;
    }

    public List<SELECTOption> getvipCheckStatusList(){
        List<SELECTOption> options = new List<SELECTOption>();
        options.add(new SELECTOption('ALL','ALL'));
        options.add(new SELECTOption('VIP','VIP'));
        options.add(new SELECTOption('Non-VIP','Non-VIP'));
        return options;
    }

    public Map<String,List<SubsEntityWrapper>> subsMap{get;set;} //the subscription data
    public Map<String,SubsEntityWrapper> subsTotalMap{get;set;}  //  the total amount data


    public renewalDashboardController(){
    /*NoRenewalRep = false;*/
        subsMap= new Map<String,List<SubsEntityWrapper>>();
        subsTotalMap = new Map<String,SubsEntityWrapper>(); 
        columnName = 'TermEndDate';
        keyWord = '';
        sortMap = new Map<String,sortData>();
        tooManyData = false;
        if(subscriptionStatus == '' || subscriptionStatus == Null){
            subscriptionStatus = 'ALL';
        }       
        if(ownershipScope  == '' || ownershipScope  == Null){
            ownershipScope  = 'My subscriptions'; 
        }
        if(subscriptionTermStatus  == '' || subscriptionTermStatus  == Null){
            subscriptionTermStatus  = 'Include'; 
        }
        if(String.isBlank(subscriptionProductLine)){
            subscriptionProductLine = 'ALL';
        }       
        pageNumber = 1;
        opportunityInfos = new Opportunity();
        expiringDateQuote = new zqu__Quote__c();
        expiringDateQuote.zqu__StartDate__c = Date.today();//for the Expiring Start date
        expiringDateQuote.zqu__TermStartDate__c = Date.today().addmonths(1);//for the expiring End date

        // get all market and category, send to VF page with a JSON string
        List<Market__c> marketList = [SELECT
                                                                        Id, 
                                                                        Name, 
                                                                        Market_ID__c
                                                                    FROM 
                                                                        Market__c];

        List<Category__c> categoryList = [SELECT
                                                                                Id, 
                                                                                Name, 
                                                                                Taxonomy_ID__c
                                                                            FROM 
                                                                                Category__c];

        Map<String,String> marketMap = new Map<String,String>();
        Map<String,String> categoryMap = new Map<String,String>();
        for (Integer i = 0 ; i<marketList.size() ; i++) {
            marketMap.put(marketList[i].Market_ID__c,marketList[i].Name);
        }
        marketMapString = JSON.serialize(marketMap); 

        for (Integer i = 0 ; i<categoryList.size() ; i++) {
            categoryMap.put(categoryList[i].Taxonomy_ID__c,categoryList[i].Name);
        }
        categoryMapString = JSON.serialize(categoryMap); 

        buildExpiringSubsData();
    }


    public Void buildExpiringSubsData(){
        subsMap.clear();
        subsTotalMap.clear();
        dateValidation = false;

        String soql = 'SELECT '
                                            + 'Id, '
                                            + 'Name, '
                                            + 'Zuora__TermStartDate__c, '
                                            + 'Zuora__TermEndDate__c, '
                                            + 'Zuora__AutoRenew__c, '
                                            + 'AutoRenewal__c, '
                                            + 'Reporting_Rep__c, '
                                            + 'Zuora__TCV__c, '
                                            + 'Zuora__MRR__c, '
                                            + 'IncludeLess12Item__c, '
                                            + 'Zuora__Account__r.Name, '
                                            + 'Zuora__Account__r.Credit_Hold__c, '
                                            + 'Renewal_Rep__c, '
                                            + 'Renewal_Rep__r.name, '
                                            + 'Zuora__Account__r.VIP_Program__c ';

        String soqlFROMWHERE = 'FROM '
                                                            + 'zuora__Subscription__c '
                                                    + 'WHERE '
                                                            + 'Renewal_Rep__c != null '
                                                    + 'AND '
                                                            + 'Zuora__Status__c != \'Cancelled\'';

        // Siva Vankadaru 05/22/2018 added below 2 lines for 2690  -->
        If ( vipCheckStatus == 'VIP' ){
            soqlFROMWHERE = soqlFROMWHERE + ' AND Zuora__Account__r.VIP_Program__c = True ';
        }
        else if ( vipCheckStatus == 'Non-VIP' ){
            soqlFROMWHERE = soqlFROMWHERE + ' AND Zuora__Account__r.VIP_Program__c = False ';
        }
        else {
            soqlFROMWHERE = soqlFROMWHERE ;
        }
        // Siva Vankadaru 05/22/2018 added above 2 lines for 2690  -->

        // Start filter statement of expiration date
        startDate = expiringDateQuote.zqu__StartDate__c;
        endDate = expiringDateQuote.zqu__TermStartDate__c;

        soqlFROMWHERE += 'AND '
                                            + 'Zuora__TermEndDate__c >=: startDate '
                                    + 'AND '
                                            + 'Zuora__TermEndDate__c <= :endDate ';
        // End filter statement of expiration date

        // Start filter statement of Renewal_Rep
        set<id> renewalRepList = new set<id>();
        if(expiringDateQuote.RenewalRepLookup__c == null){
            if(ownershipScope  == 'My subscriptions'){
                renewalRepList.add(userInfo.getUserId());
            }else if(ownershipScope  == 'My team\'s subscriptions'){
                renewalRepList.add(userInfo.getUserId());
                list<user> hierarchyIdlist = new List<user>();
                set<id> managerIdlist = new set<Id>();
                managerIdlist.add(userInfo.getUserId());
                Integer count = 0;
                //use do{}while() to search all the subordinate for the current user. 
                //And the count is used for prevent to query too many times. 
                do{
                    hierarchyIdlist.clear();
                    hierarchyIdlist = [SELECT Id FROM User WHERE ManagerId in : managerIdlist];
                    managerIdlist.clear();
                    if(!hierarchyIdlist.isEmpty()){
                        for(User user:hierarchyIdlist){
                            renewalRepList.add(user.Id);
                            managerIdlist.add(user.Id);
                        }
                    }
                    count++;
                }while(!hierarchyIdlist.isEmpty() && count<5);

            }else if(ownershipScope == 'All subscriptions'){

            }
        }else{
            renewalRepList.add(expiringDateQuote.RenewalRepLookup__c);
        }

        if(renewalRepList.size()>0){
            soqlFROMWHERE += 'AND '
                                                    + 'Renewal_Rep__c in: renewalRepList ';
        }
        // End filter statement of Renewal_Rep


        // Start filter statement of subscriptionStatus///////////////////////////////////////////
        List<Opportunity> renewalOppList = new List<Opportunity>();
        List<Opportunity> removeOppList = new List<Opportunity>();
        List<zqu__Quote__c> renewalQuoteList = new List<zqu__Quote__c>();
        renewalOppList = [SELECT Id, 
                                                Renew_Subscription__c, 
                                                Renew_Subscription__r.Name, 
                                                StageName
                                            FROM 
                                                Opportunity 
                                            WHERE 
                                                Type = 'Renewal'  
                                            AND 
                                                StageName != 'Closed Lost'  
                                            AND 
                                                Renew_Subscription__r.Zuora__TermEndDate__c >=: startDate 
                                            AND 
                                                Renew_Subscription__r.Zuora__TermEndDate__c <=: endDate ];

        removeOppList = [SELECT 
                                            Id, 
                                            Renew_Subscription__c, 
                                            StageName, 
                                            Renew_Subscription__r.Name 
                                        FROM 
                                            Opportunity 
                                        WHERE 
                                            Type = 'Renewal'  
                                        AND 
                                            StageName = 'Closed Lost'  
                                        AND 
                                            Renew_Subscription__r.Zuora__TermEndDate__c >=: startDate 
                                        AND 
                                            Renew_Subscription__r.Zuora__TermEndDate__c <=: endDate ];

        renewalQuoteList = [SELECT 
                                                    Id, 
                                                    zqu__Subscription_Name__c, 
                                                    zqu__Opportunity__c, 
                                                    zqu__Opportunity__r.Name, 
                                                    zqu__Opportunity__r.StageName
                                                FROM 
                                                    zqu__Quote__c  
                                                WHERE 
                                                    zqu__SubscriptionType__c = 'Renew Subscription' ];

        // for current system, a quote which was renewed for a subscription, there is only a name related to the renewal
        //  subscription.so we should use the name as a key word.
        Map<String,Opportunity> removeOppMap = new Map<String,Opportunity>();
        Map<String,Opportunity> renewalOppMap = new Map<String,Opportunity>();
        Map<String,zqu__Quote__c> renewalQuoteMap = new Map<String,zqu__Quote__c>();
        //The list used for store the Opp StageName and Opp Id, for the ticket CSP-1837
        Map<String,List<String>> oppStageNameMap = new Map<String,List<String>>();

        for (Opportunity record : renewalOppList) {
            if (!renewalOppMap.containsKey(record.Renew_Subscription__r.Name )) {
                renewalOppMap.put(record.Renew_Subscription__r.Name,record);
                //the Id used for redirect to opp pagelayout when user click the Opp Stage in the renewal queue
                List<String> oppStringlist = new List<String>();
                oppStringlist.add(record.StageName);
                oppStringlist.add(String.valueOf(record.Id));
                oppStageNameMap.put(record.Renew_Subscription__r.Name, oppStringlist);
            }               
        }  

        for (zqu__Quote__c record : renewalQuoteList) {
            if (!renewalQuoteMap.containsKey(record.zqu__Subscription_Name__c)) {
                renewalQuoteMap.put(record.zqu__Subscription_Name__c,record);

                List<String> oppStringlist = new List<String>();
                oppStringlist.add(record.zqu__Opportunity__r.StageName);
                oppStringlist.add(String.valueOf(record.zqu__Opportunity__c));
                oppStageNameMap.put(record.zqu__Subscription_Name__c, oppStringlist);
            }               
        }  

        // If a subscription have a renewal OPP or renewal Quote, it is renewed even though it have a removed OPP.
        for (Opportunity record : removeOppList) {
            if (!removeOppMap.containsKey(record.Renew_Subscription__r.Name) 
                    && !renewalOppMap.containsKey(record.Renew_Subscription__r.Name) 
                    && !renewalQuoteMap.containsKey(record.Renew_Subscription__r.Name)) {

                
                removeOppMap.put(record.Renew_Subscription__r.Name,record);

                List<String> oppStringlist = new List<String>();
                oppStringlist.add(record.StageName);
                oppStringlist.add(String.valueOf(record.Id));
                oppStageNameMap.put(record.Renew_Subscription__r.Name, oppStringlist);
            }               
        }  

        Set<String> subNameSet = new Set<String>();
        if (subscriptionStatus == 'ALL') {

        }else if (subscriptionStatus == 'Renewed') {
            subNameSet.addAll(renewalQuoteMap.keySet());
            subNameSet.addAll(renewalOppMap.keySet());
            soqlFROMWHERE += ' AND Name in: subNameSet ';
        }else if (subscriptionStatus == 'Removed') {
            subNameSet.addAll(removeOppMap.keySet());
            soqlFROMWHERE += ' AND Name in: subNameSet ';
        }else if(subscriptionStatus == 'Not Renewed'){
            subNameSet.addAll(renewalQuoteMap.keySet());
            subNameSet.addAll(renewalOppMap.keySet());
            soqlFROMWHERE += ' AND Name Not in: subNameSet ';
        }
        //CSP-1838
        if (subscriptionTermStatus == 'Without services less than 12 months') {
            soqlFROMWHERE += ' AND IncludeLess12Item__c = FALSE ';
        }else if (subscriptionTermStatus == 'Services less than 12 months' ) {
            soqlFROMWHERE += ' AND IncludeLess12Item__c = TRUE ';
        }else if (subscriptionTermStatus == 'All service periods' ) {

        }
        // CSP-2022 | Product Line filter (by default exclude Direct Mail)
        if (subscriptionProductLine == 'ALL') {
            soqlFROMWHERE += ' AND Product_Line__c != \'Direct Mail\' ';
        } else {
            soqlFROMWHERE += ' AND Product_Line__c = \'' + subscriptionProductLine + '\' ';
        }
        // End filter statement of subscriptionStatus///////////////////////////////////////////

        // start the query statement of calculate the TCV
        String totalQuery = 'SELECT '
                                                    + 'count(id) num, '
                                                    + 'Renewal_Rep__r.Name RenewalRep, '
                                                    + 'sum(Zuora__TCV__c) TCVtotal ';
        totalQuery += soqlFROMWHERE;
        totalQuery += 'group by Renewal_Rep__r.name ';
        // end the query statement of calculate the TCV

        soqlFROMWHERE += 'order by Renewal_Rep__r.name asc, Zuora__TermEndDate__c asc, Zuora__Account__r.Name asc limit 20000 ';    
        soql += soqlFROMWHERE;

        Integer limitLeft = limits.getLimitQueryRows()-limits.getQueryRows();
        if (limitLeft <= 40000) {
            tooManyData = TRUE;
            noResults = false;
        }else {

            system.debug(' soql : ' + soql);

            List<zuora__Subscription__c> subscriptionsList = Database.query(soql); 

            if (!subscriptionsList.isEmpty() && subscriptionsList.size()>=20000) {
                tooManyData = TRUE;
                noResults = false;
            }else{
                tooManyData = FALSE;

                // start calculate the TCV
                List<AggregateResult> agglist = Database.query(totalQuery);
                for(AggregateResult agg: agglist)
                {
                    SubsEntityWrapper subtotal = new SubsEntityWrapper();
                    subtotal.totalRenewal = Decimal.valueOf(String.valueOf(agg.get('TCVtotal'))).setscale(2);
                    subtotal.recordNum = Integer.valueOf(agg.get('num')) ;
                    subsTotalMap.put(string.valueOf(agg.get('RenewalRep')),subtotal);     
                }
                // end calculate the TCV

                if(subscriptionsList.isEmpty()){
                    totalPage = 0;
                    pageNumber = 0;
                    disableNext = true;
                    disablePrevious = True;
                    noResults = True;
                }else{
                    noResults = False;
                    integer PageSize; 
                    if(pageNumber * listSize-1 > subscriptionsList.size()){
                        PageSize = subscriptionsList.size();
                    }else{
                        PageSize = pageNumber * listSize-1;
                    }

                    if (math.mod(subscriptionsList.size(), listSize) > 0) {
                        totalPage = subscriptionsList.size()/listSize + 1;
                    } else {
                        totalPage = subscriptionsList.size()/listSize;
                    }
                    if(totalPage == pageNumber){
                        disableNext = true;
                    }else{
                        disableNext = false;
                    }
                    if(pageNumber == 1){
                        disablePrevious = true;
                    }else{
                        disablePrevious = false;
                    }

                    // this loop used for grabbing the items which fit onto this page. 
                    // the reason for those code is prevent to over the limit of 135k page view state
                    for(integer i = (pageNumber-1)*listSize; i< PageSize ; i++){                    
                        SubsEntityWrapper se = new SubsEntityWrapper();
                        se.zSub = subscriptionsList[i];
                        // If a subscription had a renewal Opp or Quote, disabled the renew button
                        if(renewalQuoteMap.containsKey(subscriptionsList[i].Name) || renewalOppMap.containsKey(subscriptionsList[i].Name)){
                            se.showRenewalButton = true;
                        }else{
                            se.showRenewalButton = false; 
                        }
                        // If a subscription had a remove Opp or Quote, disabled the remove button
                        if (removeOppMap.containsKey(subscriptionsList[i].Name)) {
                            se.showRemoveButton = true;
                        }else{
                            se.showRemoveButton = FALSE;
                        }
                        if(!oppStageNameMap.isEmpty() && oppStageNameMap.containsKey(subscriptionsList[i].Name)){
                            se.oppStageName  = oppStageNameMap.get(subscriptionsList[i].Name)[0];
                            se.oppId = (ID)oppStageNameMap.get(subscriptionsList[i].Name)[1];
                            if (se.oppStageName == 'Closed Won' || se.oppStageName == 'Client Approved' ) {
                                se.showRemoveButton = true;
                            }
                        }

                        if(subsMap.containsKey(subscriptionsList[i].Renewal_Rep__r.name)){
                            subsMap.get(subscriptionsList[i].Renewal_Rep__r.name).add(se);
                        }else{
                            list<SubsEntityWrapper> selist = new list<SubsEntityWrapper>();
                            selist.add(se);
                            subsMap.put(subscriptionsList[i].Renewal_Rep__r.name,selist);
                            sortMap.put(subscriptionsList[i].Renewal_Rep__r.name,new sortData('TermEndDate','ASC'));
                        }  
                    }
                } 
            }
        }
    }

    public PageReference goSearch()
    {
        Date startDateValidate = expiringDateQuote.zqu__StartDate__c;
        Date endDateValidate = expiringDateQuote.zqu__TermStartDate__c;
        if (startDateValidate >= endDateValidate) {
            dateValidation = true;
            tooManyData = false;
            noResults = false;
            subsMap.clear();
            totalPage = 0;
            pageNumber = 0;
            return null;
        }else{
            subsMap.clear();
            pageNumber = 1;
            buildExpiringSubsData();
            return null;
        }
    }


    public PageReference Beginning() { //user clicked beginning
        pageNumber = 1;
        buildExpiringSubsData();
        return null;
    }

    public PageReference Previous() { //user clicked previous button
        pageNumber -= 1;
        buildExpiringSubsData();
        return null;
    }

    public PageReference Next() { //user clicked next button
        pageNumber += 1;
        buildExpiringSubsData();
        return null;
    }

    public PageReference End() { //user clicked end
        pageNumber = totalPage;
        buildExpiringSubsData();
        return null;
    }



    public PageReference GoRenew(){

        // Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        // List<zuora__Subscription__c> ZsList = [SELECT id,name,Zuora__Account__c FROM zuora__Subscription__c WHERE id = : subscriptionId];

        // String OppKeyPrefix = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getKeyPrefix();
        // PageReference pr = new PageReference('/' + OppKeyPrefix + '/e?nooverride=1');
        // String html;
        // //Blob pageContent = pr.getContent();
        // Blob pageContent ;
        // if (Test.IsRunningTest())
        // {
        //  pageContent =Blob.valueOf('UNIT.TEST');
        // }else{
        //  pageContent =pr.getContent();
        // }

        // if ( pageContent != null ) {
        //  html = pageContent.toString();
        // }
        // Matcher macher = Pattern.compile('<label for="(.*?)">(<span class="requiredMark">\\*</span>)?(.*?)</label>').matcher(html);
        // String LabelName = 'Renew Subscription';
        // String fieldid;
        // while ( macher.find() ) {
        //  String label = macher.group(3);
        //  String fldId = macher.group(1);
        //  if(macher.group(3) == LabelName){
        //      fieldid =  macher.group(1);       
        //  }
        // }

        // pageReference retVal = new pageReference('/'+OppKeyPrefix + '/e?opp5=renewal&'+fieldid+'_lkid='+ZsList[0].Id+'&'+fieldid+'='+ZsList[0].name+'&accid='+ZsList[0].Zuora__Account__c+'&RecordType='+rtOppMapByName.get('Local').getRecordTypeId());  
        // retVal.setredirect(true);   
        // return retVal;
        // update for ticket CSP-1837, created a new Opp when user click the button "Renew" and refresh the dataPanel.
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        //List<zuora__Subscription__c> ZsList = [SELECT 
        //                                                                                  Id, 
        //                                                                                  Name, 
        //                                                                                  Zuora__Account__c, 
        //                                                                                  Zuora__Zuora_Id__c 
        //                                                                          FROM 
        //                                                                                  zuora__Subscription__c 
        //                                                                          WHERE 
        //                                                                                  Id = : subscriptionId];
        
    SavePoint oppRollback;

        Try{
      Zuora__Subscription__c renewSubscription = [SELECT 
                                                    Id, 
                                                    Name, 
                                                    Zuora__Account__c, 
                                                    Zuora__Zuora_Id__c 
                                                  FROM 
                                                    zuora__Subscription__c 
                                                  WHERE 
                                                    Id = :subscriptionId];

      oppRollback = Database.setSavepoint();
            Opportunity oppInsert = new Opportunity();
            oppInsert.stageName = 'Prospecting';//'Closed Lost';
            oppInsert.type = 'Renewal';
            oppInsert.AccountId = renewSubscription.Zuora__Account__c;
            oppInsert.recordtypeId=rtOppMapByName.get('Local').getRecordTypeId();
            oppInsert.name = 'Renewal Subscription ' + renewSubscription.Name;
            oppInsert.Renew_Subscription__c = renewSubscription.Id;
            oppInsert.CloseDate = date.today().adddays(15);
            insert oppInsert;

      // CSP-1963
      ZuoraSubscriptionUtility.generateRenewalQuoteFromSubscription(renewSubscription.Id, oppInsert);

      buildExpiringSubsData();

            return null;
        }Catch(exception E){
      Database.rollback(oppRollback);
      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
    }

    public PageReference goRemove(){
        if (String.isBlank(opportunityInfos.Lost_Reason__c) || opportunityInfos.Lost_Reason__c.containsIgnoreCase('none')) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please SELECT a reason why you do not wish to pursue this renewal opportunity');
            ApexPages.addMessage(myMsg);
            return null;
        }

        List<zuora__Subscription__c> ZsList = [SELECT id,name, Zuora__Account__c,Zuora__Zuora_Id__c FROM zuora__Subscription__c WHERE id = : subscriptionId];
        List<Opportunity> renewalOppList = [SELECT id,name, Renew_Subscription__c, StageName FROM Opportunity WHERE Renew_Subscription__c = : subscriptionId];
        opportunity Opp = new Opportunity();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        Try{
            if (!renewalOppList.isEmpty()) {
                Opp = renewalOppList[0];
            }else{
                Opp = new Opportunity();
                Opp.stageName = 'Prospecting';//'Closed Lost';
                Opp.type = 'Renewal';
                Opp.AccountId = ZsList[0].Zuora__Account__c;
                opp.recordtypeId=rtOppMapByName.get('Local').getRecordTypeId();
                opp.CloseDate = date.today();
                opp.name = System.Label.RemovedFromRenewalQueue;
                opp.Renew_Subscription__c = ZsList[0].Id;

                insert opp;
            }
            opp.Name = System.Label.RemovedFromRenewalQueue;
            opp.Lost_Reason__c = opportunityInfos.Lost_Reason__c;
            Opp.stageName = 'Closed Lost';//'Closed Lost';
            update Opp;
            opportunityInfos = new Opportunity();

            buildExpiringSubsData();
            return null;
        }Catch(exception E){
            ApexPages.addMessages(e);
            return null;
        }
    }

    public PageReference cancelAndRefresh() {
        return null;
    }


    /*public PageReference OnchageOwnership(){
    opportunityInfos = new Opportunity();
    pageNumber = 1;
    buildExpiringSubsData();
    return null;
    }

    public PageReference OnchageDate(){
    pageNumber = 1;
    buildExpiringSubsData();
    return null;
    }*/

    Public Pagereference doSort(){
        List<SubsEntityWrapper> subsenlist = new List<SubsEntityWrapper>();
        subsenlist = subsMap.get(renewalRepName);
        SubsEntityWrapper.sortBy = columnName;
        system.debug('columnName:::'+columnName+'::::renewalRepName::::'+renewalRepName);
        system.debug('sortMap::::::::::::'+sortMap);

        if(sortMap.containsKey(renewalRepName) && sortMap.get(renewalRepName).columnName == columnName){
            if(sortMap.get(renewalRepName).ascOrDesc == 'ASC'){
                sortMap.put(renewalRepName,new sortData(columnName,'DESC'));
                SubsEntityWrapper.ascOrDesc = 'DESC';
            }else if(sortMap.get(renewalRepName).ascOrDesc == 'DESC'){
                sortMap.put(renewalRepName,new sortData(columnName,'ASC'));
                SubsEntityWrapper.ascOrDesc = 'ASC';
            }
        }else if(sortMap.containsKey(renewalRepName) && sortMap.get(renewalRepName).columnName != columnName){
            sortMap.put(renewalRepName,new sortData(columnName,'ASC'));
            SubsEntityWrapper.ascOrDesc = 'ASC';
        }else{
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Sorry, an unexpect happened, please try again or contact your admin, thanks!');
            ApexPages.addMessage(myMsg);
        }
        system.debug('sortMap::::::::::::'+sortMap.get(renewalRepName));
        system.debug('List before sort:::::::::::');
        subsenlist.sort();
        system.debug('List after sort:::::::::::');
        subsMap.put(renewalRepName,subsenlist);
        return null;
    }



    public class SortData{
        public String columnName{get;set;}
        public String ascOrDesc{get;set;}
        public sortData(String columnName,String ascOrDesc){
            this.columnName = columnName;
            this.ascOrDesc = ascOrDesc;
        }
    }
}
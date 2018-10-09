global with sharing class NationalSalesPipelineController {
    private final Map<Integer, String> monthQuarterMap = new Map<Integer, String>{1 => 'q1', 2 => 'q1', 3 => 'q1', 4 => 'q2', 5 => 'q2', 6 => 'q2', 7 => 'q3', 8 => 'q3', 9 => 'q3', 10 => 'q4', 11 => 'q4', 12 => 'q4'};
    private Date filterStartDate;
    private Date filterSecondStartDate;
    private Date filterEndDate;
    private Map<String, PipelineInfo> stagePipelineTotalMap {get; set;}

    public Map<String, List<PipelineInfo>> salesRepPipelineMap {get; set;}
    public Map<String, PipelineInfo> salesRepTotalMap {get; set;}
    public PipelineInfo grandTotal {get; set;}
    public Integer selectedYear {get; set;}
    public String selectYear {get; set;}

    public String viewType {get; set;}
    public String viewOppType {get; set;}
    public String selectedProdFamily {get; set;}
    public Boolean noResults {get; set;}
    public String selectCampaign {get; set;} //CSP-2972 SIVA VANKADARu 08/07/2018 BEGIN
    public Boolean accountExecutive {get; private set;}

    //////////////////////
    // STATIC VARIABLES // 
    //////////////////////
    private static final String ST_ALL = 'all';
    private static final Id CURRENT_USER_ID = UserInfo.getUserId();

    /////////////////
    // CONSTRUCTOR //
    /////////////////
    public NationalSalesPipelineController() {
        salesRepPipelineMap = new Map<String, List<PipelineInfo>>();

        // Current Pages URL Parameters
        Map<String, String> paramMap = ApexPages.currentPage().getParameters();
        
        // Get current running user record Id
        String userId = UserInfo.getUserId();

        // Determine if the current running user has the UserRole "Account Executive"
        accountExecutive = isUserRoleEqual(userId, 'Account Executive');

        String paramViewType = paramMap.get('viewType');
        if(paramViewType != null) {
            viewType = paramViewType;
        } else {
            viewType = accountExecutive ? 'myreps' : ST_ALL;
        }

        // Default values for page display if parameters do not exist
        viewOppType = (paramMap.get('viewOppType') != null) ? paramMap.get('viewOppType') : ST_ALL;
        selectedProdFamily = (paramMap.get('selectedProdFamily') != null) ? paramMap.get('selectedProdFamily') : ST_ALL;
        selectYear = (paramMap.get('selectYear') != null) ? paramMap.get('selectYear') : String.valueof(date.today().year());
        selectCampaign = (paramMap.get('selectCampaign') != null) ? paramMap.get('selectCampaign') : ST_ALL; //CSP-2972 SIVA VANKADARu 08/07/2018 BEGIN


        // Default no results boolean to true
        noResults = true;
        
        // Execute build pipeline data method
        buildPipelineData();
    }

    /**
     *   Method used to determine if a user has the specified role. This method
     *   queries for the User using the supplied user id.
     *       
     *   @author Justin
     *   @param  {String}  userId       User id that is used to query for a specific user
     *   @param  {String}  roleName     Role name used to determine if the current user has this
     *                                  specific role
     *   @return {Boolean}              Boolean value returned that is representative of the current
     *                                  user having the supplied role
     */
    private static Boolean isUserRoleEqual(String userId, String roleName) {
        if(String.isBlank(userId) || String.isBlank(roleName)) {
            return false;
        }

        User currentUser = [SELECT Id, UserRole.Name FROM User WHERE Id = :userId];

        return currentUser.UserRole.Name == roleName;
    }

    /**
     *   Getter for "ViewTypes" variable used by the front end. Builds select option
     *   map.
     *   
     *   @author Rusty
     *   @return {Map<String, String>}      Map of picklist/select option values
     */
    public Map<String, String> getViewTypes() {
        Map<String, String> options = new Map<String, String>();
        
        if(accountExecutive) {
            options.put('myreps', 'My Pipeline');
            options.put('product', 'My Forecast Category Summary');
        } else {
            options.put('all','All Account Executives');
            if([SELECT COUNT() FROM User WHERE ManagerId = :UserInfo.getUserId()] == 0){
                options.put('myreps', 'My Pipeline');
            }else{
                options.put('myreps', 'My Team Pipeline');
            }
            options.put('stage','Stage Summary');
            options.put('product', 'Forecast Category Summary');
        }

        return options;
    }

    /**
     *   Getter for "ProductFamilyTypes" variable used by the front end. Builds select option
     *   map.
     *   
     *   @author Rusty
     *   @return {Map<String, String>}      Map of picklist/select option values
     */
    public Map<String, String> getProductFamilyTypes(){
        Map<String, String> options = new Map<String, String>();
        options.put('all','All Product Family');
        options.put('online', 'Only Online');
        options.put('print', 'Only Print');
        return options;
    }

    /**
     *   Getter for "SelectYears" variable used by the frotn end. Builds select option map.
     *   @author Rusty
     *   @return {Map<String, String>}      Map of picklist/select option values
     */
    public Map<String, String> getSelectYears(){
        Map<String, String> options = new Map<String, String>();
        Integer startYear = date.today().year() - 1;
        for(Integer i = 0; i < 11; i++){
            options.put(String.valueOf(startYear + i), String.valueOf(startYear + i));
        }
        return options;
    }

    /**
     *   Getter for "selectCampaign" variable used by the frotn end. Builds select option map.
     *   @author Siva
     *   @return {Map<String, String>}      Map of picklist/select option values
     */
    public Map<String, String> getselectCampaigns(){
        Map<String, String> options = new Map<String, String>();
        options.put('all', System.Label.NationalSalesPipelineAll);
        options.put('only', System.Label.NationalSalesPipelineStartDate);
        return options;
    }


    public void buildPipelineData(){
        salesRepPipelineMap.clear();
        stagePipelineTotalMap = new Map<String, PipelineInfo>();
        salesRepTotalMap = new Map<String, PipelineInfo>();
        grandTotal = new PipelineInfo();
        selectedYear = (String.isNotBlank(selectYear) == null) ? Date.today().year() : Integer.valueOf(selectYear);
        filterStartDate = date.newInstance(selectedYear, 1, 1);
        filterSecondStartDate = date.newInstance(selectedYear + 1, 1, 1);
        filterEndDate = date.newInstance(selectedYear + 1, 12, 31);

        List<Opportunity> oppList = new List<Opportunity>();
        
        if(viewType == 'myreps'){
            /* 
                If the current user is an Account Executive only query against records they own
                or they are the SplitRep on else query against records the user owns and records
                of the people they manage.
            */
            //CSP-2972 SIVA VANKADARu 08/07/2018 BEGIN
            if(accountExecutive) {
                if (selectCampaign != 'all'){
                    oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) AND isClosed = false AND (OwnerId = :CURRENT_USER_ID OR SplitRep__c = :CURRENT_USER_ID) ORDER BY StageName, Account.Name];
                }
                else{
                    oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and isClosed = false AND (OwnerId = :CURRENT_USER_ID OR SplitRep__c = :CURRENT_USER_ID) ORDER BY StageName, Account.Name];
                }
            } else {
                if (selectCampaign != 'all'){
                    oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) AND isClosed = false AND OwnerId IN (select Id from User where IsActive = true and (ManagerId =: CURRENT_USER_ID or Id =: CURRENT_USER_ID)) order by StageName, Account.Name];
                }
                else{
                    oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and isClosed = false AND OwnerId IN (select Id from User where IsActive = true and (ManagerId =: CURRENT_USER_ID or Id =: CURRENT_USER_ID)) order by StageName, Account.Name];
                }
            }
            
            repStageView(oppList);
        }else if(viewType == 'stage'){
            //oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, (select Start_Date__c, End_Date__c, TotalPrice from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) and isClosed = false and StageName != 'Stage 10: Final Review' order by StageName, Account.Name];
            if (selectCampaign != 'all'){
                oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) AND isClosed = false ORDER BY StageName, Account.Name];
            }
            else{
                oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and isClosed = false ORDER BY StageName, Account.Name];
            }
            repStageView(oppList);
        }else if(viewType == 'all'){
            //oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, (select Start_Date__c, End_Date__c, TotalPrice from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) and isClosed = false and StageName != 'Stage 10: Final Review' order by Owner.Name, StageName, Account.Name];
            if (selectCampaign != 'all'){
                oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and ((CampaignStartDate__c >= :filterStartDate and CampaignStartDate__c <=: filterEndDate) or (CampaignEndDate__c >=: filterStartDate and CampaignEndDate__c <=: filterEndDate) or (CampaignStartDate__c <=: filterStartDate and CampaignEndDate__c >=: filterEndDate)) AND isClosed = false ORDER BY Owner.Name, StageName, Account.Name];
            }
            else{
                oppList = [select Id, Owner.Name, StageName, Probability, AccountId, Account.Name, Name, OrderNumber__c, CampaignStartDate__c, CampaignEndDate__c, Amount, SplitRep__c, Primary_Rep_p__c, Split_Rep_p__c, SplitRep__r.Name, CreatedDate, Agency__r.Name, (select Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId from OpportunityLineItems where (Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate)) from Opportunity where RecordType.Name = 'National' and isClosed = false ORDER BY Owner.Name, StageName, Account.Name];
            }
            repStageView(oppList);
        }else if(viewType == 'product'){
            
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            if(selectedProdFamily == 'all'){
                /* 
                    If the current user is an Account Executive only query against records they own
                    or they are the SplitRep on else query against records the user owns and records
                    of the people they manage.
                */
                if(accountExecutive) {
                    if (selectCampaign != 'all'){
                        oliList =   [SELECT Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId, Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family
                                    FROM 
                                        OpportunityLineItem 
                                    WHERE 
                                        ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) OR (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                    AND 
                                        Opportunity.RecordType.Name = 'National' 
                                    AND 
                                        ((Opportunity.CampaignStartDate__c >= :filterStartDate AND Opportunity.CampaignStartDate__c <=: filterEndDate) OR (Opportunity.CampaignEndDate__c >=: filterStartDate AND Opportunity.CampaignEndDate__c <=: filterEndDate) OR (Opportunity.CampaignStartDate__c <=: filterStartDate AND Opportunity.CampaignEndDate__c >=: filterEndDate)) 
                                    AND 
                                        Opportunity.IsClosed = false
                                    AND
                                        (Opportunity.OwnerId = :CURRENT_USER_ID OR Opportunity.SplitRep__c = :CURRENT_USER_ID)
                                    ORDER BY 
                                        Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    } else {
                        oliList =   [SELECT Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId, Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family
                                    FROM 
                                        OpportunityLineItem 
                                    WHERE 
                                        ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) OR (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                    AND 
                                        Opportunity.RecordType.Name = 'National' 
                                    AND 
                                        Opportunity.IsClosed = false
                                    AND
                                        (Opportunity.OwnerId = :CURRENT_USER_ID OR Opportunity.SplitRep__c = :CURRENT_USER_ID)
                                    ORDER BY 
                                        Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    }
                } else {
                    if (selectCampaign != 'all'){
                        oliList = [SELECT Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId, Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family from OpportunityLineItem where ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                        and Opportunity.RecordType.Name = 'National' and ((Opportunity.CampaignStartDate__c >= :filterStartDate and Opportunity.CampaignStartDate__c <=: filterEndDate) or (Opportunity.CampaignEndDate__c >=: filterStartDate and Opportunity.CampaignEndDate__c <=: filterEndDate) or (Opportunity.CampaignStartDate__c <=: filterStartDate and Opportunity.CampaignEndDate__c >=: filterEndDate)) and Opportunity.IsClosed = false ORDER BY Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    } else {
                        oliList = [SELECT Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, Opportunity.Split_Rep_p__c, Opportunity.OwnerId, Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family from OpportunityLineItem where ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                        and Opportunity.RecordType.Name = 'National' and Opportunity.IsClosed = false ORDER BY Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    }                    
                }
                
            }else{
                List<String> prodFamilyList = new List<String>();
                if(selectedProdFamily == 'online'){
                    prodFamilyList.add('Online');
                }else if(selectedProdFamily == 'Print'){
                    prodFamilyList.add('Print');
                }

                /* 
                    If the current user is an Account Executive only query against records they own
                    or they are the SplitRep on else query against records the user owns and records
                    of the people they manage.
                */
                if(accountExecutive) {
                    if (selectCampaign != 'all'){
                        oliList =   [SELECT Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, 
                                        Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family 
                                    FROM 
                                        OpportunityLineItem 
                                    WHERE 
                                        ((Start_Date__c >= :filterStartDate AND Start_Date__c <=: filterEndDate) OR (End_Date__c >=: filterStartDate AND End_Date__c <=: filterEndDate) OR (Start_Date__c <=: filterStartDate AND End_Date__c >=: filterEndDate))
                                    AND 
                                        Opportunity.RecordType.Name = 'National' 
                                    AND 
                                        ((Opportunity.CampaignStartDate__c >= :filterStartDate AND Opportunity.CampaignStartDate__c <=: filterEndDate) OR (Opportunity.CampaignEndDate__c >=: filterStartDate AND Opportunity.CampaignEndDate__c <=: filterEndDate) OR (Opportunity.CampaignStartDate__c <=: filterStartDate AND Opportunity.CampaignEndDate__c >=: filterEndDate))
                                    AND 
                                        Opportunity.IsClosed = false
                                    AND 
                                        Product2.Family IN :prodFamilyList
                                    AND
                                        (Opportunity.OwnerId = :CURRENT_USER_ID OR Opportunity.SplitRep__c = :CURRENT_USER_ID)
                                    ORDER BY 
                                        Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    } else {
                        oliList =   [SELECT Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, Opportunity.Account.Name, 
                                        Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, Opportunity.CampaignEndDate__c, Opportunity.Amount, 
                                        Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c, 
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family 
                                    FROM 
                                        OpportunityLineItem 
                                    WHERE 
                                        ((Start_Date__c >= :filterStartDate AND Start_Date__c <=: filterEndDate) OR (End_Date__c >=: filterStartDate AND End_Date__c <=: filterEndDate) OR (Start_Date__c <=: filterStartDate AND End_Date__c >=: filterEndDate))
                                    AND 
                                        Opportunity.RecordType.Name = 'National' 
                                    AND 
                                        Opportunity.IsClosed = false
                                    AND 
                                        Product2.Family IN :prodFamilyList
                                    AND
                                        (Opportunity.OwnerId = :CURRENT_USER_ID OR Opportunity.SplitRep__c = :CURRENT_USER_ID)
                                    ORDER BY 
                                        Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    }
                } else {
                    if (selectCampaign != 'all'){
                        oliList = [SELECT Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, 
                                        Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, 
                                        Opportunity.CampaignEndDate__c, Opportunity.Amount, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c,  
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family from OpportunityLineItem where ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                        and Opportunity.RecordType.Name = 'National' and ((Opportunity.CampaignStartDate__c >= :filterStartDate and Opportunity.CampaignStartDate__c <=: filterEndDate) or (Opportunity.CampaignEndDate__c >=: filterStartDate and Opportunity.CampaignEndDate__c <=: filterEndDate) or (Opportunity.CampaignStartDate__c <=: filterStartDate and Opportunity.CampaignEndDate__c >=: filterEndDate)) and Opportunity.IsClosed = false AND Product2.Family IN :prodFamilyList order by Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    } else {
                        oliList = [SELECT Opportunity.Id, Opportunity.Owner.Name, Opportunity.StageName, Opportunity.Probability, Opportunity.AccountId, 
                                        Opportunity.Account.Name, Opportunity.Name, Opportunity.OrderNumber__c, Opportunity.CampaignStartDate__c, 
                                        Opportunity.CampaignEndDate__c, Opportunity.Amount, Opportunity.SplitRep__c, Opportunity.Primary_Rep_p__c,  
                                        Start_Date__c, End_Date__c, TotalPrice, Product2.Name, Product2.Family from OpportunityLineItem where ((Start_Date__c >= :filterStartDate and Start_Date__c <=: filterEndDate) or (End_Date__c >=: filterStartDate and End_Date__c <=: filterEndDate) or (Start_Date__c <=: filterStartDate and End_Date__c >=: filterEndDate))
                                        and Opportunity.RecordType.Name = 'National' and Opportunity.IsClosed = false AND Product2.Family IN :prodFamilyList order by Product2.Name, Opportunity.StageName, Opportunity.Account.Name];
                    }
                    //CSP-2972 SIVA VANKADARu 08/07/2018 END
                }
                
            }
            
            forecastView(oliList);
        }
        

        if(salesRepPipelineMap.isEmpty()){
            noResults = true;
        }else{
            noResults = false;
        }
    }

    private void forecastView(List<OpportunityLineItem> oliList){
        String currentStage = '';
        String currentOwner = '';
        Set<Id> myRepIds = new Set<Id>();

        for(Integer i = 0; i < oliList.size(); i++) {
            OpportunityLineItem record = oliList[i];

            if(String.isBlank(currentStage)){
                currentStage = record.Opportunity.StageName;
            }else if((currentStage != record.Opportunity.StageName || currentOwner != record.Product2.Name)){
                salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
                stagePipelineTotalMap.clear();
                currentStage = record.Opportunity.StageName;
            }

            if(String.isBlank(currentOwner)){
                currentOwner = record.Product2.Name;
            }else if(currentOwner != record.Product2.Name){
                currentOwner = record.Product2.Name;
            }


            PipelineInfo newPipelineInfo = new PipelineInfo();
            newPipelineInfo.opportunityInfo = record.Opportunity.clone();
            newPipelineInfo.opportunityInfo.Id = record.OpportunityId;
            newPipelineInfo.opportunityInfo.Amount = record.TotalPrice;
            if(accountExecutive && String.isNotBlank(newPipelineInfo.opportunityInfo.SplitRep__c)) {
                newPipelineInfo.opportunityInfo.Amount = determineAmountSplit(newPipelineInfo.opportunityInfo, CURRENT_USER_ID);
            }

            newPipelineInfo = buildQuarterData(record, newPipelineInfo, false);


            newPipelineInfo.totalCYRev = newPipelineInfo.q1CYRev + newPipelineInfo.q2CYRev + newPipelineInfo.q3CYRev + newPipelineInfo.q4CYRev;
            newPipelineInfo.totalNYRev = newPipelineInfo.q1NYRev + newPipelineInfo.q2NYRev + newPipelineInfo.q3NYRev + newPipelineInfo.q4NYRev;

            if(newPipelineInfo.opportunityInfo.Amount  != null) { //CSP-2972 SIVA VANKADARu 08/07/2018
                grandTotal.opportunityInfo.Amount = (grandTotal.opportunityInfo.Amount == null) ? newPipelineInfo.opportunityInfo.Amount : grandTotal.opportunityInfo.Amount + newPipelineInfo.opportunityInfo.Amount;
            }
            grandTotal.q1CYRev += newPipelineInfo.q1CYRev;
            grandTotal.q2CYRev += newPipelineInfo.q2CYRev;
            grandTotal.q3CYRev += newPipelineInfo.q3CYRev;
            grandTotal.q4CYRev += newPipelineInfo.q4CYRev;
            grandTotal.totalCYRev += newPipelineInfo.totalCYRev;
            grandTotal.q1NYRev += newPipelineInfo.q1NYRev;
            grandTotal.q2NYRev += newPipelineInfo.q2NYRev;
            grandTotal.q3NYRev += newPipelineInfo.q3NYRev;
            grandTotal.q4NYRev += newPipelineInfo.q4NYRev;
            grandTotal.totalNYRev += newPipelineInfo.totalNYRev;

            if(salesRepPipelineMap.containsKey(currentOwner)){
                salesRepPipelineMap.get(currentOwner).add(newPipelineInfo);
            }else{
                List<PipelineInfo> newPipelineInfoList = new List<PipelineInfo>();
                newPipelineInfoList.add(newPipelineInfo);
                salesRepPipelineMap.put(currentOwner, newPipelineInfoList);
            }

            if(stagePipelineTotalMap.containsKey(record.Opportunity.StageName)){
                stagePipelineTotalMap.get(record.Opportunity.StageName).q1CYRev += newPipelineInfo.q1CYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q2CYRev += newPipelineInfo.q2CYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q3CYRev += newPipelineInfo.q3CYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q4CYRev += newPipelineInfo.q4CYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).totalCYRev += newPipelineInfo.totalCYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q1NYRev += newPipelineInfo.q1NYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q2NYRev += newPipelineInfo.q2NYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q3NYRev += newPipelineInfo.q3NYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).q4NYRev += newPipelineInfo.q4NYRev;
                stagePipelineTotalMap.get(record.Opportunity.StageName).totalNYRev += newPipelineInfo.totalNYRev;

                if(accountExecutive && String.isNotBlank(newPipelineInfo.opportunityInfo.SplitRep__c)) {
                    if(newPipelineInfo.opportunityInfo.OwnerId == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Primary_Rep_p__c != null) {
                        stagePipelineTotalMap.get(record.Opportunity.StageName).opportunityInfo.Amount += record.TotalPrice * (newPipelineInfo.opportunityInfo.Primary_Rep_p__c / 100);
                    } else if(newPipelineInfo.opportunityInfo.SplitRep__c == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Split_Rep_p__c != null) {
                        stagePipelineTotalMap.get(record.Opportunity.StageName).opportunityInfo.Amount += record.TotalPrice * (newPipelineInfo.opportunityInfo.Split_Rep_p__c / 100);
                    }
                } else {
                    stagePipelineTotalMap.get(record.Opportunity.StageName).opportunityInfo.Amount += record.TotalPrice;
                }
            }else{
                PipelineInfo totalPipelineInfo = new PipelineInfo();
                totalPipelineInfo.opportunityInfo.StageName = record.Opportunity.StageName + ' Total:';
                totalPipelineInfo.q1CYRev = newPipelineInfo.q1CYRev;
                totalPipelineInfo.q2CYRev = newPipelineInfo.q2CYRev;
                totalPipelineInfo.q3CYRev = newPipelineInfo.q3CYRev;
                totalPipelineInfo.q4CYRev = newPipelineInfo.q4CYRev;
                totalPipelineInfo.totalCYRev = newPipelineInfo.totalCYRev;
                totalPipelineInfo.q1NYRev = newPipelineInfo.q1NYRev;
                totalPipelineInfo.q2NYRev = newPipelineInfo.q2NYRev;
                totalPipelineInfo.q3NYRev = newPipelineInfo.q3NYRev;
                totalPipelineInfo.q4NYRev = newPipelineInfo.q4NYRev;
                totalPipelineInfo.totalNYRev = newPipelineInfo.totalNYRev;

                ////////////////////////////////////////////////////////
                // Logic to determine Stage Total display on Forecast //
                ////////////////////////////////////////////////////////
                
                // If current user is an accountExecutive and the current Opportunity has a split owner determine
                // split amount. Else just use TotalPrice without splits
                if(accountExecutive && String.isNotBlank(newPipelineInfo.opportunityInfo.SplitRep__c)) {
                    if(newPipelineInfo.opportunityInfo.OwnerId == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Primary_Rep_p__c != null) {
                        totalPipelineInfo.opportunityInfo.Amount = record.TotalPrice * (newPipelineInfo.opportunityInfo.Primary_Rep_p__c / 100);
                    } else if(newPipelineInfo.opportunityInfo.SplitRep__c == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Split_Rep_p__c != null) {
                        totalPipelineInfo.opportunityInfo.Amount = record.TotalPrice * (newPipelineInfo.opportunityInfo.Split_Rep_p__c / 100);
                    }
                } else {
                    totalPipelineInfo.opportunityInfo.Amount = record.TotalPrice;
                }
                
                stagePipelineTotalMap.put(record.Opportunity.StageName, totalPipelineInfo);
            }

            if(salesRepTotalMap.containsKey(currentOwner)){
                salesRepTotalMap.get(currentOwner).q1CYRev += newPipelineInfo.q1CYRev;
                salesRepTotalMap.get(currentOwner).q2CYRev += newPipelineInfo.q2CYRev;
                salesRepTotalMap.get(currentOwner).q3CYRev += newPipelineInfo.q3CYRev;
                salesRepTotalMap.get(currentOwner).q4CYRev += newPipelineInfo.q4CYRev;
                salesRepTotalMap.get(currentOwner).totalCYRev += newPipelineInfo.totalCYRev;
                salesRepTotalMap.get(currentOwner).q1NYRev += newPipelineInfo.q1NYRev;
                salesRepTotalMap.get(currentOwner).q2NYRev += newPipelineInfo.q2NYRev;
                salesRepTotalMap.get(currentOwner).q3NYRev += newPipelineInfo.q3NYRev;
                salesRepTotalMap.get(currentOwner).q4NYRev += newPipelineInfo.q4NYRev;
                salesRepTotalMap.get(currentOwner).totalNYRev += newPipelineInfo.totalNYRev;
                if(accountExecutive && String.isNotBlank(newPipelineInfo.opportunityInfo.SplitRep__c)) {
                    if(newPipelineInfo.opportunityInfo.OwnerId == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Primary_Rep_p__c != null) {
                        salesRepTotalMap.get(currentOwner).opportunityInfo.Amount += record.TotalPrice * (newPipelineInfo.opportunityInfo.Primary_Rep_p__c / 100);
                    } else if(newPipelineInfo.opportunityInfo.SplitRep__c == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Split_Rep_p__c != null) {
                        salesRepTotalMap.get(currentOwner).opportunityInfo.Amount += record.TotalPrice * (newPipelineInfo.opportunityInfo.Split_Rep_p__c / 100);
                    }
                } else {
                    salesRepTotalMap.get(currentOwner).opportunityInfo.Amount += record.TotalPrice;
                }
            }else{
                PipelineInfo salesRepTotalInfo = new PipelineInfo();
                salesRepTotalInfo.q1CYRev = newPipelineInfo.q1CYRev;
                salesRepTotalInfo.q2CYRev = newPipelineInfo.q2CYRev;
                salesRepTotalInfo.q3CYRev = newPipelineInfo.q3CYRev;
                salesRepTotalInfo.q4CYRev = newPipelineInfo.q4CYRev;
                salesRepTotalInfo.totalCYRev = newPipelineInfo.totalCYRev;
                salesRepTotalInfo.q1NYRev = newPipelineInfo.q1NYRev;
                salesRepTotalInfo.q2NYRev = newPipelineInfo.q2NYRev;
                salesRepTotalInfo.q3NYRev = newPipelineInfo.q3NYRev;
                salesRepTotalInfo.q4NYRev = newPipelineInfo.q4NYRev;
                salesRepTotalInfo.totalNYRev = newPipelineInfo.totalNYRev;
                if(accountExecutive && String.isNotBlank(newPipelineInfo.opportunityInfo.SplitRep__c)) {
                    if(newPipelineInfo.opportunityInfo.OwnerId == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Primary_Rep_p__c != null) {
                        salesRepTotalInfo.opportunityInfo.Amount = record.TotalPrice * (newPipelineInfo.opportunityInfo.Primary_Rep_p__c / 100);
                    } else if(newPipelineInfo.opportunityInfo.SplitRep__c == CURRENT_USER_ID && newPipelineInfo.opportunityInfo.Split_Rep_p__c != null) {
                        salesRepTotalInfo.opportunityInfo.Amount = record.TotalPrice * (newPipelineInfo.opportunityInfo.Split_Rep_p__c / 100);
                    }
                } else {
                    salesRepTotalInfo.opportunityInfo.Amount = record.TotalPrice;
                }
                salesRepTotalMap.put(currentOwner, salesRepTotalInfo);
            }
        }

        if(String.isNotBlank(currentStage) && String.isNotBlank(currentOwner)){
            salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
        }
    }

    private void repStageView(List<Opportunity> oppList){
        String currentStage = '';
        String currentOwner = '';
        Set<Id> myRepIds = new Set<Id>();

        if(String.isNotBlank(viewType) && viewType == 'stage'){
            currentOwner = 'Stage Summary';
        }

        Map<String, Map<String, List<PipelineInfo>>> salesRepToStageMap = new Map<String, Map<String, List<PipelineInfo>>>();

        for(Integer i = 0; i < oppList.size(); i++) {
            Opportunity record = oppList[i];

            if(String.isBlank(currentStage)) {
                currentStage = record.StageName;
            } else if (accountExecutive && (currentStage != record.StageName || (currentOwner != record.Owner.Name && currentOwner != record.SplitRep__r.Name)) && viewType != 'stage') {
                salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
                stagePipelineTotalMap.clear();
                currentStage = record.StageName;
            } else if (!accountExecutive && (currentStage != record.StageName || currentOwner != record.Owner.Name) && viewType != 'stage'){
                salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
                stagePipelineTotalMap.clear();
                currentStage = record.StageName;
            } else if (currentStage != record.StageName && viewType == 'stage'){
                salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
                currentStage = record.StageName;
            }

            if(viewType != 'stage'){
                if(String.isBlank(currentOwner) && accountExecutive && record.OwnerId != CURRENT_USER_ID) {
                    currentOwner = record.SplitRep__r.Name;
                } else if(String.isBlank(currentOwner)){
                    currentOwner = record.Owner.Name;
                } else if(currentOwner != record.Owner.Name){
                    if(accountExecutive && record.OwnerId != CURRENT_USER_ID) {
                        currentOwner = record.SplitRep__r.Name;
                    } else {
                        currentOwner = record.Owner.Name;
                    }
                }
            }


            PipelineInfo newPipelineInfo = new PipelineInfo();
            PipelineInfo splitPipelineInfo;
            if(accountExecutive && String.isNotBlank(record.SplitRep__c)) {
                record.Amount = determineAmountSplit(record, CURRENT_USER_ID);
            } else if(String.isNotBlank(record.SplitRep__c) && viewType != 'stage') {
                splitPipelineInfo = new PipelineInfo();
                splitPipelineInfo.opportunityInfo = record.clone(true, true, true, true);
                splitPipelineInfo.opportunityInfo.Amount = determineAmountSplit(record, record.SplitRep__c);

                record.Amount = determineAmountSplit(record, record.OwnerId);
            }

            newPipelineInfo.opportunityInfo = record;

            if(record.OpportunityLineItems.size() > 0){
                for(Integer j = 0; j < record.OpportunityLineItems.size(); j++) {
                    OpportunityLineItem childRecord = record.OpportunityLineItems[j];
                    newPipeLineInfo = buildQuarterData(childRecord, newPipelineInfo, false);

                    if(splitPipelineInfo != null) {
                        OpportunityLineItem splitChildRecord = splitPipelineInfo.opportunityInfo.OpportunityLineItems[j];
                        splitPipelineInfo = buildQuarterData(splitChildRecord, splitPipelineInfo, true);
                    }
                }
            }

            newPipelineInfo.totalCYRev = newPipelineInfo.q1CYRev + newPipelineInfo.q2CYRev + newPipelineInfo.q3CYRev + newPipelineInfo.q4CYRev;
            newPipelineInfo.totalNYRev = newPipelineInfo.q1NYRev + newPipelineInfo.q2NYRev + newPipelineInfo.q3NYRev + newPipelineInfo.q4NYRev;

            if (record.Amount != null){ //CSP-2972 SIVA VANKADARu 08/07/2018
                grandTotal.opportunityInfo.Amount = (grandTotal.opportunityInfo.Amount == null) ? record.Amount : grandTotal.opportunityInfo.Amount + record.Amount;//2972
            }
            grandTotal.q1CYRev += newPipelineInfo.q1CYRev;
            grandTotal.q2CYRev += newPipelineInfo.q2CYRev;
            grandTotal.q3CYRev += newPipelineInfo.q3CYRev;
            grandTotal.q4CYRev += newPipelineInfo.q4CYRev;
            grandTotal.totalCYRev += newPipelineInfo.totalCYRev;
            grandTotal.q1NYRev += newPipelineInfo.q1NYRev;
            grandTotal.q2NYRev += newPipelineInfo.q2NYRev;
            grandTotal.q3NYRev += newPipelineInfo.q3NYRev;
            grandTotal.q4NYRev += newPipelineInfo.q4NYRev;
            grandTotal.totalNYRev += newPipelineInfo.totalNYRev;

            if(splitPipelineInfo != null) {
                splitPipelineInfo.totalCYRev = splitPipelineInfo.q1CYRev + splitPipelineInfo.q2CYRev + splitPipelineInfo.q3CYRev + splitPipelineInfo.q4CYRev;
                splitPipelineInfo.totalNYRev = splitPipelineInfo.q1NYRev + splitPipelineInfo.q2NYRev + splitPipelineInfo.q3NYRev + splitPipelineInfo.q4NYRev;

                if (splitPipelineInfo.opportunityInfo.Amount != null){ //CSP-2972 SIVA VANKADARu 08/07/2018
                    grandTotal.opportunityInfo.Amount = (grandTotal.opportunityInfo.Amount == null) ? splitPipelineInfo.opportunityInfo.Amount : grandTotal.opportunityInfo.Amount + splitPipelineInfo.opportunityInfo.Amount;
                }
                grandTotal.q1CYRev += splitPipelineInfo.q1CYRev;
                grandTotal.q2CYRev += splitPipelineInfo.q2CYRev;
                grandTotal.q3CYRev += splitPipelineInfo.q3CYRev;
                grandTotal.q4CYRev += splitPipelineInfo.q4CYRev;
                grandTotal.totalCYRev += splitPipelineInfo.totalCYRev;
                grandTotal.q1NYRev += splitPipelineInfo.q1NYRev;
                grandTotal.q2NYRev += splitPipelineInfo.q2NYRev;
                grandTotal.q3NYRev += splitPipelineInfo.q3NYRev;
                grandTotal.q4NYRev += splitPipelineInfo.q4NYRev;
                grandTotal.totalNYRev += splitPipelineInfo.totalNYRev;

                if(salesRepPipelineMap.containsKey(splitPipelineInfo.opportunityInfo.SplitRep__r.Name)) {
                    salesRepPipelineMap.get(splitPipelineInfo.opportunityInfo.SplitRep__r.Name).add(splitPipelineInfo);
                } else {
                    List<PipelineInfo> splitPipelineInfoList = new List<PipelineInfo>();
                    splitPipelineInfoList.add(splitPipelineInfo);
                    salesRepPipelineMap.put(splitPipelineInfo.opportunityInfo.SplitRep__r.Name, splitPipelineInfoList);
                }
            }

            if(salesRepPipelineMap.containsKey(currentOwner)){
                salesRepPipelineMap.get(currentOwner).add(newPipelineInfo);
            }else{
                List<PipelineInfo> newPipelineInfoList = new List<PipelineInfo>();
                newPipelineInfoList.add(newPipelineInfo);
                salesRepPipelineMap.put(currentOwner, newPipelineInfoList);
            }

            if(stagePipelineTotalMap.containsKey(record.StageName)){
                stagePipelineTotalMap.get(record.StageName).q1CYRev += newPipelineInfo.q1CYRev;
                stagePipelineTotalMap.get(record.StageName).q2CYRev += newPipelineInfo.q2CYRev;
                stagePipelineTotalMap.get(record.StageName).q3CYRev += newPipelineInfo.q3CYRev;
                stagePipelineTotalMap.get(record.StageName).q4CYRev += newPipelineInfo.q4CYRev;
                stagePipelineTotalMap.get(record.StageName).totalCYRev += newPipelineInfo.totalCYRev;
                stagePipelineTotalMap.get(record.StageName).q1NYRev += newPipelineInfo.q1NYRev;
                stagePipelineTotalMap.get(record.StageName).q2NYRev += newPipelineInfo.q2NYRev;
                stagePipelineTotalMap.get(record.StageName).q3NYRev += newPipelineInfo.q3NYRev;
                stagePipelineTotalMap.get(record.StageName).q4NYRev += newPipelineInfo.q4NYRev;
                stagePipelineTotalMap.get(record.StageName).totalNYRev += newPipelineInfo.totalNYRev;
                if (record.Amount != null && String.isNotBlank(record.StageName) && stagePipelineTotalMap.get(record.StageName).opportunityInfo.Amount != null){ //CSP-2972 SIVA VANKADARu 08/07/2018
                    stagePipelineTotalMap.get(record.StageName).opportunityInfo.Amount += record.Amount;//2972
                }
                if(splitPipelineInfo != null) {

                    stagePipelineTotalMap.get(record.StageName).q1CYRev += splitPipelineInfo.q1CYRev;
                    stagePipelineTotalMap.get(record.StageName).q2CYRev += splitPipelineInfo.q2CYRev;
                    stagePipelineTotalMap.get(record.StageName).q3CYRev += splitPipelineInfo.q3CYRev;
                    stagePipelineTotalMap.get(record.StageName).q4CYRev += splitPipelineInfo.q4CYRev;
                    stagePipelineTotalMap.get(record.StageName).totalCYRev += splitPipelineInfo.totalCYRev;
                    stagePipelineTotalMap.get(record.StageName).q1NYRev += splitPipelineInfo.q1NYRev;
                    stagePipelineTotalMap.get(record.StageName).q2NYRev += splitPipelineInfo.q2NYRev;
                    stagePipelineTotalMap.get(record.StageName).q3NYRev += splitPipelineInfo.q3NYRev;
                    stagePipelineTotalMap.get(record.StageName).q4NYRev += splitPipelineInfo.q4NYRev;
                    stagePipelineTotalMap.get(record.StageName).totalNYRev += splitPipelineInfo.totalNYRev;
                    if (splitPipelineInfo.opportunityInfo.Amount != null){ //CSP-2972 SIVA VANKADARu 08/07/2018
                        stagePipelineTotalMap.get(record.StageName).opportunityInfo.Amount += splitPipelineInfo.opportunityInfo.Amount;
                    }
                }
            }else{
                PipelineInfo totalPipelineInfo = new PipelineInfo();
                totalPipelineInfo.opportunityInfo.StageName = record.StageName + ' Total:';
                totalPipelineInfo.q1CYRev = newPipelineInfo.q1CYRev;
                totalPipelineInfo.q2CYRev = newPipelineInfo.q2CYRev;
                totalPipelineInfo.q3CYRev = newPipelineInfo.q3CYRev;
                totalPipelineInfo.q4CYRev = newPipelineInfo.q4CYRev;
                totalPipelineInfo.totalCYRev = newPipelineInfo.totalCYRev;
                totalPipelineInfo.q1NYRev = newPipelineInfo.q1NYRev;
                totalPipelineInfo.q2NYRev = newPipelineInfo.q2NYRev;
                totalPipelineInfo.q3NYRev = newPipelineInfo.q3NYRev;
                totalPipelineInfo.q4NYRev = newPipelineInfo.q4NYRev;
                totalPipelineInfo.totalNYRev = newPipelineInfo.totalNYRev;
                if (record.Amount != null){ //CSP-2972 SIVA VANKADARu 08/07/2018
                    totalPipelineInfo.opportunityInfo.Amount = record.Amount;
                }
                
                if(splitPipelineInfo != null) {
                    totalPipelineInfo.q1CYRev += splitPipelineInfo.q1CYRev;
                    totalPipelineInfo.q2CYRev += splitPipelineInfo.q2CYRev;
                    totalPipelineInfo.q3CYRev += splitPipelineInfo.q3CYRev;
                    totalPipelineInfo.q4CYRev += splitPipelineInfo.q4CYRev;
                    totalPipelineInfo.totalCYRev += splitPipelineInfo.totalCYRev;
                    totalPipelineInfo.q1NYRev += splitPipelineInfo.q1NYRev;
                    totalPipelineInfo.q2NYRev += splitPipelineInfo.q2NYRev;
                    totalPipelineInfo.q3NYRev += splitPipelineInfo.q3NYRev;
                    totalPipelineInfo.q4NYRev += splitPipelineInfo.q4NYRev;
                    totalPipelineInfo.totalNYRev += splitPipelineInfo.totalNYRev;
                    if (splitPipelineInfo.opportunityInfo.Amount != null){//CSP-2972 SIVA VANKADARu 08/07/2018
                        totalPipelineInfo.opportunityInfo.Amount += splitPipelineInfo.opportunityInfo.Amount;
                    }
                }

                stagePipelineTotalMap.put(record.StageName, totalPipelineInfo);
            }

            if(salesRepTotalMap.containsKey(currentOwner)){
                salesRepTotalMap.get(currentOwner).q1CYRev += newPipelineInfo.q1CYRev;
                salesRepTotalMap.get(currentOwner).q2CYRev += newPipelineInfo.q2CYRev;
                salesRepTotalMap.get(currentOwner).q3CYRev += newPipelineInfo.q3CYRev;
                salesRepTotalMap.get(currentOwner).q4CYRev += newPipelineInfo.q4CYRev;
                salesRepTotalMap.get(currentOwner).totalCYRev += newPipelineInfo.totalCYRev;
                salesRepTotalMap.get(currentOwner).q1NYRev += newPipelineInfo.q1NYRev;
                salesRepTotalMap.get(currentOwner).q2NYRev += newPipelineInfo.q2NYRev;
                salesRepTotalMap.get(currentOwner).q3NYRev += newPipelineInfo.q3NYRev;
                salesRepTotalMap.get(currentOwner).q4NYRev += newPipelineInfo.q4NYRev;
                salesRepTotalMap.get(currentOwner).totalNYRev += newPipelineInfo.totalNYRev;
                if (record.Amount != null && salesRepTotalMap.get(currentOwner).opportunityInfo.Amount != null){//CSP-2972 SIVA VANKADARu 08/07/2018
                    salesRepTotalMap.get(currentOwner).opportunityInfo.Amount += record.Amount;
                }
            }else{
                PipelineInfo salesRepTotalInfo = new PipelineInfo();
                salesRepTotalInfo.q1CYRev = newPipelineInfo.q1CYRev;
                salesRepTotalInfo.q2CYRev = newPipelineInfo.q2CYRev;
                salesRepTotalInfo.q3CYRev = newPipelineInfo.q3CYRev;
                salesRepTotalInfo.q4CYRev = newPipelineInfo.q4CYRev;
                salesRepTotalInfo.totalCYRev = newPipelineInfo.totalCYRev;
                salesRepTotalInfo.q1NYRev = newPipelineInfo.q1NYRev;
                salesRepTotalInfo.q2NYRev = newPipelineInfo.q2NYRev;
                salesRepTotalInfo.q3NYRev = newPipelineInfo.q3NYRev;
                salesRepTotalInfo.q4NYRev = newPipelineInfo.q4NYRev;
                salesRepTotalInfo.totalNYRev = newPipelineInfo.totalNYRev;
                salesRepTotalInfo.opportunityInfo.Amount = record.Amount;
                salesRepTotalMap.put(currentOwner, salesRepTotalInfo);
            }

            if(splitPipelineInfo != null) {
                String splitUserName = splitPipelineInfo.opportunityInfo.SplitRep__r.Name;
                if(salesRepTotalMap.containsKey(splitUserName)) {
                    salesRepTotalMap.get(splitUserName).q1CYRev += splitPipelineInfo.q1CYRev;
                    salesRepTotalMap.get(splitUserName).q2CYRev += splitPipelineInfo.q2CYRev;
                    salesRepTotalMap.get(splitUserName).q3CYRev += splitPipelineInfo.q3CYRev;
                    salesRepTotalMap.get(splitUserName).q4CYRev += splitPipelineInfo.q4CYRev;
                    salesRepTotalMap.get(splitUserName).totalCYRev += splitPipelineInfo.totalCYRev;
                    salesRepTotalMap.get(splitUserName).q1NYRev += splitPipelineInfo.q1NYRev;
                    salesRepTotalMap.get(splitUserName).q2NYRev += splitPipelineInfo.q2NYRev;
                    salesRepTotalMap.get(splitUserName).q3NYRev += splitPipelineInfo.q3NYRev;
                    salesRepTotalMap.get(splitUserName).q4NYRev += splitPipelineInfo.q4NYRev;
                    salesRepTotalMap.get(splitUserName).totalNYRev += splitPipelineInfo.totalNYRev;
                    if (splitPipelineInfo.opportunityInfo.Amount != null){//CSP-2972 SIVA VANKADARu 08/07/2018
                        salesRepTotalMap.get(splitUserName).opportunityInfo.Amount += splitPipelineInfo.opportunityInfo.Amount;
                    }
                } else {
                    PipelineInfo splitRepTotalInfo = new PipelineInfo();
                    splitRepTotalInfo.q1CYRev = splitPipelineInfo.q1CYRev;
                    splitRepTotalInfo.q2CYRev = splitPipelineInfo.q2CYRev;
                    splitRepTotalInfo.q3CYRev = splitPipelineInfo.q3CYRev;
                    splitRepTotalInfo.q4CYRev = splitPipelineInfo.q4CYRev;
                    splitRepTotalInfo.totalCYRev = splitPipelineInfo.totalCYRev;
                    splitRepTotalInfo.q1NYRev = splitPipelineInfo.q1NYRev;
                    splitRepTotalInfo.q2NYRev = splitPipelineInfo.q2NYRev;
                    splitRepTotalInfo.q3NYRev = splitPipelineInfo.q3NYRev;
                    splitRepTotalInfo.q4NYRev = splitPipelineInfo.q4NYRev;
                    splitRepTotalInfo.totalNYRev = splitPipelineInfo.totalNYRev;
                    if (splitPipelineInfo.opportunityInfo.Amount != null){//CSP-2972 SIVA VANKADARu 08/07/2018
                        splitRepTotalInfo.opportunityInfo.Amount = splitPipelineInfo.opportunityInfo.Amount;
                    }
                    salesRepTotalMap.put(splitUserName, splitRepTotalInfo);
                }
            }
                
        }

        // Add final Stage Total for last loop
        if(String.isNotBlank(currentStage) && String.isNotBlank(currentOwner)){
            salesRepPipelineMap.get(currentOwner).add(stagePipelineTotalMap.get(currentStage));
        }

        List<String> salesRepKeyList = new List<String>(salesRepPipelineMap.keySet());
        for(Integer i = 0; i < salesRepKeyList.size(); i++) {
            List<PipelineInfo> salesRepLineInfoList = salesRepPipelineMap.get(salesRepKeyList[i]);

            salesRepLineInfoList.sort();

            String previousStage;
            PipelineInfo totalInfo = new PipelineInfo();
            for(Integer j = 0; j < salesRepLineInfoList.size(); j++) {
                PipelineInfo currentInfo = salesRepLineInfoList[j];

                // Initialize previousStage and totalInfo variables on first iteration.
                if(previousStage == null) {
                    previousStage = currentInfo.opportunityInfo.StageName;

                    totalInfo.q1CYRev += currentInfo.q1CYRev;
                    totalInfo.q2CYRev += currentInfo.q2CYRev;
                    totalInfo.q3CYRev += currentInfo.q3CYRev;
                    totalInfo.q4CYRev += currentInfo.q4CYRev;
                    totalInfo.totalCYRev += currentInfo.totalCYRev;
                    totalInfo.q1NYRev += currentInfo.q1NYRev;
                    totalInfo.q2NYRev += currentInfo.q2NYRev;
                    totalInfo.q3NYRev += currentInfo.q3NYRev;
                    totalInfo.q4NYRev += currentInfo.q4NYRev;
                    totalInfo.totalNYRev += currentInfo.totalNYRev;
                    if (currentInfo.opportunityInfo.Amount != null){//CSP-2972 SIVA VANKADARu 08/07/2018
                        totalInfo.opportunityInfo.Amount = totalInfo.opportunityInfo.Amount == null ? currentInfo.opportunityInfo.Amount : totalInfo.opportunityInfo.Amount + currentInfo.opportunityInfo.Amount;
                    }
                    totalInfo.opportunityInfo.StageName = previousStage + ' Total:';
                    continue;
                }

                // If the current stage and previous stage are identical then add values and continue
                if(currentInfo.opportunityInfo.StageName == previousStage) {
                    totalInfo.q1CYRev += currentInfo.q1CYRev;
                    totalInfo.q2CYRev += currentInfo.q2CYRev;
                    totalInfo.q3CYRev += currentInfo.q3CYRev;
                    totalInfo.q4CYRev += currentInfo.q4CYRev;
                    totalInfo.totalCYRev += currentInfo.totalCYRev;
                    totalInfo.q1NYRev += currentInfo.q1NYRev;
                    totalInfo.q2NYRev += currentInfo.q2NYRev;
                    totalInfo.q3NYRev += currentInfo.q3NYRev;
                    totalInfo.q4NYRev += currentInfo.q4NYRev;
                    totalInfo.totalNYRev += currentInfo.totalNYRev;
                    If ( currentInfo.opportunityInfo.Amount != null ) {//CSP-2972 SIVA VANKADARu 08/07/2018
                        totalInfo.opportunityInfo.Amount = totalInfo.opportunityInfo.Amount == null ? currentInfo.opportunityInfo.Amount : totalInfo.opportunityInfo.Amount + currentInfo.opportunityInfo.Amount;
                    }
                } else if(currentInfo.opportunityInfo.StageName == totalInfo.opportunityInfo.StageName) {
                    // Last line item where the previous stage before the end of the list only had a single stage entry
                    // requires this logic as there is not another stage to check against and add to.

                    if(salesRepLineInfoList.size() - 1 == j && totalInfo.opportunityInfo.Amount == null) {
                        totalInfo.q1CYRev += salesRepLineInfoList[j-1].q1CYRev;
                        totalInfo.q2CYRev += salesRepLineInfoList[j-1].q2CYRev;
                        totalInfo.q3CYRev += salesRepLineInfoList[j-1].q3CYRev;
                        totalInfo.q4CYRev += salesRepLineInfoList[j-1].q4CYRev;
                        totalInfo.totalCYRev += salesRepLineInfoList[j-1].totalCYRev;
                        totalInfo.q1NYRev += salesRepLineInfoList[j-1].q1NYRev;
                        totalInfo.q2NYRev += salesRepLineInfoList[j-1].q2NYRev;
                        totalInfo.q3NYRev += salesRepLineInfoList[j-1].q3NYRev;
                        totalInfo.q4NYRev += salesRepLineInfoList[j-1].q4NYRev;
                        totalInfo.totalNYRev += salesRepLineInfoList[j-1].totalNYRev;
                        If ( salesRepLineInfoList[j-1].opportunityInfo.Amount != null ) {//CSP-2972 SIVA VANKADARu 08/07/2018
                            totalInfo.opportunityInfo.Amount = totalInfo.opportunityInfo.Amount == null ? salesRepLineInfoList[j-1].opportunityInfo.Amount : totalInfo.opportunityInfo.Amount + salesRepLineInfoList[j-1].opportunityInfo.Amount;
                        }
                    }

                    // Overwrite current total with the newly calculated totalInfo
                    salesRepLineInfoList[j] = totalInfo;
                    previousStage = totalInfo.opportunityInfo.StageName;
                    continue;
                } else if(previousStage != currentStage){
                    // If a split exists for a split owner but there is no total generated during the
                    // initial data creation phase then generate a total line item.
                    if(previousStage.indexOf('Total:') < 0) {
                        salesRepLineInfoList.add(j, totalInfo);
                        totalInfo = new PipelineInfo();
                        totalInfo.opportunityInfo.StageName = currentInfo.opportunityInfo.StageName + ' Total:';
                        previousStage = currentInfo.opportunityInfo.StageName;
                        continue;
                    }

                    totalInfo = new PipelineInfo();
                    totalInfo.opportunityInfo.StageName = currentInfo.opportunityInfo.StageName + ' Total:';

                    totalInfo.q1CYRev += currentInfo.q1CYRev;
                    totalInfo.q2CYRev += currentInfo.q2CYRev;
                    totalInfo.q3CYRev += currentInfo.q3CYRev;
                    totalInfo.q4CYRev += currentInfo.q4CYRev;
                    totalInfo.totalCYRev += currentInfo.totalCYRev;
                    totalInfo.q1NYRev += currentInfo.q1NYRev;
                    totalInfo.q2NYRev += currentInfo.q2NYRev;
                    totalInfo.q3NYRev += currentInfo.q3NYRev;
                    totalInfo.q4NYRev += currentInfo.q4NYRev;
                    totalInfo.totalNYRev += currentInfo.totalNYRev;
                    If ( currentInfo.opportunityInfo.Amount != null ) {//CSP-2972 SIVA VANKADARu 08/07/2018
                        totalInfo.opportunityInfo.Amount = totalInfo.opportunityInfo.Amount == null ? currentInfo.opportunityInfo.Amount : totalInfo.opportunityInfo.Amount + currentInfo.opportunityInfo.Amount;
                    }
                }

                previousStage = currentInfo.opportunityInfo.StageName;
            }

            salesRepPipelineMap.put(salesRepKeyList[i], salesRepLineInfoList);
        }

        
    }

    private PipelineInfo buildQuarterData(OpportunityLineItem opli, PipelineInfo pipeline, Boolean isSplit){
        Boolean sameYear = opli.Start_Date__c.year() == opli.End_Date__c.year();
        Integer monthsBetween = opli.Start_Date__c.monthsBetween(opli.End_Date__c);
        Double daysBetween = opli.Start_Date__c.daysBetween(opli.End_Date__c);
        String beginningQuarter = monthQuarterMap.get(opli.Start_Date__c.month());
        String endingQuarter = monthQuarterMap.get(opli.End_Date__c.month());

        if(monthsBetween == 0){
            // logic in section complete
            if(filterStartDate.year() == opli.Start_Date__c.year()){
                if(beginningQuarter == 'q1'){
                    pipeline.q1CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q2'){
                    pipeline.q2CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q3'){
                    pipeline.q3CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q4'){
                    pipeline.q4CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }
            }else if(filterEndDate.year() == opli.Start_Date__c.year()){
                if(beginningQuarter == 'q1'){
                    pipeline.q1NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q2'){
                    pipeline.q2NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q3'){
                    pipeline.q3NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }else if(beginningQuarter == 'q4'){
                    pipeline.q4NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) : determineSplit(opli, isSplit, viewType);
                }
            }
        }else if(sameYear){
            // logic in section complete
            for(Integer i = opli.Start_Date__c.month(); i <= opli.End_Date__c.month(); i++){
                Double accruedDays;
                if(i == opli.Start_Date__c.month()){
                    accruedDays = Date.daysInMonth(opli.Start_Date__c.year(), i) - opli.Start_Date__c.day();
                }else if(i == opli.End_Date__c.month()){
                    accruedDays = opli.End_Date__c.day();
                }else{
                    accruedDays = Date.daysInMonth(opli.Start_Date__c.year(), i);
                }

                Double accruedPercent = accruedDays / daysBetween;

                if(filterStartDate.year() == opli.Start_Date__c.year()){
                    if(monthQuarterMap.get(i) == 'q1'){
                        pipeline.q1CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q2'){
                        pipeline.q2CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q3'){
                        pipeline.q3CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q4'){
                        pipeline.q4CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }
                }else if(filterEndDate.year() == opli.Start_Date__c.year()){
                    if(monthQuarterMap.get(i) == 'q1'){
                        pipeline.q1NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q2'){
                        pipeline.q2NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q3'){
                        pipeline.q3NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }else if(monthQuarterMap.get(i) == 'q4'){
                        pipeline.q4NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                    }
                }
            }
        }else{
            //logic in section under construnction
            Integer monthValue = (opli.Start_Date__c >= filterStartDate) ? opli.Start_Date__c.month() : (opli.Start_Date__c >= filterSecondStartDate) ? opli.Start_Date__c.month() : 1;
            for(Integer yearValue = filterStartDate.year(); yearValue <= filterEndDate.year(); yearValue++){
                Boolean iterateMonth = true;
                while(iterateMonth){
                    if(opli.Start_Date__c.year() > yearValue){
                        break;
                    }

                    Double accruedDays;
                    if(monthValue == opli.Start_Date__c.month() && yearValue == opli.Start_Date__c.year()){
                        accruedDays = Date.daysInMonth(opli.Start_Date__c.year(), monthValue) - opli.Start_Date__c.day();
                    }else if(monthValue == opli.End_Date__c.month() && yearValue == opli.End_Date__c.year()){
                        accruedDays = opli.End_Date__c.day();
                    }else{
                        accruedDays = Date.daysInMonth(yearValue, monthValue);
                    }

                    Double accruedPercent = accruedDays / daysBetween;
                    if(yearValue == selectedYear && opli.Start_Date__c.year() <= yearValue){
                        if(monthQuarterMap.get(monthValue) == 'q1'){
                            pipeline.q1CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q2'){
                            pipeline.q2CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q3'){
                            pipeline.q3CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q4'){
                            pipeline.q4CYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }
                    }else if(selectedYear + 1 == yearValue && opli.End_Date__c.year() >= yearValue){
                        if(monthQuarterMap.get(monthValue) == 'q1'){
                            pipeline.q1NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q2'){
                            pipeline.q2NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q3'){
                            pipeline.q3NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }else if(monthQuarterMap.get(monthValue) == 'q4'){
                            pipeline.q4NYRev += accountExecutive && String.isNotBlank(opli.Opportunity.SplitRep__c) ? determineSplit(opli, CURRENT_USER_ID) * accruedPercent : determineSplit(opli, isSplit, viewType) * accruedPercent;
                        }
                    }

                    if(yearValue != opli.End_Date__c.year() && monthValue == 12){
                        iterateMonth = false;
                        monthValue = 1;
                    }else if(yearValue == opli.End_Date__c.year() && monthValue == opli.End_Date__c.month()){
                        iterateMonth = false;
                    }else{
                        monthValue++;
                    }
                }
            }
        }

        return pipeline;
    }

    /**
     *   Method used to calculate the splits using a parent Opportunity record and the child opportunity
     *   line item values.
     *   
     *   @author Justin
     *   @param  {OpportunityLineItem}  currentLineItem OpportunityLineItem used for logic and calculations
     *   @param  {Id}  currentUserId                    The Id of the current running user
     *   @return {Decimal}                              The calculated split value
     */
    private static Decimal determineSplit(OpportunityLineItem currentLineItem, Id currentUserId) {
        // Edge case - just used for NPE avoidance within method
        if(currentLineItem == null || String.isBlank(currentUserId)) {
            return null;
        }

        /*
            If the current running User is the owner of the parent Opportunity and the Primary Rep % field
            is not null then use this field to determine split value.

            If the current running User is the Split Rep of the parent Opportunity and the Split Rep % field
            is not null then use this field to determine split values.
         */
        if(currentLineItem.Opportunity.OwnerId == currentUserId && currentLineItem.Opportunity.Primary_Rep_p__c != null) {
            return currentLineItem.TotalPrice * (currentLineItem.Opportunity.Primary_Rep_p__c / 100);
        } else if(currentLineItem.Opportunity.SplitRep__c == currentUserId && currentLineItem.Opportunity.Split_Rep_p__c != null) {
            return currentLineItem.TotalPrice * (currentLineItem.Opportunity.Split_Rep_p__c / 100);
        }

        // Fallback to just return original value
        return currentLineItem.TotalPrice;
    }

    // FOR USE WITH MANAGER VIEW
    private static Decimal determineSplit(OpportunityLineItem currentLineItem, Boolean isSplit, String currentView) {
        // Edge case - just used for NPE avoidance within method
        if(currentLineItem == null) {
            return null;
        }

        if(String.isBlank(currentLineItem.Opportunity.SplitRep__c) || currentView == 'stage') {
            return currentLineItem.TotalPrice;
        } 

        if(!isSplit && currentLineItem.Opportunity.Primary_Rep_p__c != null) {
            return currentLineItem.TotalPrice * (currentLineItem.Opportunity.Primary_Rep_p__c / 100);
        } else if(isSplit && currentLineItem.Opportunity.Split_Rep_p__c != null) {
            return currentLineItem.TotalPrice * (currentLineItem.Opportunity.Split_Rep_p__c / 100);
        }

        return currentLineItem.TotalPrice;
    }

    private static Decimal determineAmountSplit(Opportunity currentOpportunity, Id currentUserId) {
        // Edge case - just used for NPE avoidance within method
        if(currentOpportunity == null || String.isBlank(currentUserId)) {
            return null;
        }

        if(currentOpportunity.OwnerId == currentUserId && currentOpportunity.Primary_Rep_p__c != null) {
            return currentOpportunity.Amount * (currentOpportunity.Primary_Rep_p__c / 100);
        } else if(currentOpportunity.SplitRep__c == currentUserId && currentOpportunity.Split_Rep_p__c != null) {
            return currentOpportunity.Amount * (currentOpportunity.Split_Rep_p__c / 100);
        }

        return currentOpportunity.Amount;
    }

    global class PipelineInfo implements Comparable {
        public Opportunity opportunityInfo {get; set;}
        public Double q1CYRev {get; set;}
        public Double q2CYRev {get; set;}
        public Double q3CYRev {get; set;}
        public Double q4CYRev {get; set;}
        public Double totalCYRev {get; set;}
        public Double q1NYRev {get; set;}
        public Double q2NYRev {get; set;}
        public Double q3NYRev {get; set;}
        public Double q4NYRev {get; set;}
        public Double totalNYRev {get; set;}

        public PipelineInfo(){
            opportunityInfo = new Opportunity();
            q1CYRev = 0;
            q2CYRev = 0;
            q3CYRev = 0;
            q4CYRev = 0;
            totalCYRev = 0;
            q1NYRev = 0;
            q2NYRev = 0;
            q3NYRev = 0;
            q4NYRev = 0;
            totalNYRev = 0;
        }

        global Integer compareTo(Object compareToInfo) {
            PipeLineInfo compareToPipe = (PipeLineInfo)compareToInfo;

            if(opportunityInfo.StageName > compareToPipe.opportunityInfo.StageName) {
                return 1;
            } else if(opportunityInfo.StageName < compareToPipe.opportunityInfo.StageName) {
                return -1;
            }

            return 0;
        }
    }

}
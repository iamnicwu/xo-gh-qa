/*
 author: Steve O'Neal
 date: 4/30/2015
 purpose: tests the ReassignOwnershipController class
 */
@isTest
private class test_ReassignOwnershipController {

    static testMethod void myUnitTest() {
        /* DUMMY DATA */
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        

        /* START TEST */
        

        ReassignOwnershipController roc = new ReassignOwnershipController();
        
        roc.isTest = true;
        roc.MaxQueries = 5;
        
        try
        {
            ReassignOwnershipControllerObject__c testIgnoreObjectSetting = new ReassignOwnershipControllerObject__c();
            testIgnoreObjectSetting.Name = 'Fake Object';
            insert testIgnoreObjectSetting;
        }
        catch (Exception ios)
        {
        }
        
        try
        {
            ReassignOwnershipControllerField__c testIgnoreFieldSetting = new ReassignOwnershipControllerField__c();
            testIgnoreFieldSetting.Name = 'Fake Field';
            insert testIgnoreFieldSetting;
        }
        catch (Exception ifs)
        {
        }

        try
        {
            ReassignOwnershipControllerNonUser__c testNonUserSetting = new ReassignOwnershipControllerNonUser__c();
            testNonUserSetting.Name = 'testing non user setting';
            testNonUserSetting.User_Field_Name__c = 'alias';
            testNonUserSetting.Object_Name__c = 'Account';
            testNonUserSetting.Object_Field_Name__c = 'BillingStateCode';
            insert testNonUserSetting;
        }
        catch (Exception ocnu)
        {
        }

        try
        {
            ReassignOwnershipControllerOpenClosedObj__c testOpenCloseSetting = new ReassignOwnershipControllerOpenClosedObj__c();
            testOpenCloseSetting.Name = 'Case';
            testOpenCloseSetting.Closed_SOQL_Statement__c = 'isclosed = true';
            testOpenCloseSetting.Open_SOQL_Statement__c = 'isclosed = false';
            insert testOpenCloseSetting;
        }
        catch (Exception oco)
        {
        }

        roc.LoadConfiguration();

        // try a search with no information to bubble the error
        roc.searchRecords();
        
        // try a search with information
        roc.ownerHolder.OwnerId = userinfo.getuserID();
        roc.SearchOnlyOwnershipFields = true;
        roc.SearchClosedRecords = true;
        roc.SearchOpenRecords = true;
        roc.searchRecords();
        
        // remove the ownership field filter so we can get more code coverage
        roc.SearchOnlyOwnershipFields = false;
        roc.searchRecords();
        
        // try requerying
        roc.requeryFillObjectMap();
        
        // reassign
        for (ReassignOwnershipController.SearchableField field : roc.AllObjects)
        {
            if (field.textField)
            {
                field.selectedUserHolder.Name = 'abcd';
            }
            else
            {
                field.selectedUserHolder.OwnerId = userInfo.getUserId();
            }
        }
        
        roc.save();
        
        
    }
    
    static testMethod void test_method_two() {
        /* DUMMY DATA */
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Account testaccount = (Account)testData.get('Account');

        ReassignOwnershipController roc = new ReassignOwnershipController();
        
        roc.isTest = true;
        roc.MaxQueries = 5;
        
        try
        {
            ReassignOwnershipControllerObject__c testIgnoreObjectSetting = new ReassignOwnershipControllerObject__c();
            testIgnoreObjectSetting.Name = 'Fake Object';
            insert testIgnoreObjectSetting;
        }
        catch (Exception ios)
        {
        }
        
        try
        {
            ReassignOwnershipControllerField__c testIgnoreFieldSetting = new ReassignOwnershipControllerField__c();
            testIgnoreFieldSetting.Name = 'Fake Field';
            insert testIgnoreFieldSetting;
        }
        catch (Exception ifs)
        {
        }

        try
        {
            ReassignOwnershipControllerNonUser__c testNonUserSetting = new ReassignOwnershipControllerNonUser__c();
            testNonUserSetting.Name = 'testing non user setting';
            testNonUserSetting.User_Field_Name__c = 'alias';
            testNonUserSetting.Object_Name__c = 'Account';
            testNonUserSetting.Object_Field_Name__c = 'BillingStateCode';
            insert testNonUserSetting;
        }
        catch (Exception ocnu)
        {
        }

        try
        {
            ReassignOwnershipControllerOpenClosedObj__c testOpenCloseSetting = new ReassignOwnershipControllerOpenClosedObj__c();
            testOpenCloseSetting.Name = 'Case';
            testOpenCloseSetting.Closed_SOQL_Statement__c = 'isclosed = true';
            testOpenCloseSetting.Open_SOQL_Statement__c = 'isclosed = false';
            insert testOpenCloseSetting;
        }
        catch (Exception oco)
        {
        }
        
        // reassign
        for (ReassignOwnershipController.SearchableField field : roc.AllObjects)
        {
            if (field.textField)
            {
                field.selectedUserHolder.Name = 'abcd';
            }
            else
            {
                field.selectedUserHolder.OwnerId = userInfo.getUserId();
            }
        }
        
        
        // search by object
        roc.LoadConfiguration();
        roc.searchBy = 'object';
        roc.searchRecords();
        roc.selectedObject = 'Account';
        roc.searchRecords();
        roc.selectedField = 'Id';
        roc.selectedOperator = '=';
        roc.selectedValue = testAccount.Id;
        roc.searchRecords();
        
        // excercise some error handling
        roc.parentQuery += 'llll';
        roc.searchRecords();        
        
        // excercise some public functions
        //roc.getSearchableObjects();
        roc.selectedObject = 'Opportunity';
        string selObject = roc.selectedObject;
        boolean bShowNoResults = roc.ShowNoResults;
        roc.getSearchableFields();
        // try all three versions of the operator list
        roc.selectedField = 'IsClosed';
        roc.getOperators();
        roc.selectedField = 'CreatedDate';
        roc.getOperators();
        roc.selectedField = 'Name';
        roc.getOperators();
        
        string tmpVal;
        roc.selectedField = null;
        roc.searchRecords();
        tmpVal = roc.errSelectedField;
        roc.selectedObject = null;
        roc.searchRecords();
        tmpVal = roc.errSelectedObject;
        tmpVal = roc.errSelectedOperator;
        tmpVal = roc.errSelectedValue;        
        tmpVal = roc.errParentQuery;
        tmpVal = roc.getNow();
        tmpVal = roc.getCurrentSearchBy();
        boolean tmpBool = roc.ShowResults;
        
        
    }
    
    static testMethod void test_method_Three() {
        /* DUMMY DATA */
        Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();


        ReassignOwnershipController roc = new ReassignOwnershipController();
        ReassignOwnershipController.SearchableField SearchableField1 = new ReassignOwnershipController.SearchableField();
        //SearchableField1.
        roc.allObjects.add(SearchableField1);
        roc.requeryFillObjectMap();
        roc.Save();
        Folder targetFolder = new Folder();
        roc.SaveLogFile('test','test',targetFolder);
        
        
        roc.allObjects[0].textField = true;
        roc.allObjects[0].selectedUserHolder.Name = 'name';
        
        ReassignOwnershipController.SearchableField SearchableField2 = new ReassignOwnershipController.SearchableField();
        SearchableField2.textField = false;
        SearchableField2.selectedUserHolder.OwnerId = userinfo.getuserId();
        SearchableField2.fieldName = 'name';
        account acc = new account();
        SearchableField2.objectList.add(acc );
        
        roc.allObjects.add(SearchableField2);
        roc.Save();
        
        
    }
}
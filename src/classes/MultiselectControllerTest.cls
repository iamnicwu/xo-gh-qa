@isTest
private class MultiselectControllerTest{
    @isTest static void test_method_one() {
        MultiselectController testcase = new MultiselectController(); 
        //testcase.saveSalesRepRecord();
        testcase.leftOptions = new List<SelectOption>();
        testcase.leftOptions.add(new SelectOption('test','test'));
        testcase.rightOptions = new List<SelectOption>();
        testcase.rightOptions.add(new SelectOption('test','test'));
        
        testcase.leftOptionsHidden ='test&test&test';
        testcase.rightOptionsHidden = 'test';
    }
}
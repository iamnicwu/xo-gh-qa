@isTest
private class ComponentControllerBaseTest{
    
    @isTest static void test_method_one(){
        ComponentControllerBase CCB = new ComponentControllerBase();
        PageControllerBase PCB = new PageControllerBase();
        CCB.thePageController = PCB;
    }
}
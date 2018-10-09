@isTest
private class PageControllerBaseTest{
    @isTest static void test_method_one(){
        PageControllerBase pcb = new PageControllerBase();
        ComponentControllerBase ccb = new ComponentControllerBase();
        ccb = pcb.getMyComponentController();
        pcb.setComponentController(ccb );
        pcb = pcb.getThis();
    }
}
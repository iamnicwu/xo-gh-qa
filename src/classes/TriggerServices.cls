public without sharing class TriggerServices 
{
    public static void runTriggerWorkflow(ITriggerWorkflow itwf)
    {
        itwf.execute();
    }
}
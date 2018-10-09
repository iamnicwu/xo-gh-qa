/* 
<class>
    <name>OpportunityCloseController</name>
    <purpose>Supports OpportunityClose.page to add functionality specific to closing an Opportunity, like prompting for the actual close date,
             forcing them to select an appropriate stage, and prompting for the Lost Reason, where applicable.</purpose>
    <created>
        <by>Steve O'Neal</by>
        <date>5/26/2015</date>
        <ticket>SF-457</ticket>
        <ticket>SF-470</ticket>
    </created>
</class>
*/
public with sharing class OpportunityCloseController 
{
    private final Opportunity opp;
    private id oppId;
    private List<OpportunityStage> opportunityStages;
    
    /* 
    <method>
        <name>getOpp</name>
        <returns>Opportunity passed from the standard Opportunity page</returns>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-470</ticket>
        </created>
    </method>
    */
    public Opportunity getOpp()
    {
        return opp;
    }
    
    /* 
    <method>
        <name>getStageCloseOptions</name>
        <returns>List of StageName picklist values that are marked to close an Opportunity</returns>
        <purpose>Allows the page to display picklist items that are outside the standard functionlity due to the selected Sales Process</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
        </created>
    </method>
    */
    public List<SelectOption> getStageCloseOptions()
    {
        List<SelectOption> retVal = new List<SelectOption>();
        
        retVal.add(new SelectOption('','--None--'));
        
        for (OpportunityStage stage : opportunityStages)
        {
            retVal.add(new SelectOption(stage.MasterLabel, stage.MasterLabel));
        }
        
        return retVal;
    }
    
    /* 
    <method>
        <name>OpportunityCloseController</name>
        <returns>OpportunityCloseController instance</returns>
        <purpose>Instantiates a OpportunityCloseController</purpose>
        <params>
            <param>
                <name>stdController</name>
                <purpose>Standard controller for Opportunity</purpose>
            </param>
        </params>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
        </created>
    </method>
    */
    public OpportunityCloseController(ApexPages.StandardController stdController) {
        this.oppId = stdController.getRecord().Id;
        System.Debug(this.oppId);
        
        Set<string> fieldNames = new Set<string>();
        fieldNames.add('id');
        fieldNames.add('name');
        fieldNames.add('stagename');
        
        for (FieldSetMemberExtended f : this.getCloseOpportunityAdditionalFields())
        {
            fieldNames.add(f.getFieldSetMember().getFieldPath().toLowerCase());
        }
        
        string query = 'Select ';
        string comma = '';
        for (string fieldName : fieldNames)
        {
            query += comma + fieldName;
            comma = ',';
        }
        query += ' from Opportunity';
        query += ' where id = \'' + this.oppId + '\'';
        query += ' limit 1';

        System.Debug(query);
        this.opp = database.query(query);
        
        
        opportunityStages = [select MasterLabel, Description, IsClosed, IsWon, IsActive, DefaultProbability
                               from OpportunityStage
                              where IsActive = true
                                and IsClosed = true];
    
    }
    

    /* 
    <method>
        <name>getCloseOpportunityAdditionalFields</name>
        <returns>a list of FieldSetMemberExtended, which is a FieldSetMember with the additional ability to mark Read Only</returns>
        <purpose>Used on the page to build a layout of Opportunity fields based on the Field Sets "Close Set - Fields" and "Close Set - Read Only"</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
            <ticket>SF-470</ticket>
        </created>
    </method>
    */
    public List<FieldSetMemberExtended> getCloseOpportunityAdditionalFields()
    {
        List<Schema.FieldSetMember> fsMembersCloseSet = sObjectType.Opportunity.FieldSets.Close_Set.getFields();
        List<Schema.FieldSetMember> fsMembersCloseSetReadOnly = sObjectType.Opportunity.FieldSets.Close_Set_Read_Only.getFields();
        List<FieldSetMemberExtended> retVal = new List<FieldSetMemberExtended>();
        
        for (Schema.FieldSetMember fsm : fsMembersCloseSet)
        {
            FieldSetMemberExtended newFSME = new FieldSetMemberExtended(fsm);
            
            for (Schema.FieldSetMember fsmc : fsMembersCloseSetReadOnly)
            {
                if (fsm.FieldPath == fsmc.FieldPath)
                {
                    newFSME.IsReadOnly = true;
                }
            }
            
            retVal.add(newFSME);
        }
        
        return retVal;
    }
    
    
    /* 
    <class>
        <name>FieldSetMemberExtended</name>
        <purpose>Extends the built-in FieldSetMember to allow flagging a field as Read-Only</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
            <ticket>SF-470</ticket>
        </created>
    </class>
    */
    public class FieldSetMemberExtended
    {
        /* 
        <method>
            <name>getIsRequired</name>
            <returns>True if the field is required, false if not required</returns>
            <purpose>Used to validate the field on the page layout</purpose>
            <created>
                <by>Steve O'Neal</by>
                <date>5/26/2015</date>
                <ticket>SF-457</ticket>
                <ticket>SF-470</ticket>
            </created>
        </method>
        */
        public boolean getIsRequired()
        {
            if (IsReadOnly) {return false;}
            if (fieldSetMember.Required || fieldSetMember.dbRequired) {return true;}
            return false;
        }
        
        /* 
        <method>
            <name>IsReadOnly</name>
            <returns>True if the field is read only, false if not read only</returns>
            <purpose>Used to display the field on the page layout</purpose>
            <created>
                <by>Steve O'Neal</by>
                <date>5/26/2015</date>
                <ticket>SF-457</ticket>
                <ticket>SF-470</ticket>
            </created>
        </method>
        */
        public boolean IsReadOnly
        {
            get;
            set;
        }
        
        private Schema.FieldSetMember fieldSetMember;
        
        /* 
        <method>
            <name>getFieldSetMember</name>
            <returns>The fieldSetMember based on "Close Set - Fields"</returns>
            <purpose>Used to display the field on the page layout</purpose>
            <created>
                <by>Steve O'Neal</by>
                <date>5/26/2015</date>
                <ticket>SF-457</ticket>
                <ticket>SF-470</ticket>
            </created>
        </method>
        */
        public Schema.FieldSetMember getFieldSetMember()
        {
            return this.fieldSetMember;
        }
        
        /* 
        <method>
            <name>FieldSetMemberExtended</name>
            <returns>an instance of FieldSetMemberExtended</returns>
            <purpose>Instantiates a FieldSetMemberExtended</purpose>
            <created>
                <by>Steve O'Neal</by>
                <date>5/26/2015</date>
                <ticket>SF-457</ticket>
                <ticket>SF-470</ticket>
            </created>
        </method>
        */
        public FieldSetMemberExtended(Schema.FieldSetMember fsMember)
        {
            this.fieldSetMember = fsMember;
            IsReadOnly = false;
        }
    }
    
    
    /* 
    <method>
        <name>Cancel</name>
        <returns>A pageReference back to the originating Opportunity view page</returns>
        <purpose>Called from a button on the page to return the user to the opportunity</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
            <ticket>SF-470</ticket>
        </created>
    </method>
    */
    public PageReference Cancel()
    {
        return new PageReference('/' + oppId);
    }
    
    
    /* 
    <method>
        <name>Save</name>
        <returns>A pageReference back to the originating Opportunity view page</returns>
        <purpose>Called from a button on the page to update the opportunity</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/26/2015</date>
            <ticket>SF-457</ticket>
            <ticket>SF-470</ticket>
        </created>
    </method>
    */
    public PageReference Save()
    {
        try
        {
            System.Debug(opp.StageName);
            update(opp);
            return Cancel();
        }
        catch (exception e)
        {
            ApexPages.addMessages(e);
        }
        return null;
    }

}
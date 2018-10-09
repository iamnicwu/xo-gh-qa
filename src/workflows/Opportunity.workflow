<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Account_Approved_Notification</fullName>
        <description>Account Approved Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Credit_Hold_Account_s_Opp_ApprovedHTML</template>
    </alerts>
    <alerts>
        <fullName>Account_Decline_Notification</fullName>
        <description>Account Decline Notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/Credit_Hold_Account_s_Opp_DeclinedHTML</template>
    </alerts>
    <fieldUpdates>
        <fullName>Account_set_Conc_Prog_Qual_to_Qualified</fullName>
        <field>ConciergePrgQua__c</field>
        <literalValue>Qualified for Program</literalValue>
        <name>Account set Conc Prog Qual to Qualified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Acct_Strategist_Default</fullName>
        <field>AccStrategist__c</field>
        <lookupValue>naste@xogrp.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>Acct Strategist Default</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Process_Assignment_AR</fullName>
        <description>SF-1511. When this box is checked during a Local Opp Approval Process, the OpportunityTrigger assigns the correct AR Approver to the Approval Request by (A) populating the Opp &quot;Approval_Process_AR_Lookup__c&quot; field, and (B) sending the AR Approver a task.</description>
        <field>Approval_Process_AR_Assignment__c</field>
        <literalValue>1</literalValue>
        <name>Approval Process Assignment - AR</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Process_Assignment_Cancel</fullName>
        <description>SF-1781</description>
        <field>Approval_Process_Cancel_Assignment__c</field>
        <literalValue>1</literalValue>
        <name>Approval Process Assignment - Cancel</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Approval_Process_Assignment_Manager</fullName>
        <description>SF-1506. When this box is checked during a Local Opp Approval Process, the OpportunityTrigger assigns the Opp Owner&apos;s Manager to the Approval Request by (A) populating the Opp &quot;Approval_Process_Manager_Lookup__c&quot; field, and (B) sending the Manager a task.</description>
        <field>Approval_Process_Manager_Assignment__c</field>
        <literalValue>1</literalValue>
        <name>Approval Process Assignment - Manager</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_AR_Lookup_On_Opportunity</fullName>
        <description>Clears the &quot;Approval_Process_AR_Lookup__c&quot; field on the Opportunity after Approval Process exists. Not strictly necessary, but doing so may help prevent incorrect approval process assignments in the event a resubmission.</description>
        <field>Approval_Process_AR_Lookup__c</field>
        <name>Clear AR Lookup On Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Cancel_Lookup_On_Opportunity</fullName>
        <description>Clears the &quot;Approval_Process_Cancel_Lookup__c&quot; field on the Opportunity after Approval Process exists. Not strictly necessary, but doing so may help prevent incorrect approval process assignments in the event a resubmission.</description>
        <field>Approval_Process_Cancel_Lookup__c</field>
        <name>Clear Cancel Lookup On Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Manager_Lookup_On_Opportunity</fullName>
        <description>Clears the &quot;Approval_Process_Manager_Lookup__c&quot; field on the Opportunity after Approval Process exists. Not strictly necessary, but doing so may help prevent incorrect approval process assignments in the event a resubmission.</description>
        <field>Approval_Process_Manager_Lookup__c</field>
        <name>Clear Manager Lookup On Opportunity</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Concierge_Record_Type_Update</fullName>
        <field>RecordTypeId</field>
        <lookupValue>Local</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Concierge Record Type Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUOppReqOnboardAcc</fullName>
        <description>Phase 1</description>
        <field>ConciergePrgQua__c</field>
        <literalValue>Requires Onboarding</literalValue>
        <name>FU_OppReqOnboardAcc</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_AccDisQuaOpp</fullName>
        <description>Phase 1 - When Opportunity is Closed Lost, Account will be Disqualified from Prgrom</description>
        <field>ConciergePrgQua__c</field>
        <literalValue>Disqualified from Program</literalValue>
        <name>FU_AccDisQuaOpp</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_OppRecordTypeNational</fullName>
        <description>Phase 1 for National</description>
        <field>RecordTypeId</field>
        <lookupValue>National</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>FU_OppRecordTypeNational</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_OpportunityRename</fullName>
        <description>Set the Opportunity name on creation</description>
        <field>Name</field>
        <formula>RecordType.DeveloperName &amp; &apos; - &apos; &amp;  LEFT(Account.Name,40) &amp; &apos; - &apos; &amp;  TEXT(MONTH(DATEVALUE(CreatedDate))) &amp; &apos;/&apos; &amp; TEXT(YEAR(DATEVALUE(CreatedDate)))</formula>
        <name>FU_OpportunityRename</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_StageProspect</fullName>
        <description>Phase 1.0.5 Concierge</description>
        <field>StageName</field>
        <literalValue>Prospecting</literalValue>
        <name>FU_StageProspect</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lock_Quotes</fullName>
        <field>Lock_Quotes__c</field>
        <literalValue>1</literalValue>
        <name>Lock Quotes</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_Stage_Calculating_TCV</fullName>
        <field>StageName</field>
        <literalValue>Calculating TCV</literalValue>
        <name>Opp Stage Calculating TCV</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_Stage_Pending_Internal_Approval</fullName>
        <field>StageName</field>
        <literalValue>Pending Internal Approval</literalValue>
        <name>Opp Stage Pending Internal Approval.</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opp_Stage_Ready_for_Echosign</fullName>
        <field>StageName</field>
        <literalValue>Ready for Echo-Sign</literalValue>
        <name>Opp Stage Ready for Echosign</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Primary_Rep_Default</fullName>
        <field>Primary_Rep_p__c</field>
        <formula>1</formula>
        <name>Primary Rep % Default</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Account_conc_qual_to_Qualified</fullName>
        <description>Set the Concierge Program Status field to &quot;Qualified for Program&quot;</description>
        <field>ConciergePrgQua__c</field>
        <literalValue>Qualified for Program</literalValue>
        <name>Set Account conc qual to Qualified</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>AccountId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Close_Date_to_Actual_Close_Date</fullName>
        <field>CloseDate</field>
        <formula>Actual_Close_Date__c</formula>
        <name>Set Close Date to Actual Close Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Date_Qualifying</fullName>
        <field>Date_Qualifying__c</field>
        <formula>TODAY()</formula>
        <name>Set Date Qualifying</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_NeedToSendToZBilling_To_True</fullName>
        <description>(CSP-634) Set the Opportunity.NeedToSendToZBilling__c field to true</description>
        <field>NeedToSendToZBilling__c</field>
        <literalValue>1</literalValue>
        <name>Set NeedToSendToZBilling To True</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Opp_Stage_to_Client_Approved</fullName>
        <field>StageName</field>
        <literalValue>Client Approved</literalValue>
        <name>Set Opp Stage to Client Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Opp_Stage_to_Quoting</fullName>
        <field>StageName</field>
        <literalValue>Quoting</literalValue>
        <name>Set Opp Stage to Quoting</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Stage_Date_Closing</fullName>
        <field>Date_Closing__c</field>
        <formula>Today()</formula>
        <name>Set Stage Date Closing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Stage_Date_Developing</fullName>
        <field>Date_Developing__c</field>
        <formula>TODAY()</formula>
        <name>Set Stage Date Developing</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_the_send_to_z_billing_date</fullName>
        <field>Send_To_Z_Billing_Triggered_On__c</field>
        <formula>NOW()</formula>
        <name>Set the send to z-billing date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Setting_Record_locked_field</fullName>
        <field>Is_Record_Locked__c</field>
        <literalValue>1</literalValue>
        <name>Setting Record locked field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Split_Rep_Default_Update</fullName>
        <field>Primary_Rep_p__c</field>
        <formula>0.5</formula>
        <name>Split Rep Default Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Store_Stage_Date_Client_Approved</fullName>
        <description>Store the most recent date the stage moved to &quot;Client Approved&quot;</description>
        <field>Date_Client_Approved__c</field>
        <formula>TODAY()</formula>
        <name>Store Stage Date Client Approved</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Unlock_Quotes</fullName>
        <field>Lock_Quotes__c</field>
        <literalValue>0</literalValue>
        <name>Unlock Quotes</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Unsetting_Record_Locked</fullName>
        <field>Is_Record_Locked__c</field>
        <literalValue>0</literalValue>
        <name>Unsetting Record Locked</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Local_Opp_Amount</fullName>
        <description>CSP-2948: Campaign Statistics shows no dollar value
Given a Local Opportunity, the value of the standard Amount field mirrors the value from the &quot;Total Potential Value&quot; field.</description>
        <field>Amount</field>
        <formula>Total_Potential_Value__c</formula>
        <name>Update Local Opp Amount</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_name_from_testforinsert</fullName>
        <field>Name</field>
        <formula>&quot;Removed from Renewal Queue&quot;</formula>
        <name>Update name from &quot;testforinsert&quot;</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account Strategist Default</fullName>
        <actions>
            <name>Acct_Strategist_Default</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Please_re_assign_to_an_Account_Strategist</name>
            <type>Task</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.AccStrategist__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>National</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.BU__c</field>
            <operation>notEqual</operation>
            <value>Local,Concierge</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Concierge Opp Won</fullName>
        <actions>
            <name>Set_Account_conc_qual_to_Qualified</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.IsWon</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.IsClosed</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Concierge</value>
        </criteriaItems>
        <description>When a concierge opportunity is Closed and Won, mark the account as Qualified for Program.
JIRA: SF-470</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>EchoSign Contract Not Returned - Reminder and Notification</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Pending Client Approval</value>
        </criteriaItems>
        <description>SF-1509 and SF-1502.</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>X1_Business_Day_Remaining_For</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Opportunity.EchoSign_Contract_Due_Date__c</offsetFromField>
            <timeLength>-1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
        <workflowTimeTriggers>
            <actions>
                <name>Set_Opp_Stage_to_Quoting</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>EchoSign_Deadline_Expired</name>
                <type>Task</type>
            </actions>
            <offsetFromField>Opportunity.EchoSign_Contract_Due_Date__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Local Opp Update Amount</fullName>
        <actions>
            <name>Update_Local_Opp_Amount</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-2948: Campaign Statistics shows no dollar value
Given a Local Opportunity, the value of the standard Amount field mirrors the value from the &quot;Total Potential Value&quot; field.</description>
        <formula>AND( 
OR( 
RecordType.DeveloperName == &apos;Local&apos;, 
RecordType.DeveloperName == &apos;Local_Closed_Lost&apos;, 
RecordType.DeveloperName == &apos;Local_Closed_Won&apos; 
), 
ISCHANGED( Total_Potential_Value__c ) 
)

/**
OR( 
ISNEW(), 
ISCHANGED( Total_Potential_Value__c ) 
)
**/</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opp Actual Close Date set</fullName>
        <actions>
            <name>Set_Close_Date_to_Actual_Close_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When Actual Close Date has a value, set the Close Date of the Opportunity to it.</description>
        <formula>AND(     OR(ISNEW(), ISCHANGED(Actual_Close_Date__c)),     NOT(ISBLANK(Actual_Close_Date__c))    )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Opp-concierge closed won</fullName>
        <actions>
            <name>Account_set_Conc_Prog_Qual_to_Qualified</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>When a Concierge opportunity is closed/won, mark the account as Qualified for Program</description>
        <formula>AND(     RecordType.DeveloperName = &apos;OppConcierge&apos;,     IsClosed = true,     IsWon = true    )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Opportunity moved to Client Approved</fullName>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Client Approved</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>equals</operation>
            <value>Local</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Set_NeedToSendToZBilling_To_True</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Set_the_send_to_z_billing_date</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Opportunity.LastModifiedDate</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Hours</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Primary Rep %25 Default</fullName>
        <actions>
            <name>Primary_Rep_Default</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>RecordType.Name==&apos;National&apos;&amp;&amp;ISBLANK( SplitRep__c )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Split Rep Default Rule</fullName>
        <actions>
            <name>Split_Rep_Default_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>NOT(ISBLANK( SplitRep__c )) &amp;&amp; (Primary_Rep_p__c = 1 || ISNULL(Primary_Rep_p__c))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Store Stage Date Client Approved</fullName>
        <actions>
            <name>Store_Stage_Date_Client_Approved</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Client Approved</value>
        </criteriaItems>
        <description>When an opportunity stage changes, store the date for specific stages</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Store Stage Date Closing</fullName>
        <actions>
            <name>Set_Stage_Date_Closing</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Closing</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Date_Closing__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>When an opportunity stage changes, store the date for specific stages</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Store Stage Date Developing</fullName>
        <actions>
            <name>Set_Stage_Date_Developing</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Developing</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Date_Developing__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>When an opportunity stage changes, store the date for specific stages</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Store Stage Date Qualifying</fullName>
        <actions>
            <name>Set_Date_Qualifying</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Opportunity.StageName</field>
            <operation>equals</operation>
            <value>Qualifying</value>
        </criteriaItems>
        <criteriaItems>
            <field>Opportunity.Date_Qualifying__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>When an opportunity stage changes, store the date for specific stages</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update name from %22testforinsert%22</fullName>
        <actions>
            <name>Update_name_from_testforinsert</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.Name</field>
            <operation>equals</operation>
            <value>testforinsert</value>
        </criteriaItems>
        <description>When a rep uses the renewal dashboard and &quot;removes&quot; a record, it generates an opportunity with this name, we just want to update the name</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WF_ConcOppRecordType</fullName>
        <actions>
            <name>Concierge_Record_Type_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.BU__c</field>
            <operation>equals</operation>
            <value>Local</value>
        </criteriaItems>
        <description>Concierge Opportunity Record Type logic</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WF_OppDisQuaAcc</fullName>
        <actions>
            <name>FU_AccDisQuaOpp</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>When an opportunity is Closed and Lost and the reason is Do not contact again, change the Account&apos;s concierge program status to disqualified from program.
JIRA: SF-470</description>
        <formula>AND(     RecordType.DeveloperName = &apos;OppConcierge&apos;,     IsClosed = true,     IsWon = false,     ISPICKVAL(Lost_Reason__c, &apos;Do not contact again&apos;)    )</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WF_OppRecordType</fullName>
        <actions>
            <name>FU_OppRecordTypeNational</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.BU__c</field>
            <operation>equals</operation>
            <value>National</value>
        </criteriaItems>
        <description>Phase 1 for National</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WF_OppStageProspect</fullName>
        <actions>
            <name>FU_StageProspect</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Phase 1.0.5 Concierge</description>
        <formula>IF( RecordType.Name = &quot;Opp Concierge&quot; , TRUE, FALSE)</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WF_OpportunityRename</fullName>
        <actions>
            <name>FU_OpportunityRename</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Opportunity.RecordTypeId</field>
            <operation>notEqual</operation>
            <value>National</value>
        </criteriaItems>
        <description>Whenever an Opportunity is created, set its name using a naming convention</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>EchoSign_Deadline_Expired</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Opportunity.EchoSign_Contract_Due_Date__c</offsetFromField>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>EchoSign Deadline Expired</subject>
    </tasks>
    <tasks>
        <fullName>Opportunity_Set_Back_To_Quoting</fullName>
        <assignedToType>owner</assignedToType>
        <description>Hi, 

The opportunity has been set back to Quoting. Please check if, 
1. The approver declined the opportunity (or) 
2. The client did not Sign the contract 

Please take the appropriate action.

Thanks!</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Opportunity Set Back To Quoting</subject>
    </tasks>
    <tasks>
        <fullName>Please_re_assign_to_an_Account_Strategist</fullName>
        <assignedTo>naste@xogrp.com</assignedTo>
        <assignedToType>user</assignedToType>
        <description>The Sales Rep of the related Opportunity does not have a mapped Account Strategist. Please select the proper Account Strategist and have the mapping updated.</description>
        <dueDateOffset>1</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Please re-assign to an Account Strategist</subject>
    </tasks>
    <tasks>
        <fullName>Submit_for_customer_signature</fullName>
        <assignedToType>owner</assignedToType>
        <description>Opportunity approved. Please submit for signature.</description>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>High</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>Submit for customer signature</subject>
    </tasks>
    <tasks>
        <fullName>X1_Business_Day_Remaining_For</fullName>
        <assignedToType>owner</assignedToType>
        <dueDateOffset>0</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <offsetFromField>Opportunity.EchoSign_Contract_Due_Date__c</offsetFromField>
        <priority>High</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>1 Business Day Remaining For EchoSign Deadline</subject>
    </tasks>
</Workflow>

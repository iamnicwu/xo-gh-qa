<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Custom_Content_Update_SDN_Field</fullName>
        <field>Sales_Dev_Needed__c</field>
        <literalValue>1</literalValue>
        <name>Custom Content Update SDN Field</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <reevaluateOnChange>true</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Opportunity_Stage_Proposal</fullName>
        <field>StageName</field>
        <literalValue>Stage 4: Proposal</literalValue>
        <name>Opportunity: Stage Proposal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Opportunity__c</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Opportunity_Stage_to_TS_Proposal</fullName>
        <field>StageName</field>
        <literalValue>Stage 1: TS Proposal</literalValue>
        <name>Update Opportunity Stage to TS Proposal</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
        <targetObject>Opportunity__c</targetObject>
    </fieldUpdates>
    <rules>
        <fullName>RFP Custom Content</fullName>
        <actions>
            <name>Custom_Content_Update_SDN_Field</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>(Custom_Content__c &amp;&amp; NOT(Sales_Dev_Needed__c))</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Opportunity Stage to Proposal</fullName>
        <actions>
            <name>Opportunity_Stage_Proposal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>ThoughtStarter_RFP__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>RFP</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Update Opportunity Stage to TS Proposal</fullName>
        <actions>
            <name>Update_Opportunity_Stage_to_TS_Proposal</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>ThoughtStarter_RFP__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>ThoughtStarter</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>

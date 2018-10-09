<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Checked_Disallow_Sales_Rep_On_Quotes</fullName>
        <field>Disallow_Sales_Rep_On_Quotes__c</field>
        <literalValue>1</literalValue>
        <name>Checked Disallow Sales Rep On Quotes</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Salesrep_Id_with_Salesrep_dup</fullName>
        <field>SalesRepID__c</field>
        <formula>TEXT(VALUE(SalesRep_ID_Duplicate__c) + 20000)</formula>
        <name>Update Salesrep Id with Salesrep dup</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Disallow Ops and SS On Quotes</fullName>
        <actions>
            <name>Checked_Disallow_Sales_Rep_On_Quotes</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 OR 2</booleanFilter>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>equals</operation>
            <value>Local Core Sales Operations</value>
        </criteriaItems>
        <criteriaItems>
            <field>User.ProfileId</field>
            <operation>equals</operation>
            <value>Local Core Strategy Specialist</value>
        </criteriaItems>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>Populate Salesrep Duplicate value in Salesrep Id</fullName>
        <actions>
            <name>Update_Salesrep_Id_with_Salesrep_dup</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>User.SalesRepID__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>

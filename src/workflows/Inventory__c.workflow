<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Last_Expiry_Date_for_Account</fullName>
        <description>Set the last expiry date for account to the record&apos;s current Inventory Expiry Date</description>
        <field>Last_Expiry_Date_for_Account__c</field>
        <formula>Inventory_Hold_Expiry_Date__c</formula>
        <name>Set Last Expiry Date for Account</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Save Last Expiry Date for Account</fullName>
        <actions>
            <name>Set_Last_Expiry_Date_for_Account</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When an inventory is updated and it belongs solely to an account, set the date for Last Expiry Date for Account.</description>
        <formula>AND(     NOT(ISBLANK(Waitlist_Account__c)),     ISBLANK(Quote_Rate_Plan__c),     ISBLANK(PRIORVALUE(Quote_Rate_Plan__c)),     ISBLANK(Subscription_Product_Charge__c),     ISBLANK(PRIORVALUE(Subscription_Product_Charge__c)),     OR(ISNEW(),ISCHANGED(Inventory_Hold_Expiry_Date__c))    )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>

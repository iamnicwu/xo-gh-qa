<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>test_22222</fullName>
        <description>test 22222</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>System_Template/OnBoarding_Welcome_Auto</template>
    </alerts>
    <fieldUpdates>
        <fullName>Contact_Same_Address_Uncheck</fullName>
        <description>Uncheck the &quot;Same Address as Account&quot; checkbox</description>
        <field>Same_Address_as_Account__c</field>
        <literalValue>0</literalValue>
        <name>Contact-Same Address-Uncheck</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Lead_to_Contact_Home_Phone_field_update</fullName>
        <field>HomePhone</field>
        <formula>Workflow_Home_Phone__c</formula>
        <name>Lead to Contact Home Phone field update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sync_Cont_Mailing_City_w_Acct_City</fullName>
        <field>MailingCity</field>
        <formula>Account.BillingCity</formula>
        <name>Sync Cont Mailing City w Acct City</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sync_Cont_Mailing_State_w_Acct_State</fullName>
        <field>MailingState</field>
        <formula>Account.BillingState</formula>
        <name>Sync Cont Mailing State w Acct State</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sync_Cont_Mailing_Street_w_Acct_Street</fullName>
        <description>Set the Contact Mailing Street to match the Account Billing Street</description>
        <field>MailingStreet</field>
        <formula>Account.BillingStreet</formula>
        <name>Sync Cont Mailing Street w Acct Street</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Sync_Cont_Mailing_Zip_w_Acct_Zip</fullName>
        <field>MailingPostalCode</field>
        <formula>Account.BillingPostalCode</formula>
        <name>Sync Cont Mailing Zip w Acct Zip</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Twitter_Click_1</fullName>
        <field>Twitter_Clicks__c</field>
        <formula>Twitter_Clicks__c+1</formula>
        <name>Twitter Click +1</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Contact Address Set To Sync</fullName>
        <actions>
            <name>Sync_Cont_Mailing_City_w_Acct_City</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sync_Cont_Mailing_State_w_Acct_State</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sync_Cont_Mailing_Street_w_Acct_Street</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>Sync_Cont_Mailing_Zip_w_Acct_Zip</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When a contact&apos;s address is set to match the Account&apos;s, sync the addresses</description>
        <formula>AND(Same_Address_as_Account__c,  NOT(ISNULL(AccountId)))</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Contact Synced Address Changed</fullName>
        <actions>
            <name>Contact_Same_Address_Uncheck</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>When a Contact record has the &quot;Same Address as Account&quot; box checked, but someone changes the Contact&apos;s address, uncheck the box automatically.</description>
        <formula>AND ( Same_Address_as_Account__c, NOT(ISNEW()), OR( ISCHANGED(MailingStreet), ISCHANGED(MailingState), ISCHANGED(MailingCity), ISCHANGED(MailingPostalCode), ISCHANGED( MailingCountry ) ), NOT(ISBLANK(AccountId)), OR ( MailingCity &lt;&gt; Account.BillingCity, MailingState &lt;&gt; Account.BillingState, MailingStreet &lt;&gt; Account.BillingStreet ) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Lead to Contact Home Phone</fullName>
        <actions>
            <name>Lead_to_Contact_Home_Phone_field_update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Contact.Workflow_Home_Phone__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Test Email Bounce</fullName>
        <actions>
            <name>test_22222</name>
            <type>Alert</type>
        </actions>
        <actions>
            <name>Twitter_Click_1</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>Id = &apos;0033F0000063RAC&apos;</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>

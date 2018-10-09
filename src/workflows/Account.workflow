<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Featured_Tier_Account_Received</fullName>
        <description>Featured Tier Account Received</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/AccountFeaturedTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>Limited_Tier_Account_Received</fullName>
        <description>Limited Tier Account Received</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/AccountLimitedTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>Other_Tier_Account_Received</fullName>
        <description>Other Tier Account Received</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/AccountOtherTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>Standard_Tier_Account_Received</fullName>
        <description>Standard Tier Account Received</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/AccountStandardTierTemplateCSP2044</template>
    </alerts>
    <alerts>
        <fullName>XO_Group_Internal_Hubspot_Paid_Advertising_for_Accounts</fullName>
        <description>XO Group Internal - Hubspot_Paid Advertising for Accounts</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderAddress>noreply@xogrp.com</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>System_Template/PaidMediaTemplateAccountCSP2044</template>
    </alerts>
    <alerts>
        <fullName>testray</fullName>
        <description>testray</description>
        <protected>false</protected>
        <recipients>
            <type>accountOwner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>System_Template/OnBoarding_Welcome_Auto</template>
    </alerts>
    <fieldUpdates>
        <fullName>Clean_Account_inactive_reason</fullName>
        <field>Inactive_Reason__c</field>
        <name>Clean Account inactive reason</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Clear_Concierge_On_Hold_Until</fullName>
        <description>This is to remove the value in the Concierge On Hold Until field</description>
        <field>Concierge_On_Hold_Until__c</field>
        <name>Clear Concierge On Hold Until</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Concierge_Account_Record_Type</fullName>
        <field>RecordTypeId</field>
        <lookupValue>AccConcierge</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>Concierge Account Record Type</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FU_AccRecordTypeNational</fullName>
        <description>Phase 1 for National</description>
        <field>RecordTypeId</field>
        <lookupValue>National</lookupValue>
        <lookupValueType>RecordType</lookupValueType>
        <name>FU_AccRecordTypeNational</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Credit_Hold_Dropdown_to_NO</fullName>
        <field>CreditHold__c</field>
        <literalValue>No</literalValue>
        <name>Set Credit Hold Dropdown to NO</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Credit_Hold_Dropdown_to_YES</fullName>
        <field>CreditHold__c</field>
        <literalValue>Yes</literalValue>
        <name>Set Credit Hold Dropdown to YES</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Uncheck_Concierge_On_Hold</fullName>
        <description>This is designed to uncheck the Concierge On Hold field</description>
        <field>Concierge_On_Hold__c</field>
        <literalValue>0</literalValue>
        <name>Uncheck Concierge On Hold</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>UpdateLeadToAccountConversionFlag</fullName>
        <description>CSP-1840</description>
        <field>LeadToAccountConversionFlag__c</field>
        <literalValue>0</literalValue>
        <name>UpdateLeadToAccountConversionFlag</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Update_Active_Status_Stamp_Date</fullName>
        <field>Active_Status_Stamp_Date__c</field>
        <formula>now()</formula>
        <name>Update Active Status Stamp Date</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>Account is in credit hold</fullName>
        <actions>
            <name>Set_Credit_Hold_Dropdown_to_YES</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(
ISPICKVAL(CreditHold__c, &apos;No&apos;),
OR( 
	if( Past_Due_Invoice__c, True, 
		if( Charge_Back_Balance__c &lt;&gt; 0, True, False) ), 
		if( 
			OR(TEXT(Customer_Type__c) == &apos;AMS&apos;, 
				 TEXT(Customer_Type__c) == &apos;BANKRUPTCY&apos;, 
				 TEXT(Customer_Type__c) == &apos;BANKRUPTCY2&apos;, 
				 TEXT(Customer_Type__c) == &apos;CAN BAD PAY 3&apos;, 
				 TEXT(Customer_Type__c) == &apos;CANCELLED&apos;, 
				 TEXT(Customer_Type__c) == &apos;CC CHARGEBACK&apos;, 
				 TEXT(Customer_Type__c) == &apos;CC CHARGEBACK 2&apos;, 
				 TEXT(Customer_Type__c) == &apos;CNCXLD BAD PAY&apos;, 
				 TEXT(Customer_Type__c) == &apos;CNCXLD BAD PAY2&apos;, 
				 TEXT(Customer_Type__c) == &apos;CREDIT HOLD&apos;, 
				 TEXT(Customer_Type__c) == &apos;OUT OF BUS 3&apos;, 
				 TEXT(Customer_Type__c) == &apos;OUT OF BUS. 2&apos;, 
				 TEXT(Customer_Type__c) == &apos;OUT OF BUSINESS&apos;, 
				 TEXT(Customer_Type__c) == &apos;MB&amp;W&apos;, 
				 TEXT(Customer_Type__c) == &apos;CBP-In House&apos;, 
				 TEXT(Customer_Type__c) == &apos;ACH RETURN&apos; ) 
				, True, False ))
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Account is not in credit hold</fullName>
        <actions>
            <name>Set_Credit_Hold_Dropdown_to_NO</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(
ISPICKVAL(CreditHold__c, &apos;Yes&apos;),
NOT( 
	OR( 
		if( Past_Due_Invoice__c, True, 
			if(Charge_Back_Balance__c &lt;&gt; 0, True, False)),
			if( 
				OR(
					TEXT(Customer_Type__c) == &apos;AMS&apos;, 
					TEXT(Customer_Type__c) == &apos;BANKRUPTCY&apos;, 
					TEXT(Customer_Type__c) == &apos;BANKRUPTCY2&apos;, 
					TEXT(Customer_Type__c) == &apos;CAN BAD PAY 3&apos;, 
					TEXT(Customer_Type__c) == &apos;CANCELLED&apos;, 
					TEXT(Customer_Type__c) == &apos;CC CHARGEBACK&apos;, 
					TEXT(Customer_Type__c) == &apos;CC CHARGEBACK 2&apos;, 
					TEXT(Customer_Type__c) == &apos;CNCXLD BAD PAY&apos;, 
					TEXT(Customer_Type__c) == &apos;CNCXLD BAD PAY2&apos;, 
					TEXT(Customer_Type__c) == &apos;CREDIT HOLD&apos;, 
					TEXT(Customer_Type__c) == &apos;OUT OF BUS 3&apos;, 
					TEXT(Customer_Type__c) == &apos;OUT OF BUS. 2&apos;, 
					TEXT(Customer_Type__c) == &apos;OUT OF BUSINESS&apos;, 
					TEXT(Customer_Type__c) == &apos;MB&amp;W&apos;, 
					TEXT(Customer_Type__c) == &apos;CBP-In House&apos;, 
					TEXT(Customer_Type__c) == &apos;ACH RETURN&apos; ) , 
				True, 
				False )))
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Clean Expired Account inactive reason</fullName>
        <actions>
            <name>Clean_Account_inactive_reason</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>AND(RecordType.Name = &apos;Local&apos;,Local_Active__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Concierge On Hold Until Reversion</fullName>
        <active>true</active>
        <description>This rule is designed to uncheck the Concierge On Hold check box based on the Concierge On Hold Until date</description>
        <formula>Concierge_On_Hold__c</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Clear_Concierge_On_Hold_Until</name>
                <type>FieldUpdate</type>
            </actions>
            <actions>
                <name>Uncheck_Concierge_On_Hold</name>
                <type>FieldUpdate</type>
            </actions>
            <offsetFromField>Account.Concierge_On_Hold_Until__c</offsetFromField>
            <timeLength>0</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
    <rules>
        <fullName>Test Ray</fullName>
        <actions>
            <name>testray</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <formula>ISCHANGED(OwnerId)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Update Active Stamp Date</fullName>
        <actions>
            <name>Update_Active_Status_Stamp_Date</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>CSP-3004</description>
        <formula>And( RecordType.Name = &quot;Local&quot;, ISCHANGED(Account_Status__c), ISPICKVAL(Account_Status__c,&quot;Active&quot;) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WF_AccRecordType</fullName>
        <actions>
            <name>FU_AccRecordTypeNational</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.BU__c</field>
            <operation>equals</operation>
            <value>National</value>
        </criteriaItems>
        <description>Phase 1 National</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>WF_ConciergeAccRecordType</fullName>
        <actions>
            <name>Concierge_Account_Record_Type</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.BU__c</field>
            <operation>equals</operation>
            <value>Local</value>
        </criteriaItems>
        <description>Concierge Record Type Update</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Featured Tier Account</fullName>
        <actions>
            <name>Featured_Tier_Account_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044

Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot; 
&amp;&amp; 
CONTAINS(Fulfillment_Data__c, &quot;Featured&quot;)
&amp;&amp;
LeadToAccountConversionFlag__c = FALSE</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Limited Tier Account</fullName>
        <actions>
            <name>Limited_Tier_Account_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044

Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot; 
&amp;&amp; 
CONTAINS(Fulfillment_Data__c, &quot;Limited&quot;)
&amp;&amp;
LeadToAccountConversionFlag__c = FALSE</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Other Tier Account</fullName>
        <actions>
            <name>Other_Tier_Account_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044
Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot; &amp;&amp; NOT(CONTAINS(Fulfillment_Data__c, &quot;Standard&quot;)) 
&amp;&amp; NOT(CONTAINS(Fulfillment_Data__c, &quot;Limited&quot;)) 
&amp;&amp; NOT(CONTAINS(Fulfillment_Data__c, &quot;Featured&quot;))
&amp;&amp;LeadToAccountConversionFlag__c</description>
        <formula>False</formula>
        <triggerType>onCreateOnly</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Freemium %E2%80%93 Standard Tier Account</fullName>
        <actions>
            <name>Standard_Tier_Account_Received</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>CSP - 2044

Lead_Source__r.Name == &quot;XO Group Internal - Freemium&quot; 
&amp;&amp; 
CONTAINS(Fulfillment_Data__c, &quot;Standard&quot;)
&amp;&amp;
LeadToAccountConversionFlag__c = FALSE</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - Hubspot_Paid Advertising for Accounts</fullName>
        <actions>
            <name>XO_Group_Internal_Hubspot_Paid_Advertising_for_Accounts</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <description>csp-1840
AND (((Lead_Source__r.Name = &apos;XO Group Internal - Hubspot_Paid Advertising-A&apos;)  || (Lead_Source__r.Name = &apos;XO Group Internal - Hubspot_Paid Advertising-B&apos;)), LeadToAccountConversionFlag__c = FALSE)</description>
        <formula>False</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>XO Group Internal - UpdateLeadToAccountConversionFlag</fullName>
        <actions>
            <name>UpdateLeadToAccountConversionFlag</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>csp-1840</description>
        <formula>ISNEW()</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>

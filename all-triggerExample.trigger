// Insert → no old values → no oldMap
// Undelete → treated like insert → no oldMap
// Update → has previous values → oldMap is available
// Delete → record is being removed → oldMap available
================================================================================================================================================================
prevent duplicate contact with same email under same account
    trigger ContactTrigger on Contact (before insert, before update) {
    Set<String> emails = new Set<String>();
    for(Contact con : Trigger.new){
        if(con.Email != null){
            emails.add(con.Email);
        }
    }
    
    Map<String, Contact> existingContacts = new Map<String, Contact>();
    
    for(Contact c : [
        SELECT Id, Email, AccountId
        FROM Contact
        WHERE Email IN :emails
    ]){
        existingContacts.put(c.Email + c.AccountId, c);
    }

    for(Contact con : Trigger.new){
        String key = con.Email + con.AccountId;
        if(existingContacts.containsKey(key)){
            con.addError('Duplicate Contact Email found for this Account');
        }
    }

    }
================================================================================================================================================================
//containsKey()
//get()
//trigger to update  field on Account when Case is inserted, updated, deleted, or undeleted

trigger CaseTrigger on Case(after insert, after update, after delete, after undelete) {
    Set<Id> acctIds = new Set<Id>();
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete)
        for (Case c : Trigger.new) if (c.AccountId != null) acctIds.add(c.AccountId);
        
    if (Trigger.isUpdate || Trigger.isDelete)
        for (Case c : Trigger.old) if (c.AccountId != null) acctIds.add(c.AccountId);
    
    if (acctIds.isEmpty()) return;
    
    Map<Id, Integer> counts = new Map<Id, Integer>();
    Map<Id, Datetime> lastCreatedByOpp = new Map<Id, Datetime>();
         List<AggregateResult> rollups = [
        SELECT AccountId a, COUNT(Id) cnt, MAX(CreatedDate) lastCreated
        FROM Case
        WHERE AccountId IN :acctIds AND Status != 'Closed'
        GROUP BY AccountId
    ];

    for (AggregateResult ar :rollups){
        counts.put((Id)ar.get('a'), (Integer)ar.get('cnt'));
        lastCreatedByOpp.put((Id)ar.get('a'), (Datetime) ar.get('lastCreated'));
        System.debug('ar=====>: ' + ar); // AggregateResult:{a=001dL00001qLC9NQAW, cnt=1}
        System.debug('counts=====>: ' + counts); // {001dL00001qLC9NQAW=1}
        System.debug('lastCreatedByOpp=====>: ' + lastCreatedByOpp); // {001dL00001qLC9NQAW=2023-10-10 12:00:00}
    }
    
    List<Account> updates = new List<Account>();
    for (Id aid : acctIds) {
        updates.add(new Account(
            Id = aid,
        Active_Cases__c = counts.containsKey(aid) ? counts.get(aid) : 0,
        Last_Active_Case__c = lastCreatedByOpp.containsKey(aid) ? lastCreatedByOpp.get(aid) : null
            ));
    }
    update updates;
}



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 6️⃣ Create Task When Opportunity Closed Won
 Trigger (after update)
trigger CreateTaskOnClosedWon on Opportunity (after update){

    List<Task> tasks = new List<Task>();

    for(Opportunity opp : Trigger.new){
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

        if(oldOpp.StageName != 'Closed Won' &&
           opp.StageName == 'Closed Won'){

            tasks.add(new Task(
                Subject = 'Follow up after Closed Won',
                WhatId = opp.Id,
                OwnerId = opp.OwnerId
            ));
        }
    }

    insert tasks;
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 8️⃣ Update Contact Industry When Account Industry Changes
 Trigger (after update)

trigger UpdateContactIndustry on Account (after update) {

    trigger accountTrigger on Account (after update) {

    Map<Id, String> accountIdsMap = new Map<Id, String>();

    // Find accounts where Industry changed
    for (Account ac : Trigger.new) {
        String oldIndustry = Trigger.oldMap.get(ac.Id).Industry;

        if (ac.Industry != oldIndustry) {
            accountIdsMap.put(ac.Id, ac.Industry);
        }
    }

    if (accountIdsMap.isEmpty()) return;

    // Fetch related contacts
    List<Contact> contacts = [
        SELECT Id, AccountId
        FROM Contact
        WHERE AccountId IN :accountIdsMap.keySet()
    ];

    List<Contact> updateList = new List<Contact>();

    for (Contact con : contacts) {
        updateList.add(new Contact(
            Id = con.Id,
            Industry__c = accountIdsMap.get(con.AccountId)
        ));
    }

    // Update once (bulk-safe)
    if (!updateList.isEmpty()) {
        update updateList;
    }
}

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 9️⃣ Prevent Account Insert Without Website
 Trigger (before insert)
trigger RequireWebsite on Account (before insert){
    for(Account acc : Trigger.new){
        if(String.isBlank(acc.Website)){
            acc.addError('Website is mandatory.');
        }
    }
}

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 🔟 Auto Update Account Type Based on Revenue
 Scenario
If AnnualRevenue > 1M → Type = 'Premium'
 Trigger (before insert, before update)
trigger UpdateAccountType on Account (before insert, before update){

    for(Account acc : Trigger.new){
        if(acc.AnnualRevenue != null && acc.AnnualRevenue > 1000000){
            acc.Type = 'Premium';
        }
    }
}


================================================================================================================================================================================================
 1️⃣ Prevent Deleting Account with Opportunities
 Scenario Do not allow deletion of an `Account` if related `Opportunity` records exist.
 Trigger (before delete)
trigger PreventAccountDelete on Account (before delete) {

    Set<Id> accountIds = new Set<Id>();
    for(Account acc : Trigger.old){
        accountIds.add(acc.Id);
    }

    Map<Id, Integer> oppCountMap = new Map<Id, Integer>();

    for(AggregateResult ar : [
        SELECT AccountId accId, COUNT(Id) oppCount
        FROM Opportunity
        WHERE AccountId IN :accountIds
        GROUP BY AccountId
    ]){
        oppCountMap.put((Id)ar.get('accId'), (Integer)ar.get('oppCount'));
    }

    for(Account acc : Trigger.old){
        if(oppCountMap.containsKey(acc.Id)){
            acc.addError('Cannot delete Account with existing Opportunities.');
        }
    }
}
================================================================================================================================================================================================
 2️⃣ Auto Create Contact After Account Insert
 Scenario - Automatically create a default Contact when an `Account` is created.
    Trigger (after insert) trigger CreateContactAfterAccount on Account (after insert){
        List<Contact> contactsToInsert = new List<Contact>();
        for(Account acc : Trigger.new){
            contactsToInsert.add(new Contact(
                LastName = acc.Name + ' Contact',
                AccountId = acc.Id
            ));
        }
        insert contactsToInsert;
    }
================================================================================================================================================================================================
 3️⃣ Prevent Stage Change Without Reason
 Scenario
If Opportunity Stage changes to “Closed Lost”, Description must be filled.
Trigger (before update)
trigger ValidateClosedLost on Opportunity (before update){
    for(Opportunity opp : Trigger.new){
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        if(oldOpp.StageName != 'Closed Lost' &&
           opp.StageName == 'Closed Lost' &&
           String.isBlank(opp.Description)){
            opp.addError('Description is required when Stage is Closed Lost.');
        }
    }
}
================================================================================================================================================================================================-
  5️⃣ Prevent Duplicate Contact Email Under Same Account
 Trigger (before insert, before update)
trigger PreventDuplicateEmail on Contact (before insert, before update){
    Set<String> emails = new Set<String>();
    Set<Id> accountIds = new Set<Id>();

    for(Contact con : Trigger.new){
        if(con.Email != null){
            emails.add(con.Email);
            accountIds.add(con.AccountId);
        }
    }

    List<Contact> existingContacts = [
        SELECT Email, AccountId FROM Contact
        WHERE Email IN :emails
        AND AccountId IN :accountIds
    ];

    for(Contact con : Trigger.new){
        for(Contact existing : existingContacts){
            if(con.Email == existing.Email &&
               con.AccountId == existing.AccountId &&
               con.Id != existing.Id){

                con.addError('Duplicate Email not allowed under same Account.');
            }
        }
    }
}

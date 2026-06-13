// NOTES FILE: This is a documentation-only file for triggers/handlers examples.
// The actual deployable Apex code should live under force-app/main/default/*

// Example: OpportunityLineItemTrigger (reference only)

trigger OpportunityLineItemTrigger on OpportunityLineItem (
    after insert,
    after undelete,
    after delete
) {
    Set<Id> oppIds = new Set<Id>();
    
    if (Trigger.isInsert || Trigger.isUndelete) {
        for (OpportunityLineItem oli : Trigger.new) {
            if (oli.OpportunityId != null) oppIds.add(oli.OpportunityId);
        }
    }
    if (Trigger.isDelete) {
        for (OpportunityLineItem oli : Trigger.old) {
            if (oli.OpportunityId != null) oppIds.add(oli.OpportunityId);
        }
    }
    
    if (!oppIds.isEmpty()) {
        OpportunityLineItemTriggerHandler.updateOppCountsAndLastCreated(oppIds);
    }
}

// Handler class must be placed in force-app/main/default/classes/OpportunityLineItemTriggerHandler.cls

public with sharing class OpportunityLineItemTriggerHandler {
    private static Boolean isRunning = false;
    
    public static void updateOppCountsAndLastCreated(Set<Id> oppIds) {
        if (isRunning) return; // recursion guard
        isRunning = true;
        
        Savepoint sp = Database.setSavepoint();
        try {
            if (oppIds == null || oppIds.isEmpty()) return;
            
            List<AggregateResult> rollups = [
                SELECT
                    OpportunityId oppId,
                    COUNT(Id) cnt,
                    MAX(CreatedDate) lastCreated
                FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIds
                GROUP BY OpportunityId
            ];
            
            Map<Id, Integer> countsByOpp = new Map<Id, Integer>();
            Map<Id, Datetime> lastCreatedByOpp = new Map<Id, Datetime>();
            
            for (AggregateResult ar : rollups) {
                Id oppId = (Id) ar.get('oppId');
                countsByOpp.put(oppId, (Integer) ar.get('cnt'));
                lastCreatedByOpp.put(oppId, (Datetime) ar.get('lastCreated'));
            }
            
            List<Opportunity> updates = new List<Opportunity>();
            for (Id oppId : oppIds) {
                Opportunity o = new Opportunity(Id = oppId);
                o.Total_Line_Items__c = countsByOpp.containsKey(oppId) ? countsByOpp.get(oppId) : 0;
                o.Last_LineItem_Created_Date__c = lastCreatedByOpp.get(oppId);
                updates.add(o);
            }
            
            if (!updates.isEmpty()) {
                update updates;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            // ErrorLogger.log('OpportunityLineItemTriggerHandler.updateOppCountsAndLastCreated', e);
            throw e;
        } finally {
            isRunning = false;
        }
    }
}
*/

// 2nd Example (reference only): Create Project__c on Closed Won

trigger OpportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OpportunityTriggerHandler.createProjectOnClosedWon(Trigger.new, Trigger.oldMap);
        }
    }
}

public with sharing class OpportunityTriggerHandler {
    private static Boolean isRunning = false;
    public static void createProjectOnClosedWon(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (isRunning) return;
        isRunning = true;
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> oppIdsNeedingProject = new Set<Id>();
            
            for (Opportunity opp : newList) {
                                
                if (oldMap == null) {
                    if (opp.StageName == 'Closed Won') {
                        oppIdsNeedingProject.add(opp.Id);
                    }
                }
                
                Opportunity oldOpp = oldMap.get(opp.Id);
               
                Boolean movedToClosedWon = (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won');
               
                if (movedToClosedWon) {
                    oppIdsNeedingProject.add(opp.Id);
                }
            }
            
            if (oppIdsNeedingProject.isEmpty()) return;
            
            Map<Id, Project__c> existingByOppId = new Map<Id, Project__c>();
            for (Project__c p : [
                SELECT Id, Opportunity__c
                FROM Project__c
                WHERE Opportunity__c IN :oppIdsNeedingProject
            ]) {
                if (p.Opportunity__c != null) {
                    existingByOppId.put(p.Opportunity__c, p);
                }
            }
            
            List<Project__c> toInsert = new List<Project__c>();
            for (Opportunity opp : newList) {
                if (!oppIdsNeedingProject.contains(opp.Id)) continue;
                if (existingByOppId.containsKey(opp.Id)) continue;
                
                Project__c proj = new Project__c();
                proj.Opportunity__c = opp.Id;
                proj.Project_Manager__c = opp.OwnerId;
                toInsert.add(proj);
            }
            
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            // ErrorLogger.log('OpportunityTriggerHandler.createProjectOnClosedWon', e);
            throw e;
        } finally {
            isRunning = false;
        }
    }
}


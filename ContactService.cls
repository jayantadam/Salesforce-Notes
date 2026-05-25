public with sharing class ContactService {
    // For @wire → must be cacheable and no side effects
    /* ✅ Wired Apex Call (@wire)
        Characteristics
        Reactive & automatic → runs whenever the parameter changes.
        Must call an Apex method marked @AuraEnabled(cacheable=true).
        Read‑only only (no DML allowed in the Apex method).
        Supports LDS caching.
        Automatically handles:
        Data state (data, error)
        Re-run logic when parameters change
        Works with refreshApex.
    Use when:
            You need automatic refreshing.
            You want cached, fast reads.
            You want your UI to stay in sync with record/page context. */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccount(Id accountId, Integer limitSize) {
        if (accountId == null || limitSize == null || limitSize <= 0) {
            return new List<Contact>();
        }
        return [
            SELECT Id, Name, Title, Email, Phone, AccountId, LastModifiedDate
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastModifiedDate DESC
            LIMIT :limitSize
        ];
    }

    // For imperative → can be non-cacheable and do DML/side effects
     /* Called manually (e.g., button click, save, search, onchange event).
        Supports try/catch, sequential logic.
        Can call non-cacheable Apex.
        Apex method can perform DML.
        Does not auto‑refresh.
        Must use `refreshApex()` to sync wired values (if needed).*/
    @AuraEnabled
    public static Contact upsertContact(Contact c) {
        if (c == null) {
            throw new AuraHandledException('Contact payload is required.');
        }
        upsert c;
        return [
            SELECT Id, Name, Title, Email, Phone, AccountId, LastModifiedDate
            FROM Contact
            WHERE Id = :c.Id
            LIMIT 1
        ];
    }
}

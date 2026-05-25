Salesforce Governor Limits – Ultimate Cheat Sheet


# Apex + LWC Interview (5 Years Experience) — Questions & Answers

A senior‑level, practical Q&A pack tailored for ~5 years of Salesforce development experience. Use this as an interview prep guide or as an interviewer rubric.

this.dispatchEvent(new CustomEvent('payloadSubmit':detail:{id:1,name:'alex'}));

## 1) Bulkification — what is it and how do you ensure it?
**Answer:** Handle multiple records per transaction. Accept/return **collections**, do **SOQL/DML outside loops**, aggregate IDs first, use **Maps/Sets**, and centralize queries in **Selector** classes. Add unit tests that pass 200+ records to catch N+1 issues.

**Snippet (bad vs good):**
```apex
// ❌ Bad
for (Contact c: Trigger.new) {
  Account a = [SELECT Id FROM Account WHERE Id = :c.AccountId LIMIT 1];
}
// ✅ Good
Set<Id> accIds = new Set<Id>();
for (Contact c: Trigger.new) if (c.AccountId != null) accIds.add(c.AccountId);
Map<Id, Account> accMap = new Map<Id, Account>([
  SELECT Id, Name FROM Account WHERE Id IN :accIds
]);
```

---

## 2) Before vs After triggers — when to use which?
**Answer:** **Before** = default/validate fields on the same records. **After** = need record **IDs**, create related records, publish platform events, or call async jobs.

---

## 3) What does a robust trigger architecture look like?
**Answer:** One trigger per object → delegate to a **Trigger Handler**. Use **Service** (business logic), **Selector** (SOQL), and optional **Domain** layer. Include **recursion guards**, bulk-safety, and unit tests that target services.

---

## 4) Key trigger context variables & caveats
**Answer:** `isBefore`, `isAfter`, `isInsert`, `isUpdate`, `isDelete`, `isUndelete`; `Trigger.new`, `Trigger.old`, `newMap`, `oldMap`. No `new` on delete; `new` is read-only in after context; IDs only exist after insert.

---

## 5) Preventing recursion
**Answer:** Use **static flags/sets**; compare old vs new values to avoid write-backs; design services to update only when needed.

---

## 6) Validation Rule vs Flow vs Trigger
**Answer:** **Validation** for field/data rules; **Flow** for admin-maintainable automation; **Trigger/Apex** for complex, cross-object, or high-scale transactional logic/integrations.

---

## 7) Query selectivity at scale
**Answer:** Lead with **indexed fields** (`Id`, `OwnerId`, `RecordTypeId`, `CreatedDate`, `LastModifiedDate`, External IDs). Use date windows (e.g., `LAST_N_DAYS:30`), avoid leading `%` in `LIKE`, avoid `NOT` and broad `OR`s; add `LIMIT` in UI queries.

---

## 8) Which fields are indexed by default?
**Answer:** `Id`, `OwnerId`, `RecordTypeId`, `CreatedDate`, `LastModifiedDate`, and **External ID/Unique** custom fields. Request custom indexes via Salesforce support for other fields.

---

## 9) Polymorphic relationships (WhoId/WhatId) — safe querying
**Answer:** Use `TYPEOF` to select fields per concrete type or filter by `What.Type` / `Who.Type`.
```soql
SELECT Id, Subject,
TYPEOF What
  WHEN Opportunity THEN Name, StageName, Amount, Account.Name
  WHEN Case        THEN CaseNumber, Status
END
FROM Task
WHERE WhatId != NULL
```

---

## 10) Parent/child queries — limits & patterns
**Answer:** Up to **5 levels up** via dot notation; subqueries for children use **child relationship names**; subquery returns **max 200 children per parent**. Query children directly if you need more than 200.

---

## 11) DISTINCT / GROUP BY / COUNT_DISTINCT
**Answer:** Use `DISTINCT` for unique rows; `GROUP BY` for rollups; `COUNT_DISTINCT(field)` for unique counts. `DISTINCT` only on top-level SELECT (not inside subqueries).

---

## 12) Can formula fields be used in WHERE?
**Answer:** **Yes**, if the formula returns a filterable type (Text/Number/Date/DateTime/Checkbox). Long/Rich Text returns are not filterable.

---

## 13) Enforcing sharing in Apex
**Answer:** Use **`with sharing`** or **`inherited sharing`** (recommended). In async, prefer **USER_MODE** where supported. Validate with tests using `System.runAs(user)`.

---

## 14) Enforcing CRUD/FLS
**Answer:** Add `WITH SECURITY_ENFORCED` to SOQL; use `Security.stripInaccessible` for create/update; check describes (`isAccessible`, `isCreateable`, `isUpdateable`). Prefer **LDS** on UI for automatic enforcement.

---

## 15) Preventing SOQL injection
**Answer:** Bind variables, whitelist identifiers (field/order), validate types & lengths, escape `%`/`_` in LIKE. Never concatenate raw input into SOQL.
```apex
String t = term.trim();
String p = '%' + t.replace('%','\\%').replace('_','\\_') + '%';
List<Account> a = [SELECT Id, Name FROM Account WHERE Name LIKE :p ESCAPE '\\' LIMIT 50];
```

---

## 16) Future vs Queueable vs Batch — when to use which?
**Answer:** **Future**: simple fire-and-forget (primitives), no chaining. **Queueable**: chaining, state, accepts sObjects, callouts OK. **Batch**: huge datasets; resumable; `start/execute/finish`.

---

## 17) Batch best practices
**Answer:** Scope 100–200; selective start query; idempotent logic; partial success; log failures; optional chaining from `finish()`.

---

## 18) Callouts design pattern
**Answer:** Use **Named Credentials**; run callouts via **Queueable** or `@future(callout=true)`; implement retry/backoff; ensure idempotency (external IDs/hashes); secure secrets via Named Creds.

---

## 19) Platform Events vs Change Data Capture (CDC)
**Answer:** **PE** for custom event-driven workflows and internal decoupling. **CDC** for out-of-the-box DML change streams consumed by external systems.

---

## 20) Testing strategy
**Answer:** Create test data (no `seeAllData=true`), cover positive/negative/edge/bulk/FLS/sharing cases; use `startTest/stopTest` for async; assert **business outcomes** (not just coverage).

---

## 21) Mocking callouts in tests
**Answer:** Implement `HttpCalloutMock` and register via `Test.setMock(HttpCalloutMock.class, new MyMock())` to simulate responses and assert request payloads.

---

## 22) Code quality beyond 75%
**Answer:** Aim for branch coverage, meaningful assertions, performance checks, PMD rules, and avoiding anti-patterns (SOQL/DML in loops, heavy constructors).

---

## 23) LWC: Wired vs Imperative Apex
**Answer:** **Wired**: reactive, auto-run on param change, must be `@AuraEnabled(cacheable=true)`, read-only, cached, supports `refreshApex`. **Imperative**: manual (button/submit), DML + try/catch, no auto-refresh.

---

## 24) Why `@AuraEnabled`? When `cacheable=true`?
**Answer:** `@AuraEnabled` exposes Apex to Lightning. `cacheable=true` is required for **wire**, implies **read-only**, and enables LDS caching. Without it, use **imperative** for DML/side-effects.

---

## 25) LWC reactivity in practice (2026)
**Answer:** `@api` for public props; reassign arrays/objects to trigger render; `@track` rarely needed (legacy/deep mutation). Use debouncing for inputs to limit wire calls.

---

## 26) Prefer LDS (`lightning/ui*Api`) or Apex?
**Answer:** Prefer **LDS** for simple CRUD and forms (`lightning-record-form`, `getRecord`, `updateRecord`) — enforces sharing/FLS and caches efficiently. Use Apex for complex queries/logic.

---

## 27) LWC performance patterns
**Answer:** Use `key` in `for:each`, debounce searches, batch state updates to reduce re-render storms, lazy-load large lists, avoid expensive getters.

---

## 28) `refreshApex` — when and how
**Answer:** After imperative DML, refresh wired data: keep the wired result reference and call `refreshApex(wiredRef)`.

---

## 29) Scenario: List page slow at 5M records
**Answer:** Lead with **indexed** filters (`OwnerId`, `RecordTypeId`, `LastModifiedDate`), avoid `OR`/leading `%`, add pagination and `LIMIT`, consider skinny tables, cache hot queries, and precompute where feasible.

---

## 30) Scenario: Update 2M records overnight
**Answer:** **Batch Apex** with selective query and scope 100–200; idempotent updates; capture failures; chain Queueable/Batch in `finish()`; schedule job.

---

## 31) Scenario: LWC with auto list + quick add
**Answer:** Wire a read method (`@AuraEnabled(cacheable=true)`), show list; imperative `upsert` on button; then `refreshApex`. Use toasts, spinners, disabled states, and error normalization.

---

## 32) Scenario: Secure LWC read
**Answer:** Apex with `WITH SECURITY_ENFORCED`, `Security.stripInaccessible`; class `inherited sharing`. Prefer LDS when possible. Test with low-privileged user.

---

## 33) Rapid Fire (one-liners)
- **Can wired Apex do DML?** No (read-only).
- **Subquery child limit?** 200 per parent.
- **Formula in WHERE?** Yes, if filterable type.
- **Best sharing modifier for services?** `inherited sharing`.
- **Stop SOQL injection?** Bind vars + whitelist identifiers + validate types.
- **Reactive param in wire?** Prefix with `$` (e.g., `{ id: '$recordId' }`).

---

## 34) Handy Service & LWC Snippets

**Apex service (read + write):**
```apex
public with sharing class OpportunityService {
  @AuraEnabled(cacheable=true)
  public static List<Opportunity> getRecentOpps(Id accountId, Integer limitSize) {
    if (accountId == null || limitSize == null || limitSize <= 0) return new List<Opportunity>();
    return [
      SELECT Id, Name, StageName, Amount, CloseDate, LastModifiedDate
      FROM Opportunity
      WHERE AccountId = :accountId
      ORDER BY LastModifiedDate DESC
      LIMIT :limitSize
    ];
  }
  @AuraEnabled
  public static Opportunity upsertOpp(Opportunity opp) {
    if (opp == null) throw new AuraHandledException('Opportunity payload required.');
    upsert opp;
    return [SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
  }
}
```

**LWC wire + imperative + refresh:**
```js
import { LightningElement, api, wire } from 'lwc';
import getRecentOpps from '@salesforce/apex/OpportunityService.getRecentOpps';
import upsertOpp from '@salesforce/apex/OpportunityService.upsertOpp';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OppPanel extends LightningElement {
  @api recordId; // Account Id
  size = 10;
  wiredRef;
  rows = [];
  error;

  @wire(getRecentOpps, { accountId: '$recordId', limitSize: '$size' })
  wiredOpps(result) {
    this.wiredRef = result;
    const { data, error } = result;
    this.rows = data || [];
    this.error = error ? (error.body?.message || 'Error') : undefined;
  }

  async handleSave() {
    try {
      await upsertOpp({ opp: { Name: 'Quick Add', AccountId: this.recordId, StageName: 'Prospecting', CloseDate: new Date().toISOString().slice(0,10) } });
      await refreshApex(this.wiredRef);
      this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Saved', variant: 'success' }));
    } catch (e) {
      this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: e?.body?.message || e?.message || 'Error', variant: 'error' }));
    }
  }
}
```

---

**Tip:** Keep this file as `apex_lwc_interview_5yrs.md` and review the Rapid Fire and Scenario sections right before interviews.

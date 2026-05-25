

# ⚡ 1. Wired vs Imperative Apex Calls

## ✅ Wired Apex Call (`@wire`)

Characteristics
   Reactive & automatic → runs whenever the parameter changes.
   Must call an Apex method marked `@AuraEnabled(cacheable=true)`.
   Read‑only only (no DML allowed in the Apex method).
   Supports LDS caching.
   Automatically handles:
       Data state (`data`, `error`)
       Re-run logic when parameters change
   Works with `refreshApex`.

Use when:
   You need automatic refreshing.
   You want cached, fast reads.
   You want your UI to stay in sync with record/page context.

## ✅ Imperative Apex Call

Characteristics

   Called manually (e.g., button click, save, search, onchange event).
   Supports try/catch, sequential logic.
   Can call non-cacheable Apex.
   Apex method can perform DML.
   Does not auto‑refresh.
   Must use `refreshApex()` to sync wired values (if needed).

Use when:

   User initiates an action (Save, Submit, Search).
   You need DML, complex validation, or control flow.
   You need to pass dynamic inputs at runtime.

Example

# ⚡ 2. Wired vs Imperative — Quick Table

| Feature                           | Wired (`@wire`) | Imperative |
| --------------------------------- | ------------------- | -------------- |
| Auto refresh                      | ✅ Yes               | ❌ No           |
| Reactive (params change → re-run) | ✅                   | ❌              |
| Requires `cacheable=true`         | ✅                   | ❌              |
| Supports DML                      | ❌ No                | ✅ Yes          |
| Good for read queries             | ✅                   | ✔️              |
| Good for save/update actions      | ❌                   | ✅              |
| Easy to use                       | Medium                | Easy            |
| Manual control (try/catch)        | ❌                   | ✅              |

# ⚡ 3. Why do we need `@AuraEnabled`?

### Because LWC cannot call Apex unless the method is explicitly exposed to the UI layer.

`@AuraEnabled` tells Salesforce:

   “Expose this Apex method to Lightning components.”
   “Make it callable from LWC, Aura, and Lightning Flow.”

## Types of `@AuraEnabled`

### 1️⃣ `@AuraEnabled(cacheable=true)`

   Required for wired Apex calls.
   Apex method must be read-only.
   Enables Lightning Data Service caching → faster, lower server load.

```apex
@AuraEnabled(cacheable=true)
public static List<Contact> getContacts(Id accountId) { ... }
```

### 2️⃣ `@AuraEnabled` (without cacheable)
   Used for imperative calls.
   Allows DML, complex logic, long-running code.
```apex
@AuraEnabled
public static Contact upsertContact(Contact c) { ... }
```
# ⚡ 4. Interview‑Ready Summary

### Wired Apex

   Auto runs, reactive, cacheable, no DML
   Used for displaying data automatically based on context

### Imperative Apex

   Manual, full control, supports DML
   Used for actions triggered by the user (Save, Submit, Search)

### @AuraEnabled
   Makes Apex usable from LWC
   `cacheable=true` → required for wired, must be read-only
   Without cache → imperative, can include DML

If you want, I can generate:

📌 A side‑by‑side wired vs imperative visual cheatsheet  
📌 Real LWC code examples for interview prep  
📌 A full Apex + LWC interview Q\&A PDF

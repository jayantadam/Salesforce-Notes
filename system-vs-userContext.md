🔥 Apex Sharing Keywords
            OR
🔥 Class Sharing Modes

1️⃣ with sharing
👉 Respects record-level security
2️⃣ without sharing
👉 Ignores record-level security
3️⃣ ✅ inherited sharing (the third one)

👉 It inherits the sharing behavior from the caller class
        public inherited sharing class ChildClass {
            public static void run() {
                List<Account> accs = [SELECT Id FROM Account];
            }
        }
✅ 🔹 Why we don’t use extends for sharing?
        👉 Sharing is NOT inherited via extends
        👉 It is controlled by sharing keywords, not inheritance

✅ Case 1: Called from with sharing
            public with sharing class ParentClass {
                public static void execute() {
                    ChildClass.run();
                }
            }

    👉 Result:
        ✅ Acts like with sharing
        ✅ Only accessible records returned

✅ Case 2: Called from without sharing
            public without sharing class ParentClass {
                public static void execute() {
                    ChildClass.run();
                }
            }
    👉 Result:
    ✅ Acts like without sharing
    ✅ All records returned


            

# ✅ 🔷 Visual Diagram (Simple Mental Model)
                ┌──────────────────────────────┐
                │        APEX CODE RUNS        │
                └──────────────┬───────────────┘
                               │
                      DEFAULT → System Context
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
 Object Permissions     Field Permissions     Record Sharing
 (CRUD)                 (FLS)                 (OWD, Roles)
        │                      │                      │
        ❌ Ignored            ❌ Ignored              ❌ Ignored
                                                   (unless sharing keyword)

                               │
                 ┌─────────────▼─────────────┐
                 │    Sharing Keywords       │
                 └─────────────┬─────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   with sharing        without sharing        inherited sharing
        │                      │                      │
   ✅ Enforce                ❌ Ignore           ✅ Depends on caller
   record access            record access

                               │
                 ┌─────────────▼─────────────┐
                 │ Manual Security Needed    │
                 └─────────────┬─────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
 Schema checks        stripInaccessible     WITH SECURITY_ENFORCED
 (CRUD)               (FLS)                 (CRUD + FLS in SOQL)

# ✅ 🔷 Trickiest Interview Questions (with Answers)
## 🔥 Q1: If a class is `with sharing`
                    Example 1 :  does it enforce object permissions?
                        👉 **Answer: Object permissions are NOT enforced automatically**
                                    ✔ It only enforces : Record-level access
                                    ❌ It does NOT enforce:
                                            * Object permissions
                                            * Field-level security
                                    ✅ You must still manually check:
                                ```apex
                                    Schema.sObjectType.Account.isAccessible()```
                        
                    Example 2 : If you run this query without object access and record access
                                        [SELECT Id FROM Account];
                                                ✅ Runs successfully
                                                ❌ Even without object access

                    Example 3 : 🔥When WOULD it fail?
                                        [SELECT Id FROM Account WITH SECURITY_ENFORCED];
                                        O/P ---> System.QueryException

                    Example 4 : ✅ Scenario Class: with sharing
                                        User:
                                        ❌ No object permission
                                        ❌ No record access
                                    Performing DML (insert/update/delete)        
                                👉 DML operation will STILL succeed ✅ (No exception)
                                
                                ✅ 1. Apex runs in System Context
                                    Object permissions are NOT enforced automatically
                                    So even if user cannot:
                                        Read
                                        Create
                                        Update
                                        Delete
                                    👉 Apex still executes DML

                            ❌ DML can STILL fail due to:
                                        Validation rules
                                        Required fields missing
                                        Triggers throwing errors
                                        Duplicate rules
                                        System limits
                                        👉 But NOT due to:
                                        Object permission
                                        Field permission

                    ❌ DML is blocked if we use below code
                                        if (!Schema.sObjectType.Account.isCreateable()) {
                                        throw new AuthorizationException('No create access');
                                    }

                    insert new Account(Name = 'Test');
        
***
## 🔥 when apex code runs in user context?
        👉 Apex runs in user context ONLY when you explicitly enforce it.
✅ 🔹 1. Using WITH SECURITY_ENFORCED (SOQL)
            List<Account> accs = [
                SELECT Id FROM Account WITH SECURITY_ENFORCED
            ];
            👉 Enforces:
                ✅ Object permissions
                ✅ Field-level security

✅ 🔹 2. Using Schema Methods (CRUD Checks)
            if (!Schema.sObjectType.Account.isAccessible()) {
                throw new AuthorizationException();
            }
                👉 Enforces:
                ✅ Object-level permissions

✅ 🔹 3. Using Security.stripInaccessible
        Security.stripInaccessible(AccessType.READABLE, records);
            👉 Enforces:
            ✅ Field-level security

✅ 🔹 4. with sharing (Partial user context)
            👉 Enforces:
            ✅ Record-level access

can we peform DML in without sharing class?
👉 Even in a without sharing class, DML succeeds without object permission because Apex runs in system context and ignores CRUD security unless explicitly enforced.

## 🔥 Q2: Can a user without object permission still query data and peform dml in Apex?
👉 **Answer: YES**
            ✔ Because Apex runs in **system context**
            ```apex
            List<Account> accs = [SELECT Id FROM Account];
                   OR
            Account acc = new Account(Name = 'Test');
            insert acc;
            ```
            ✅ Works even if user has no access
            ✅ DML operations still execute
            ❌ Object permissions are ignored
            ❌ Field-level security is ignored
            ***
🔸 Case 1: Manual Check (Best Practice)
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new AuthorizationException('No create access');
        }
    insert new Account(Name = 'Test');
👉 ❌ Now it fails with: System.AuthorizationException

## 🔥 Q3: Then how do you enforce object security in SOQL?
👉 Use:
        ```apex
        WITH SECURITY_ENFORCED
        ```
        ✅ Example:
        ```apex
        SELECT Id FROM Account WITH SECURITY_ENFORCED
        ```
        ❌ Without access → throws:

        ```
        System.QueryException
        ```
    ***

## 🔥 Q4: Difference between `WITH SECURITY_ENFORCED` and `stripInaccessible`?

            | Feature      | WITH SECURITY\_ENFORCED | stripInaccessible  |
            | ------------ | ----------------------- | ------------------ |
            | Object check | ✅ Yes                   | ❌ No               |
            | Field check  | ✅ Yes                   | ✅ Yes              |
            | Behavior     | ❌ Throws error          | ✅ Removes fields   |
            | Use case     | Strict enforcement      | Safe data handling |

            ***
## 🔥 Q5: Does `without sharing` give more permissions?
👉 **Tricky answer: NO**
❌ Ignores record-level sharing rules
✅ Allows access to all records


✔ It only affects:
* Record visibility
        ❌ It does NOT:
        * Grant object access
        * Grant field access
        👉 It just ignores sharing rules
        ***
## 🔥 Q6: What is the biggest security mistake in Apex?
👉 Not enforcing CRUD + FLS
Example (BAD):

```apex
insert new Account(Name='Test');
```

✅ Works even if user has no create permission  
❌ Security risk

***

## 🔥 Q7: What is the best secure Apex pattern?

✅ Answer:

```apex
if (!Schema.sObjectType.Account.isCreateable()) {
    throw new AuthorizationException();
}

SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.CREATABLE,
    new List<Account>{ new Account(Name='Test') }
);

insert decision.getRecords();
```

***

## 🔥 Q8: What happens in this scenario?

### Code:

```apex
public with sharing class TestCls {
    public static void run() {
        List<Account> accs = [SELECT Id FROM Account];
    }
}
```
### User:
* ❌ No object access
* ❌ No record access

👉 Result:

✅ Query runs  
✅ No exception  
❌ May return empty (if no shared records)

***

## 🔥 Q9: What is `inherited sharing`?

👉 Uses the **caller’s context**

Example:

* Called from `with sharing` → behaves as **with sharing**
* Called from `without sharing` → behaves as **without sharing**

✔ Best practice for reusable classes

***

## 🔥 Q10: Why does Salesforce use System Context?

👉 To:

* Run automation
* Ensure business logic executes
* Avoid permission blocking in backend

***

# ✅ 🔷 Golden Interview Summary

👉 Say this confidently:

> Apex runs in **system context by default**, which ignores object and field permissions.  
> `with sharing` only enforces **record-level access**, not CRUD/FLS.  
> To achieve full security, we must explicitly enforce **object and field permissions** using `Schema`, `stripInaccessible`, or `WITH SECURITY_ENFORCED`.

***

# ✅ 🔥 Bonus: One-Line Memory Trick

👉 **"Sharing controls records, not permissions."**

***

If you want, I can give you:
✅ Real-time **scenario-based questions (like LWC + Apex security)**  
✅ OR a **cheat sheet PDF (since you prefer downloads)**

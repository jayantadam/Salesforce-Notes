Good — this error is actually **useful and expected** ✅

```
"errorCode":"invalid_client",
"errorSummary":"Invalid value for 'client_id' parameter."
```

***

# ✅ ✅ What this means (simple)

👉 The request **reached Okta successfully** ✅  
👉 DNS, endpoint, and payload are all **correct** ✅

But:

> ❌ The `client_id` you used is NOT valid in that Okta tenant

***

# ✅ ✅ Why you're getting this

You imported my collection which had:

```
clientId
clientSecret
```

👉 Those are just placeholders — not real credentials  
👉 Okta is correctly rejecting them

***

# ✅ ✅ This is actually GOOD progress

You’ve now confirmed:

✔ URL is correct  
✔ Network/DNS is working  
✔ Request format is correct  
✔ OAuth flow is correct

👉 Only thing missing: **valid credentials**

***

# ✅ ✅ How to fix (guaranteed working path)

## 🔹 Step 1: Create free Okta account

👉 <https://developer.okta.com>

***

## 🔹 Step 2: Create OAuth App

1. Go to:
   **Applications → Create App Integration**

2. Select:
   * **API Services** ✅ (important)

3. Click **Next**

***

## 🔹 Step 3: Copy credentials

You’ll get:

```
Client ID
Client Secret
```

***

## 🔹 Step 4: Use SAME Postman request

### ✅ URL:

```
https://YOUR_OKTA_DOMAIN/oauth2/default/v1/token
```

### ✅ Authorization tab:

* Type: **Basic Auth**
  * Username = client\_id
  * Password = client\_secret

***

### ✅ Body:

```
grant_type=client_credentials
scope=customScope
```

***

# ✅ ✅ Expected success response

```json
{
  "access_token": "eyJraWQiOiJ...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

***

# ✅ ✅ Why there’s no “public working credentials”

Important concept:

👉 OAuth Client Credentials is **secure by design**

So:

* ❌ No provider gives public `client_id` + `secret`
* ✅ You must generate your own

***

# ✅ ✅ Quick mental model

| Stage          | Status                      |
| -------------- | --------------------------- |
| DNS            | ✅ Fixed                     |
| Endpoint       | ✅ Correct                   |
| Payload        | ✅ Correct                   |
| Authentication | ❌ Invalid client (expected) |

***

# ✅ ✅ If your goal is Salesforce testing

Once this works, I can give you:

✅ Named Credential config (new External Credential model)  
✅ Apex callout code  
✅ Token auto-handling setup

***

# ✅ 🚀 Bottom line

👉 You are **95% done**  
👉 Just replace:

```
clientId → real client_id  
clientSecret → real client_secret  
```

and it will work instantly ✅

***

If you want, I can:

* Walk you **click-by-click in Okta (2 mins)**
* Or give you a **Salesforce-ready setup using this token**

Just say 👍

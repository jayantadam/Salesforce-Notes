
// contactPanel.js
import { LightningElement, api, wire, track } from 'lwc';
import getContactsByAccount from '@salesforce/apex/ContactService.getContactsByAccount';
import upsertContact from '@salesforce/apex/ContactService.upsertContact';
import { refreshApex } from '@salesforce/apex';

// Example HTML snippet to display contacts:'
//   <template if:true={contacts.length}>
//         <template for:each={contacts} for:item="o">
//           <div key={o.Id} class="slds-box slds-m-vertical_xx-small">
//             <div class="slds-text-heading_small">{o.Name}</div>
//             <div>{o.StageName} — ₹{o.Amount} — {o.CloseDate}</div>
//           </div>
//         </template>
//       </template>
  // this.dispatchEvent(new CustomEvent('payloadSubmit',{detail:{id:1,name:'alex'}})); syntax for dispatching event to parent component
export default class ContactPanel extends LightningElement {
    @api recordId;             // Account Id (coming from a record page)
    @track contacts = [];
    @track error;
    limitSize = 10;

    // Holds the wired result for refreshApex
    wiredContactsResult;

    // --- @wire (reactive) ---
    @wire(getContactsByAccount, { accountId: '$recordId', limitSize: '$limitSize' })
    wiredContacts({ data, error }) {
    if (data) {
        this.contacts = data;
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.contacts = undefined;
    }
}

   

    // --- Imperative call (on button/action) ---
    async handleSave() {
        // Example payload from form inputs
        const form = this.template.querySelector('form');
        const fields = {
            Id: form?.dataset?.contactId || null,
            AccountId: this.recordId,
            FirstName: this.template.querySelector('[data-id="firstName"]')?.value,
            LastName: this.template.querySelector('[data-id="lastName"]')?.value,
            Email: this.template.querySelector('[data-id="email"]')?.value,
            Phone: this.template.querySelector('[data-id="phone"]')?.value
        };

        try {
            this.error = undefined;
            const saved = await upsertContact({ c: fields }).then(res=> res).catch(err=> {throw err;});
            console.log('saved', saved);
            // Refresh the wired list so UI reflects changes
            await refreshApex(this.wiredContactsResult);
            // Optionally, show a toast
            this.showToast('Success', `Saved ${saved.Name}`, 'success');
        } catch (e) {
            this.error = this.normalizeError(e);
            this.showToast('Error', this.error, 'error');
        }
    }

    handleLimitChange(event) {
        // Changing limitSize (a reactive param) automatically re-invokes the wire
        this.limitSize = Number(event.target.value) || 10;
          }

    showToast(title, message, variant) {
        // optional: import ShowToastEvent if you want real toasts in org UIs
        // this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
        // For this snippet, we'll just log:
        // eslint-disable-next-line no-console
        console.log(`${variant?.toUpperCase() || 'INFO'}: ${title} - ${message}`);
    }

    normalizeError(err) {
        if (!err) return 'Unknown error';
        if (Array.isArray(err.body)) {
            return err.body.map(e => e.message).join(', ');
        } else if (typeof err.body?.message === 'string') {
            return err.body.message;
        }
        return err.statusText || err.message || JSON.stringify(err);
    }
}

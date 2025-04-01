import { api } from 'lwc';
import { LightningElement } from 'lwc';

export default class FwToast extends LightningElement {

    toastMessage = null;

    get toastClasses() {
        return 'slds-notify slds-notify_toast slds-theme_' + this.toastMessage.variant;
    }

    get toastIcon() {
        return 'utility:' + this.toastMessage.variant;
    }

    toastCloseClick() {
        this.toastMessage = null;
    }

    @api
    showToast(title, message, variant, timeout, dismissible) {
        const timestamp = Date.now().valueOf();
        this.toastMessage = {
            title: title,
            message: message,
            variant: variant ? variant : 'info',
            timestamp: timestamp,
            dismissible: (dismissible === undefined || dismissible === null) ? true : (dismissible == true)
        };

        // Auto-hide after 5 seconds
        if (timeout === undefined || timeout > 0) {
            setTimeout(() => {
                if (this.toastMessage && this.toastMessage.timestamp === timestamp) {
                    this.toastMessage = null;
                }
            }, (timeout ? timeout : 5000));
        }
    }
}
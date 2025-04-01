import {api, LightningElement, track} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import getModel from '@salesforce/apex/SPGAccountController.getModel';

export default class SpgAccount extends LightningElement {
    @api recordId;
    @track retrievedRecordId = false;
    @track model = null;
    @track hasModel = false;

    renderedCallback() {
        if (!this.retrievedRecordId && this.recordId) {
            this.retrievedRecordId = true; // Escape case from recursion
            this.getModel();
        }
    }

    getModel() {
        getModel({accountId: this.recordId})
            .then((result) => {
                this.model = result;
                this.hasModel = true;
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
            });
    }

    handleRecordSaved(event){
        this.getModel();
    }

    handleClose(event) {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
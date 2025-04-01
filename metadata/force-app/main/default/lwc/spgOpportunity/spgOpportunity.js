import { api, LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from 'lightning/actions';
import getModel from "@salesforce/apex/SPGOpportunityController.getModel";
import currentVendorHeader from '@salesforce/label/c.SPG_Opp_CurrentVendor_tab_header';
import competitorsHeader from '@salesforce/label/c.SPG_Opp_Competitors_tab_header';
import buyingCommitteeHeader from '@salesforce/label/c.SPG_Opp_Buying_Committee_tab_header';

export default class SpgOpportunity extends LightningElement {
    @api recordId;
    @track retrievedRecordId = false;
    @track model = {};
    @track hasModel = false;
    @track showSpiced = false;
    @track showAccountMerge = false;

    label={
        currentVendorHeader,
        competitorsHeader,
        buyingCommitteeHeader
    };

    renderedCallback() {
        if (!this.retrievedRecordId && this.recordId) {
            this.retrievedRecordId = true; // Escape case from recursion
            this.getModel();
        }
    }

    get isNewBusiness(){
        if(this.model == {}){
            return false;
        }
        return this.model.opportunityRecordType == "Default_Opportunity_Record_Type";
    }

    getModel() {
        getModel({ opportunityId: this.recordId })
            .then((result) => {
                this.model = result;
                console.log(JSON.parse(JSON.stringify(this.model)));
                this.hasModel = true;
                this.showSpiced = this.model.opportunityRecordType === "Default_Opportunity_Record_Type";
                this.showAccountMerge = this.model.opportunityRecordType === "Default_Opportunity_Record_Type";
            })
            .catch((error) => {
                console.log(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            })
            .finally(() => {});
    }

    handleRecordSaved(event){
        this.getModel();
    }

    handleClose(event) {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
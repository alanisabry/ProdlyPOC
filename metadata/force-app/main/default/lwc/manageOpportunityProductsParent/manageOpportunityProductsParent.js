import { LightningElement, api } from 'lwc';

export default class ManageOpportunityProductsParent extends LightningElement {
    @api recordId; 
    @api showManageOpportunityProducts = false;

    handleShowAddRemoveProducts(event) {
        this.recordId = event.detail.recordId;
        this.showManageOpportunityProducts = true;
    }
}
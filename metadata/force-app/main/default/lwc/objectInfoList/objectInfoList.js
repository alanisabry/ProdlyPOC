import {LightningElement, api, track, wire} from "lwc";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";


export default class ObjectInfoList extends LightningElement {
    @api recordId;
    @api objApiName;
    @api iconName;
    @api title;
    @api objs;
    @api objFields;
    @api objColumns;
    @api addLabel;
    @api tabHeader;
    @api formattedTabHeader;
    @api showAccountMerge;
    @api parentRecordId;
    @api parentLookupApiName;
    @track showDetails = false;
    editRecord;
    showSpinner = false;
    formattedTabHeader = '<h2><s>this.tabHeader</s>\n</h2>';

    @wire(getObjectInfo, { objectApiName: '$objApiName'})
    objectInfo;

    get newFields(){
        let values = [];
        if(this.objFields && this.objFields.length > 0){
            for (let i = 0; i < this.objFields.length; i++) {
                const field = this.objFields[i];
                if(field != 'Id'){
                    if(field == this.parentLookupApiName){
                        values.push({label: field, value: this.parentRecordId});
                    }
                    else{
                        values.push({label: field, value: this.getfieldType(field)});
                    }
                }
            }
            console.log(values);
        }
        return values;
    }

    get isPartner(){
        //debugger;
        return this.objApiName == 'OpportunityPartner';
    }

    get colSize(){
        return this.objColumns == 1 ? 12 : this.objColumns == 2 ? 6 : this.objColumns == 3 ? 4 : 3;
    }

    getfieldType(fieldName) {
        if(this.objectInfo.data.fields[fieldName] != undefined){
            const fieldType = this.objectInfo.data.fields[fieldName].dataType;
            return fieldType == 'Boolean' ? false : null;
        }
        return null;
    }

    handleClick(event) {
        if (event.target.name === "addButton") {
            console.log("add clicked");
            this.recordId = null;
            this.showDetails = true;
        }
    }

    handleSuccess(event) {
        console.log("Record Edit Success");
        this.recordId = null;
        this.showDetails = false;
        this.dispatchSaveEvent();
        this.showSpinner = false;
    }

    handleAbort(event) {
        console.log("Record Edit Abort");
        this.recordId = null;
        this.showDetails = false;
    }

    handleCancel(event) {
        console.log("New Record Cancel");
        this.recordId = null;
        this.showDetails = false;
    }

    handleNewSuccess(event) {
        console.log("New Record Save Success");
        this.showSpinner = false;
        this.recordId = null;
        this.showDetails = false;
        this.dispatchSaveEvent();
    }

    handleSubmit(event) {
        this.showSpinner = true;
    }

    dispatchSaveEvent(){
        this.objs = [];
        const e = new CustomEvent('recordsaved');

        // Dispatches the event.
        this.dispatchEvent(e);
    }
}
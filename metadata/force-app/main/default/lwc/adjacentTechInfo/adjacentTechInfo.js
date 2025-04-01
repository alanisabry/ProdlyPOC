import {LightningElement, api, track, wire} from "lwc";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class adjacentTechInfoList extends LightningElement {
    @api recordId;
    @api objApiName;
    @api iconName;
    @api title;
    @api objs;
    @api objFields;
    @api objColumns;
    @api addLabel;
    @api showAccountMerge;
    @api parentRecordId;
    @api parentLookupApiName;
    @track showDetails = false;
    editRecord;
    loaded = false;
    showSpinner = false;

    @wire(getObjectInfo, { objectApiName: '$objApiName'})
    objectInfo;
    
    get fieldSets(){
        let values = [];
        for (const key in this.objFields) {
            if(this.objFields[key]){
                const fields = this.objFields[key];
                values.push({name: key, values: fields});
            }
        }
        return values
    }

    get newFields(){
        let values = [];
        for (const key in this.objFields) {
            if(this.objFields[key]){
                const fields = this.objFields[key];
                for (let i = 0; i < fields.length; i++) {
                    const field = fields[i];
                    if(field == this.parentLookupApiName){
                        values.push({label: field, value: this.parentRecordId});
                    }
                    else{
                        values.push({label: field, value: this.getfieldType(field)});
                    }
                }
            }
            
        }
        return values
    }

    get isLoaded(){
        return this.fieldSets.length > 0;
    }

    get colSize(){
        return this.objColumns == 1 ? 12 : this.objColumns == 2 ? 6 : this.objColumns == 3 ? 4 : 3;
    }

    getfieldType(fieldName) {
        console.log(this.objectInfo);
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

    handleError(event) {
        this.showSpinner = false;
    }

    dispatchSaveEvent(){
        const e = new CustomEvent('recordsaved');

        // Dispatches the event.
        this.dispatchEvent(e);
    }
}
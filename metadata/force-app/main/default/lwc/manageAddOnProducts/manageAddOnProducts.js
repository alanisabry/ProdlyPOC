import { LightningElement,api, wire, } from 'lwc';
import getAddOns from '@salesforce/apex/ManageOpportunityProducts.getAddOns';
import LightningModal from 'lightning/modal';

export default class ManageAddOnProducts extends LightningModal {
    showModal = false;
    loadingCart = false;
    addOnProducts = [];
    addOnsCart = [];
    cartWithAddOns = [];
    duplicateAddOn = false;
    oppType =null;
    @api invokedObject;
    @api productInfo;
    @api lineItemInfo;
    @api shoppingCart;
    @api triggeringRecord;
    @api parentProduct;

     connectedCallback(){
        console.log('On load');
        if(this.invokedObject =='Opportunity'){
            this.oppType = this.triggeringRecord.Type;
        }else{
            this.oppType = this.triggeringRecord.Opportunity.Type;
        }
        this.getAddOnsCart();
    }
    get headerLabel(){
        return 'Select Additional limits for '+this.parentProduct.PricebookEntry.Product2.Product_Name__c;
    }
    get noLineItems() {
        return !this.addOnsCart.length;
    }
    get defaultPriceLabel(){
        return this.invokedObject =='Opportunity'?this.lineItemInfo.fields.Default_Price_ARR__c.label:this.lineItemInfo.fields.Default_Price_ARR_One_off__c.label;
    }
    
    get salesPriceLabel(){
        return this.invokedObject =='Opportunity'?this.lineItemInfo.fields.Sales_Price_ARR__c.label:this.lineItemInfo.fields.Sales_Price_ARR_One_off__c.label;
    }
    
    
    getAddOnsCart(){
        console.log('opp currency:'+this.oppCurrency);   
       getAddOns({ parentProductID:this.parentProduct.productId, oppCurrency: this.triggeringRecord.CurrencyIsoCode, pricebookID: this.triggeringRecord.Pricebook2Id })
            .then(depProductJson => {
                    console.log("Result1:" +depProductJson);        
                    this.addOnProducts = JSON.parse(depProductJson);               
                // Add additional limit products to the shopping cart
                if(this.addOnProducts != null){
                        for (let index = 0; index < this.addOnProducts.length; index++) {
                            const addOnProduct = this.addOnProducts[index];
                            this.duplicateAddOn = false;
                            for(let index = 0; index < this.shoppingCart.length; index++){
                                if(this.shoppingCart[index].productId == addOnProduct.Product2Id){
                                    this.duplicateAddOn = true;
                                    break;
                            }
                        }
                        if(!this.duplicateAddOn){
                        this.addOnsCart.push({
                            // Custom data
                            index: this.addOnsCart.length,
                            classes: '',
                            isDeleted: false,
                            isAdded: false,
                            required: false,
                            isParent: false,
                            parentIndex: this.parentProduct.index,
                            // Line Item data
                            PricebookEntry: JSON.parse(JSON.stringify(addOnProduct)),
                            UnitPrice: addOnProduct.UnitPrice,
                            ConvertedDefaultPriceARR: addOnProduct.ConvertedUnitPriceARR,
                            form: {
                                Quantity:   1.00,
                                UnitPrice:  addOnProduct.UnitPrice,
                                Discount:   0.00,
                                Recurring_Discount__c: null,
                                Description: null,
                                Sales_Price_ARR__c: addOnProduct.List_Price_ARR_One_off__c,
                                Default_Price_ARR__c: addOnProduct.List_Price_ARR_One_off__c,
                                Part_of_Min_Commit__c:((this.oppType.includes('New Business') || this.oppType == 'Existing Business - Platform Transfer' ) && addOnProduct.Product2.For_Contract_Renewals__c?true:false),
                                Part_of_a_package__c: (this.oppType.includes('New Business') || this.oppTypee == 'Existing Business - Platform Transfer' ) && addOnProduct.Product2.Pricing_Availability__c == 'Enterprise'?true:false    
                            }
                        });
                }
            }
                console.log('AddOns Cart:'+this.addOnsCart);
                this.loadingCart = true;
            }
        }).catch(e => {
            console.log(JSON.stringify(e));
          });    
        } 

    // One of our product fields was changed
    onFieldBlur(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;

        // Copy field value to the item's form
        this.loadingCart = false;
        this.addOnsCart[index].form[field] = event.target.value;
        this.loadingCart = true;
    }

    handleSave(){
        console.log('Save button)');
        this.close(this.cartWithAddOns);
    }

    handleAddClick(event){
        console.log('Add button');
        this.loadingCart = false;
        const addItem = this.addOnsCart[event.target.dataset.index];
        this.cartWithAddOns.push({
            // Custom data
            index: this.cartWithAddOns.length,
            classes: '',
            isDeleted: false,
            required: false,
            isParent: false,
            parentIndex: this.parentProduct.index,
            productId: addItem.PricebookEntry.Product2Id,
            parentProductId: this.parentProduct.productId,
            pricingType: addItem.PricebookEntry.Product2.Pricing_Type__c,
            // Line Item data
            PricebookEntry: addItem.PricebookEntry,
            UnitPrice: addItem.UnitPrice,
            ConvertedDefaultPriceARR: addItem.ConvertedUnitPriceARR,
            form: {
                Quantity:   addItem.form.Quantity,
                UnitPrice:  addItem.UnitPrice,
                Discount:   0.00,
                Recurring_Discount__c: null,
                Description: 'Additional limit product added',
                Sales_Price_ARR__c: addItem.form.Sales_Price_ARR__c,
                Default_Price_ARR__c: addItem.form.Default_Price_ARR__c,
                Part_of_Min_Commit__c: addItem.form.Part_of_Min_Commit__c,
                Part_of_a_package__c: addItem.form.Part_of_a_package__c
            }
        });
        this.addOnsCart[event.target.dataset.index].isAdded = true;
        this.loadingCart = true;
        console.log('Updated Shopping Cart:)'+this.cartWithAddOns);    
    }

    undoAddClick(event){
        this.loadingCart = false;
        const removeIndex = event.target.dataset.index;
        this.cartWithAddOns.splice(removeIndex, 1);
            for (let index = 0; index < this.cartWithAddOns.length; index++) {
                this.cartWithAddOns[index].index = index;
            }
            this.addOnsCart[removeIndex].isAdded = false;
            this.loadingCart = true;
            console.log('Updated Shopping Cart:'+this.cartWithAddOns);

    }

    handleCancel(){
        console.log('Close button');
        this.close();
    }

    
}
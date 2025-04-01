import { api, wire , track} from 'lwc';
import AddOnModal from 'c/manageAddOnProducts';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getQuoteData, getPicklistValues, saveProducts, searchProducts, getRemovedQuoteLineItems , getPriceBookEntryDetails, deleteRemovedQuoteLineItems,getProductDependancies} from 'c/quoteService';
import QUOTE_LINE_ITEM_OBJECT from '@salesforce/schema/QuoteLineItem';
import PRICEBOOKENTRY_OBJECT from '@salesforce/schema/PricebookEntry';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import FwElement from 'c/fwElement';


export default class ManageQuoteProducts extends FwElement {
    @api recordId;
    loading = true;
    loadingCart = false;
    loadingProducts = false;
    loadingRemovedQuoteLineItems = false;
    searchQuery = null;
    resultsError = null;
    tooManyProducts = null;
    disablePartOfPackageCheckbox = false;
    disablePartOfMinCommitCheckbox = false;
    renderFlow = false;
    showEnterpriseTab = false;
    invokePricingFlow = false;
    calculatePrices = false;
    disableSave = false;

    // Data to fetch
    record = null;
    multipleCurrencies = false;
    defaultCurrency;
    defaultPrice;
    defaultPriceARR;
    convertedDefaultPriceARR;
    removedQuoteLineItems = [];
    removedQuoteLineItemsToDelete = [];
    availableProducts = [];
    availableProductsUpdated = [];
    standardPricingProducts = [];
    enterprisePricingProducts = [];
    requiredProducts = [];
    addOnProducts = [];
    addOnsCart = [];
 

    get initialized() {
        return this.hasRecord && this.productInfo && this.priceBookEntryInfo && this.quoteLineItemInfo;
    }
    get isDefaultCurrency() {
        return !this.multipleCurrencies || this.defaultCurrency === this.record.CurrencyIsoCode;
    }
    get hasRecord() {
        return this.record !== null;
    }
    get noAvailableProducts() {
        return !this.availableProducts.length;
    }

    get noRemovedQLIs() {
        return !this.removedQuoteLineItems.length;
    }
    get noLineItems() {
        return !this.shoppingCart.length;
    }

    get disableCalculatePrices() {
        return !this.disableSave;
    }

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }
    get shoppingCart() {

        // Empty Quote - initialize our list of line item records
        if (!this.record.QuoteLineItems) {
            this.record.QuoteLineItems = {
                records: []
            };
        }

        return this.record.QuoteLineItems.records;
    }
    get showSpinner() {
        return this.loading || !this.initialized;
    }

    initCallback() {
        this.init();
    }

    // Load the Quote record and existing products
    init() {
        this.loading = true;
        this.record = null;

        // Call getRemovedQuoteLineItems method
        super.callAsync(getRemovedQuoteLineItems, { recordId: this.recordId }).then(removedQLIs => {
            const data = JSON.parse(removedQLIs);
            for (let QLI of data){
                this.removedQuoteLineItems.push(QLI);
            }
            for (let index = 0; index < this.removedQuoteLineItems.length; index++ ){
                this.removedQuoteLineItems[index].index = index;
            }

            this.loadingRemovedQuoteLineItems = false;

            }).catch(e => {
                // Toast cannot be dismissed if page can not be loaded
                this.showToast(
                    'Failed to load Removed Quote Line Items',
                    ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                    '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Quote</a>',
                    'error',
                    -1,
                    false
                );
                setTimeout(() => {
                    this.loading = false;
                }, 0);
            });

        super.callAsync(getQuoteData, { recordId: this.recordId }).then(quoteDataJson => {
            const data = JSON.parse(quoteDataJson);

            // Copy our data to the component
            this.record = data.quote;
            this.multipleCurrencies = data.multipleCurrencies;
            this.defaultCurrency = data.defaultCurrency;
            
            // Process existing line items (Shopping Cart)
            for (let index = 0; index < this.shoppingCart.length; index++) {

                // Use index as the key (New items won't have an id)
                let lineItem = this.shoppingCart[index];
                lineItem.index = index;

                // Stage an edit form version of each item for use in the Selected Products section
                lineItem.form = JSON.parse(JSON.stringify(lineItem));

                // Default values
                lineItem.isDeleted = false;
                lineItem.required = false; //Specify Required attribute for Recurring Discount
                if (lineItem.Upsell_OLI_ID__c != null){
                     if (lineItem.Upsell_OLI_ID__r.Quantity > 0){
                        lineItem.iconName = 'utility:jump_to_top';
                        lineItem.iconVariant = 'success';
                    }
                    else if (lineItem.Upsell_OLI_ID__r.Quantity < 0){
                        lineItem.iconName = 'utility:jump_to_bottom';
                        lineItem.iconVariant = 'error';
                    }
                }
                lineItem.hasAddOn = lineItem.form.Product2.of_Additional_limit_products__c > 0 && lineItem.form.Quantity > 0 ? true:false;
                lineItem.productId =  lineItem.form.Product2Id;
                lineItem.parentProductId =   lineItem.form.Parent_Solution_Product__c;
                lineItem.pricingType =  lineItem.form.Product2.Pricing_Type__c;
            }
            // Enable 'Enterprise Pricing' tab when company size grouped on account is 'Large' and platform is 'Bynder'
            if(this.record.Account.Company_Size_Grouped__c == 'Large'&& this.record.Opportunity.Platform__c == 'Bynder'){
                this.showEnterpriseTab = true;
            }

            // Load products
            this.searchQuery = null;
            this.loadingProducts = true;
            this.searchProducts('', 0);

            // Initialize our Recurring Discount dropdowns - to select the actual lineItem value
            setTimeout(() => {
                this.template.querySelectorAll('select').forEach(selectElement => {

                    // Get this line's item
                    const lineItem = this.shoppingCart[selectElement.dataset.index];

                    // Go through each option
                    selectElement.querySelectorAll('option').forEach(optionElement => {

                        // If we find the matching option, select it and move on to next line item
                        if (optionElement.value === lineItem.form.Recurring_Discount__c) {
                            optionElement.selected = true;
                            return;
                        }
                    });
                });
                this.loading = false;
                
            }, 250);
        }).catch(e => {

            // Toast cannot be dismissed if page can not be loaded
            this.showToast(
                'Failed to load Quote record',
                ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Quote</a>',
                'error',
                -1,
                false
            );
            setTimeout(() => {
                this.loading = false;
            }, 0);
        });
    }

    showToast(title, message, variant, timeout, dismissible) {
        this.template.querySelector('c-fw-toast').showToast(title, message, variant, timeout, dismissible);
    }

    searchProducts(query, timeout) {

        // Is the query same as last query?
        if (this.searchQuery && this.searchQuery.query === query) {
            return;
        }

        // We delay a bit in case the user is still typing
        const timestamp = new Date().valueOf();
        this.searchQuery = {
            timestamp:  timestamp,
            query:      query
        };

        // Wait a moment in case they are still typing
        setTimeout(() => {

            // Is this the same query?
            if (this.searchQuery && this.searchQuery.timestamp === timestamp) {
                this.standardPricingProducts = [];
                this.enterprisePricingProducts = [];
                // Query the database
                this.loadingProducts = true;
                super.callAsync(searchProducts, { recordId: this.recordId, query: query }).then(resultsJson => {
                    this.availableProducts = JSON.parse(resultsJson);
                    for (let index = 0; index < this.availableProducts.length; index++) {
                        this.availableProducts[index].index = index;
                        console.log('Load Products');
                        if(this.record.Opportunity.OEM__c != null){
                        if((this.record.Opportunity.OEM__r.Name == 'Workfront') && (this.availableProducts[index].Workfront_List_Price__c != null || this.availableProducts[index].Workfront_Renewal_Price__c !=null)){
                            if(this.record.Account.Original_Contract_Start_Date__c == this.record.Account.Current_Contract_Start_Date_new__c){
                                this.availableProducts[index].List_Price_ARR_One_off__c = (this.availableProducts[index].Workfront_List_Price__c != null?this.availableProducts[index].Workfront_List_Price_ARR_One_off__c:this.availableProducts[index].List_Price_ARR_One_off__c);
                                this.availableProducts[index].ConvertedUnitPriceARR = (this.availableProducts[index].Workfront_List_Price__c != null?this.availableProducts[index].ConvertedWorkfrontPriceARR:this.availableProducts[index].ConvertedUnitPriceARR);
                            }else{
                                this.availableProducts[index].List_Price_ARR_One_off__c = (this.availableProducts[index].Workfront_Renewal_Price__c != null?this.availableProducts[index].Workfront_Renewal_Price_ARR_One_off__c:this.availableProducts[index].Workfront_List_Price_ARR_One_off__c);
                                this.availableProducts[index].ConvertedUnitPriceARR = (this.availableProducts[index].Workfront_Renewal_Price__c != null?this.availableProducts[index].ConvertedWorkfrontRenewalPriceARR:this.availableProducts[index].ConvertedUnitPriceARR);
                             }
                        }
                        if(this.record.Opportunity.OEM__r.Name == 'Acquia'  && this.availableProducts[index].Acquia_List_Price__c != null ){
                            this.availableProducts[index].List_Price_ARR_One_off__c = (this.availableProducts[index].Acquia_List_Price__c != null?this.availableProducts[index].Acquia_List_Price_ARR_One_off__c:this.availableProducts[index].List_Price_ARR_One_off__c);
                            this.availableProducts[index].ConvertedUnitPriceARR = (this.availableProducts[index].Acquia_List_Price__c != null?this.availableProducts[index].ConvertedAcquiaPriceARR:this.availableProducts[index].ConvertedUnitPriceARR);
                        }      
                    }
                    if(this.availableProducts[index].Product2.Pricing_Availability__c == 'Standard & Enterprise'){
                        this.standardPricingProducts.push(this.availableProducts[index]);
                        this.enterprisePricingProducts.push(this.availableProducts[index]);
                    }else if(this.availableProducts[index].Product2.Pricing_Availability__c == 'Enterprise'){
                        this.enterprisePricingProducts.push(this.availableProducts[index]);
                    }else{
                        this.standardPricingProducts.push(this.availableProducts[index]);
                    }
                }
                    this.resultsError = this.standardPricingProducts.length > 100 ? 'Your search returned over 100 results, use a more specific search string if you do not see the desired Product.' : null;
                    this.tooManyProducts = this.enterprisePricingProducts.length > 100 ? 'Your search returned over 100 results, use a more specific search string if you do not see the desired Product.' : null;
                }).catch(e => {
                    this.showToast(
                        'Failed to find products',
                        (e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e,
                        'error'
                    );
                }).finally(() => {
                    this.loadingProducts = false;
                })
            }
        }, timeout);
    }

    /// INPUT ACTIONS
    onRecurringDiscountChange(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Recurring_Discount__c = event.target.value;
        this.loadingCart = false;
    }

    onPartOfPackageChanged(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Part_of_Package__c = event.target.checked;
        this.loadingCart = false;
    }
    
    //Executed when 'Part of Min Commit?' field is changed
    onPartOfMinCommitChanged(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Part_of_Min_Commit__c = event.target.checked;
        this.loadingCart = false;
    }

    onSwapItemChanged(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Swap_Item__c = event.target.checked;
        this.loadingCart = false;
    }

    // Go back to the Quote record
    cancelClick() {
        window.open('/' + this.recordId, '_parent');
    }

    // Performs an upsert on the Quote Line Items
    saveClick() {
        // Validate our inputs
        let cartContainer = this.template.querySelector('.marker__select-products');
        const inputsValid = [...cartContainer.querySelectorAll('lightning-input')].concat([...cartContainer.querySelectorAll('lightning-combobox')])
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);
        // Invalid inputs (They will handle the display of error messages)
        if (!inputsValid) {
            return;
        }
        // Group up our data for the server call
        let data = this.shoppingCart.map(item => {
            return {
                isDeleted: item.isDeleted,
                dependentProductId : item.PricebookEntry.Product2.Dependent_Product__c,
                lineItem: {
                    Id: item.Id,
                    PricebookEntryId: item.PricebookEntry.Id,
                    For_Renewal__c: item.PricebookEntry.Product2.For_Contract_Renewals__c,
                    UnitPrice: item.form.UnitPrice,
                    Quantity: item.form.Quantity,
                    Discount: item.form.Discount,
                    Recurring_Discount__c: item.form.Recurring_Discount__c,
                    Description: item.form.Description,
                    Sales_Price_ARR_One_off__c: item.form.Sales_Price_ARR_One_off__c,
                    Default_Price_ARR_One_off__c: item.form.Default_Price_ARR_One_off__c,
                    Initial_Default_Price_ARR_One_off__c: item.form.Initial_Default_Price_ARR_One_off__c,
                    Product2Id : item.form.Product2Id,
                    Pricing_Factors_to_be_Applied__c: item.form.Pricing_Factors_to_be_Applied__c,
                    Part_of_Package__c : item.form.Part_of_Package__c,
                    Part_of_Min_Commit__c : item.form.Part_of_Min_Commit__c,
                    Swap_Item__c: item.form.Swap_Item__c,
                    Renewal_OLI_ID__c: item.form.Renewal_OLI_ID__c,
                    Upsell_OLI_ID__c: item.form.Upsell_OLI_ID__c,
                    Parent_Solution_Product__c : item.parentProductId
                }
            };
        });

        // Send the data to the server
        this.loading = true;
        super.callAsync(saveProducts, { recordId: this.recordId, dataJson: JSON.stringify(data)}).then(() => {
            // Re-initialize the form now
            if (this.removedQuoteLineItemsToDelete.length > 0){
                let toDeleteRQLIs = this.removedQuoteLineItemsToDelete.map(item => {
                    return{
                         Id: item.Id
                    };
                });
                super.callAsync(deleteRemovedQuoteLineItems, {removedQLIsToDelete: JSON.stringify(toDeleteRQLIs)}).then(() => {

                }).catch(e => {
                    this.loading = false;
                    this.showToast(
                        'Failed to save products',
                        (e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e,
                        'error'
                    );
                });
            }
            this.init();
            if(this.calculatePrices){
                this.invokePricingFlow = true;
            }else{
            this.showToast('Success', 'The products have been saved', 'success');
            window.open('/' + this.recordId, '_parent');
            }
            
        }).catch(e => {
            this.loading = false;
            this.showToast(
                'Failed to save products',
                (e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e,
                'error'
            );
        });
    }

    removeClick(event) {
        const removeIndex = event.target.dataset.index;
        this.loadingCart = true;

        // If this item was just added, delete it out-right and adjust ids
        if (!this.shoppingCart[removeIndex].Id) {
            this.shoppingCart.splice(removeIndex, 1);
            for (let index = 0; index < this.shoppingCart.length; index++) {
                 //Remove dependant items when parent is deleted
                if(this.shoppingCart[index].parentIndex == removeIndex && !this.shoppingCart[index].Id){
                    this.shoppingCart.splice(index, 1);
                    index--;
                }
                this.shoppingCart[index].index = index;
            }
        }
        // Pre-Existing Opp LineItem, flag it for deletion
        else {
            for (let index = 0; index < this.shoppingCart.length; index++) {
                //Remove dependant items when parent is deleted
               if(this.shoppingCart[index].parentProductId == this.shoppingCart[removeIndex].productId){
               this.shoppingCart[index].isDeleted = true;
                this.shoppingCart[index].classes = 'deleted';
               }
            }
            this.shoppingCart[removeIndex].isDeleted = true;
            this.shoppingCart[removeIndex].classes = 'deleted';            
    }
    this.loadingCart = false;
    }

    undoRemoveClick(event) {
        const undoIndex = event.target.dataset.index;

        this.loadingCart = true;
        this.shoppingCart[undoIndex].isDeleted = false;
        this.shoppingCart[undoIndex].classes = '';
        for(let index = 0; index < this.shoppingCart.length; index++){
            if(this.shoppingCart[index].parentProductId == this.shoppingCart[undoIndex].productId){
                this.shoppingCart[index].isDeleted = false;
                this.shoppingCart[index].classes = '';
            }
        }
        this.loadingCart = false;
    }

    // One of our product fields was changed
    onFieldBlur(event) {
        const index = event.target.dataset.index;
        const field = event.target.name;

        // Copy field value to the item's form
        this.loadingCart = true;
        this.shoppingCart[index].form[field] = event.target.value;
        this.loadingCart = false;
    }
    onSalesPriceChange(event) {
        const index = event.target.dataset.index;
        if(event.target.value < this.shoppingCart[index].ConvertedDefaultPriceARR && this.shoppingCart[index].For_Renewal__c){
            this.shoppingCart[index].required = true;
        }else{
            this.shoppingCart[index].required = false;
        }
    }

    selectRemovedLineItemProductClick(event) {
        const product = this.removedQuoteLineItems[event.target.dataset.index];

        //Duplication prevention logic
        if (this.removedQuoteLineItemsToDelete.indexOf(product) < 0){
            this.removedQuoteLineItemsToDelete.push(product);
        }
             
        let targetId = product.Id;
        let target = this.template.querySelector(`[data-id="${targetId}"]`);

        super.callAsync(getPriceBookEntryDetails, { preiceBookEntryId: product.Price_Book_Entry_ID__c }).then(priceBookEntryDataJson => {
        const removedItemPBE = JSON.parse(priceBookEntryDataJson);

        this.loadingCart = true;
        this.loadingRemovedQuoteLineItems = true;
        this.shoppingCart.push({
            // Custom data
            index: this.shoppingCart.length,
            classes: '',
            isDeleted: false,
            required: false,
            // Line Item data
            PricebookEntry: removedItemPBE,
            form: {
                Quantity:   product.Quantity__c,
                UnitPrice:  product.UnitPrice__c,
                Recurring_Discount__c: (product.Recurring_Discount__c == 'Yes'?'Yes':'No'),
                Default_Price_ARR_One_off__c: product.Default_Price_ARR_One_off__c,
                Sales_Price_ARR_One_off__c: product.Sales_Price_ARR_One_off__c,
                Initial_Default_Price_ARR_One_off__c: product.Initial_Default_Price_ARR_One_off__c,
                For_Renewal__c: product.For_Renewal__c,
                Part_of_Package__c: product.Part_of_Package__c,
                Swap_Item__c: product.Swap_Item__c,
                Renewal_OLI_ID__c: product.Renewal_OLI_ID__c,
                Upsell_OLI_ID__c: product.Upsell_OLI_ID__c,
                Pricing_Factors_to_be_Applied__c: product.Pricing_Factors_to_be_Applied__c,
                Part_of_Min_Commit__c: product.Part_of_Min_Commit__c
            }
        });
        
        target.style = 'text-decoration: line-through';
        this.loadingCart = false;
        this.loadingRemovedQuoteLineItems = false;
        }).catch(e => {

            // Toast cannot be dismissed if page can not be loaded
            this.showToast(
                'Failed to get PriceBookEntry Data for Removed QLI',
                ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Quote</a>',
                'error',
                -1,
                false
            );
            setTimeout(() => {
                this.loading = false;
            }, 0);
        });  
    }

    selectProductClick(event) {
        const product = this.availableProducts[event.target.dataset.index];
        console.log('Entered Product Click');
        this.defaultPrice = null;
        this.defaultPriceARR = null;
        this.ConvertedDefaultPriceARR = null;
        //set default price for OEM Quote line items
        if(this.record.Opportunity.OEM__c != null){
        if((this.record.Opportunity.OEM__r.Name == 'Workfront') && (product.Workfront_List_Price__c != null || product.Workfront_Renewal_Price__c !=null)){
            if(this.record.Account.Original_Contract_Start_Date__c == this.record.Account.Current_Contract_Start_Date_new__c){
                this.defaultPriceARR = (product.Workfront_List_Price__c != null?product.Workfront_List_Price_ARR_One_off__c:product.List_Price_ARR_One_off__c);
                this.defaultPrice = (product.Workfront_List_Price__c != null?product.Workfront_List_Price__c:product.UnitPrice);
                this.convertedDefaultPriceARR = (product.Workfront_List_Price__c != null?product.ConvertedWorkfrontPriceARR:product.ConvertedUnitPriceARR);
            }else{
                this.defaultPriceARR = (product.Workfront_Renewal_Price__c != null?product.Workfront_Renewal_Price_ARR_One_off__c:product.Workfront_List_Price_ARR_One_off__c);
                this.defaultPrice = (product.Workfront_Renewal_Price__c != null?product.Workfront_Renewal_Price__c:product.Workfront_List_Price__c);
                this.convertedDefaultPriceARR = (product.Workfront_Renewal_Price__c != null?product.ConvertedWorkfrontRenewalPriceARR:product.ConvertedUnitPriceARR);
             }
        }
        if(this.record.Opportunity.OEM__r.Name == 'Acquia' && product.Acquia_List_Price__c != null){
            this.defaultPriceARR = (product.Acquia_List_Price__c != null?product.Acquia_List_Price_ARR_One_off__c:product.List_Price_ARR_One_off__c);
            this.defaultPrice = (product.Acquia_List_Price__c != null?product.Acquia_List_Price__c:product.UnitPrice);
            this.convertedDefaultPriceARR = (product.Acquia_List_Price__c != null?product.ConvertedAcquiaPriceARR:product.ConvertedUnitPriceARR);
        }
    }
        // Prevent double selection
        this.loadingProducts = true;
        this.loadingCart = true;
        this.shoppingCart.push({
            // Custom data
            index: this.shoppingCart.length,
            classes: '',
            isDeleted: false,
            required: false,
            isParent: true,
            hasAddOn: product.Product2.of_Additional_limit_products__c > 0? true:false,
            productId: product.Product2Id,
            ParentProductId: null,
            pricingType: product.Product2.Pricing_Type__c,
            // Line Item data
            PricebookEntry: JSON.parse(JSON.stringify(product)),
            UnitPrice: product.UnitPrice,
            ConvertedDefaultPriceARR: (this.convertedDefaultPriceARR!=null?this.convertedDefaultPriceARR:product.ConvertedUnitPriceARR).toFixed(2),
            form: {
                Quantity:   1.00,
                UnitPrice:  product.UnitPrice,
                Discount:   0.00,
                Recurring_Discount__c: null,
                Description: null,
                For_Renewal__c : product.Product2.For_Contract_Renewals__c,
                Default_Price_ARR_One_off__c: (this.defaultPriceARR!=null?this.defaultPriceARR:product.List_Price_ARR_One_off__c).toFixed(2),
                Sales_Price_ARR_One_off__c: (this.defaultPriceARR!=null?this.defaultPriceARR:product.List_Price_ARR_One_off__c).toFixed(2)
            }
        });

        const parentIndex = this.shoppingCart.length - 1;
        // call an method to query the product rules and add dependant products
        super.callAsync(getProductDependancies, { parentProductID: product.Product2Id, oppCurrency: this.record.CurrencyIsoCode, pricebookID: this.record.Pricebook2Id  }).then(depProductJson => {
            const dependentProductData = JSON.parse(depProductJson);
            console.log("Result2:" +JSON.parse(depProductJson));

            this.requiredProducts = dependentProductData.requiredChildPBList;
            this.addOnProducts = dependentProductData.optionalChildPBList;
            if(this.requiredProducts != null){
                for (let index = 0; index < this.requiredProducts.length; index++) {
                    const reqProduct = this.requiredProducts[index];
                    this.shoppingCart.push({
                        // Custom data
                        index: this.shoppingCart.length,
                        classes: '',
                        isDeleted: false,
                        required: false,
                        isParent: false,
                        parentIndex: parentIndex,
                        productId: reqProduct.Product2Id,
                        parentProductId: product.Product2Id, 
                        pricingType: reqProduct.Product2.Pricing_Type__c,                      
                        // Line Item data
                        PricebookEntry: JSON.parse(JSON.stringify(reqProduct)),
                        UnitPrice: reqProduct.UnitPrice,
                        ConvertedDefaultPriceARR: (this.convertedDefaultPriceARR!=null?this.convertedDefaultPriceARR:reqProduct.ConvertedUnitPriceARR),
                        form: {
                            Quantity:   1.00,
                            UnitPrice:  reqProduct.UnitPrice,
                            Discount:   0.00,
                            Recurring_Discount__c: null,
                            Description: null,
                            Default_Price_ARR_One_off__c: (this.defaultPriceARR!=null?this.defaultPriceARR:reqProduct.List_Price_ARR_One_off__c),
                            Sales_Price_ARR_One_off__c: (this.defaultPriceARR!=null?this.defaultPriceARR:reqProduct.List_Price_ARR_One_off__c)                   
                        }
                    });
            }
        }
    }).catch(e => {
        this.showToast(
            'Failed to query dependant products',
            (e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e,
            'error'
        );
    }).finally(() => {
        this.loadingCart = false;
        this.loadingProducts = false;
    });

        // Short delay
       /* setTimeout(() => {
            this.loadingCart = false;
            this.loadingProducts = false;
        }, 250);*/
    }

    searchQueryChanged(event) {

        // Extract query and trim it
        let query = event.target.value;
        query = (query ? query.trim() : '');

        // Now pass to our method to search products
        this.searchProducts(query, 350);
    }

    /// WIRED UI LABEL HELPERS
    @wire(getObjectInfo, { objectApiName: QUOTE_LINE_ITEM_OBJECT })
    quoteLineItemInfoWire;
    get quoteLineItemInfo() {
        if (this.quoteLineItemInfoWire && this.quoteLineItemInfoWire.data) {
            return this.quoteLineItemInfoWire.data;
        }
        else {
            return null;
        };
    }
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    productInfoWire;
    get productInfo() {
        if (this.productInfoWire && this.productInfoWire.data) {
            return this.productInfoWire.data;
        }
        else {
            return null;
        };
    }
    @wire(getObjectInfo, { objectApiName: PRICEBOOKENTRY_OBJECT })
    priceBookEntryInfoWire;
    get priceBookEntryInfo() {
        if (this.priceBookEntryInfoWire && this.priceBookEntryInfoWire.data) {
            return this.priceBookEntryInfoWire.data;
        }
        else {
            return null;
        };
    }

    /// PICKLIST VALUES
    @wire(getPicklistValues, { fieldApiName: 'Recurring_Discount__c' })
    recurringDiscountValuesWire;
    get recurringDiscountValues() {
        if (this.recurringDiscountValuesWire && this.recurringDiscountValuesWire.data) {
            return JSON.parse(this.recurringDiscountValuesWire.data);
        }
        else {
            return [];
        }
    }
     //Method to open the modal for adding additional limit products to cart
        async handleClick(event) {
                    const result = await AddOnModal.open({
                        label: 'Select Add Ons',
                        size: 'medium',
                        description: 'Accessible description of modal\'s purpose',
                        showModal:true,
                        shoppingCart: this.shoppingCart,
                        productInfo: this.productInfoWire.data,
                        lineItemInfo: this.quoteLineItemInfoWire.data,
                        invokedObject: 'Quote',
                        triggeringRecord: this.record,
                        parentProduct:  this.shoppingCart[event.target.dataset.index],
                    });
                    if(result != undefined){
                        this.loadingCart = true;
                    for (let index = 0; index < result.length; index++) {
                    const addOn = result[index];
                        this.shoppingCart.push({
                            // Custom data
                            index: this.shoppingCart.length,
                            classes: '',
                            isDeleted: false,
                            required: false,
                            isParent: false,
                            parentIndex: addOn.parentIndex,
                            productId: addOn.productId,
                            parentProductId: addOn.parentProductId,
                            pricingType: addOn.pricingType,
                            // Line Item data
                            PricebookEntry: JSON.parse(JSON.stringify(addOn.PricebookEntry)),
                            UnitPrice: addOn.UnitPrice,
                            ConvertedDefaultPriceARR: addOn.ConvertedUnitPriceARR,
                            form: {
                                Quantity:   addOn.form.Quantity,
                                UnitPrice:  addOn.UnitPrice,
                                Discount:   0.00,
                                Recurring_Discount__c: null,
                                Description: addOn.Description,
                                Sales_Price_ARR_One_off__c: addOn.form.Sales_Price_ARR__c,
                                Default_Price_ARR_One_off__c: addOn.form.Default_Price_ARR__c
                            }
                        });
                    }
                    this.loadingCart = false;
                    this.disableSave = true;
                }
            }
    // Method invoked when calculate prices button is clicked
            calculatePricesClick(){
                console.log('Calculate Prices');
                this.calculatePrices = true;
                    this.saveClick(); 
            }
    // Method invoked when the pricing procedure flow is executed
            handleStatusChange(event) {
                if (event.detail.status === 'FINISHED') {
                    // set behavior after a finished flow interview
                    console.log('Flow executed successfully');
                    this.invokePricingFlow = false;
                    this.init();
                    this.disableSave = false; 
                    this.calculatePrices = false;
                    this.showToast('Success', 'The prices have been calculated', 'success');
                } else if (event.detail.status === 'ERROR') {
                    // handle errors   
                    this.invokePricingFlow = false;
                    this.init();
                    this.calculatePrices = false;
                    this.showToast('Error', 'The price calculation has failed', 'error');
                }
            }   
    //Method on change of quantity in the selected products
            onQuantityChange(event){
                const index = event.target.dataset.index;
                if(this.shoppingCart[index].pricingType == 'Special Pricing' && event.target.value > 0){
                    this.disableSave = true;
                }
            }

    
}
import { api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import AddOnModal from 'c/manageAddOnProducts';
import { getOpportunityData, getPicklistValues , saveProducts, searchProducts ,getOpenOpportunitiesForAccount , getOpenOpportunityLineItems , searchUpsellProducts, getProductDependancies } from 'c/opportunityService';
import OPPORTUNITY_LINE_ITEM_OBJECT from '@salesforce/schema/OpportunityLineItem';
import PRICEBOOKENTRY_OBJECT from '@salesforce/schema/PricebookEntry';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import FwElement from 'c/fwElement';
import Comments_Other_Clauses__c from '@salesforce/schema/Account.Comments_Other_Clauses__c';

export default class ManageUpsellOpportunityProducts extends FwElement {
    @api recordId;
    loading = true;
    loadingCart = false;
    loadingProducts = false;
    loadingCustomerPortfolioProducts = false;
    searchQuery = null;
    resultsError = null;
    disablePartOfPackageCheckbox = false;
    disablePartOfMinCommitCheckbox = false;
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
    customerOpenOpportunities = [];
    customerPortfolioProducts = [];
    availableProducts = [];
    availableProductsUpdated = [];
    standardPricingProducts = [];
    enterprisePricingProducts = [];
    requiredProducts = [];
    addOnProducts = [];
    addOnsCart = [];
    

    get initialized() {
        return this.hasRecord && this.productInfo && this.priceBookEntryInfo && this.oppLineItemInfo;
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

    get noCustomerPortfolioProducts() {
        return !this.customerPortfolioProducts.length;
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

        // Empty Opportunity - initialize our list of line item records
        if (!this.record.OpportunityLineItems) {
            this.record.OpportunityLineItems = {
                records: []
            };
        }

        return this.record.OpportunityLineItems.records;
    }
    get showSpinner() {
        return this.loading || !this.initialized;
    }

    initCallback() {
        this.init();
    }

    // Load the Opportunity record and existing products
    init() {
        this.loading = true;
        this.record = null;

        // Call getOpenOpportunitiesForAccount method
        super.callAsync(getOpenOpportunitiesForAccount, { recordId: this.recordId }).then(openOpportunities => {
            this.customerPortfolioProducts = [];
            this.customerOpenOpportunities = JSON.parse(openOpportunities);
            for (let opportunity of this.customerOpenOpportunities ){
                let opportunityId = opportunity.Id;
                super.callAsync(getOpenOpportunityLineItems, { recordId: opportunityId }).then(openOpportunityLineItems => {
                    const data = JSON.parse(openOpportunityLineItems);
                    for (let OLI of data){
                        this.customerPortfolioProducts.push(OLI);
                    }
                    for (let index = 0; index < this.customerPortfolioProducts.length; index++ ){
                        this.customerPortfolioProducts[index].index = index;
                    }
                }).catch(e => {
                    // Toast cannot be dismissed if page can not be loaded
                    this.showToast(
                        'Failed to load Customer Portfolio Items - Getting Open Opps Line Items',
                        ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                        '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Opportunity</a>',
                        'error',
                        -1,
                        false
                    );
                    setTimeout(() => {
                        this.loading = false;
                    }, 0);
                });
            }
            this.loadingCustomerPortfolioProducts = false;

            }).catch(e => {
                // Toast cannot be dismissed if page can not be loaded
                this.showToast(
                    'Failed to load Customer Portfolio Items',
                    ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                    '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Opportunity</a>',
                    'error',
                    -1,
                    false
                );
                setTimeout(() => {
                    this.loading = false;
                }, 0);
            });

        super.callAsync(getOpportunityData, { recordId: this.recordId }).then(opportunityDataJson => {
            const data = JSON.parse(opportunityDataJson);

            // Copy our data to the component
            this.record = data.opportunity;
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
                lineItem.hasAddOn = lineItem.form.Product2.of_Additional_limit_products__c > 0 && lineItem.form.Quantity > 0 ? true:false;
                lineItem.productId =  lineItem.form.Product2Id;
                lineItem.parentProductId =   lineItem.form.Parent_Solution_Product__c;
                lineItem.pricingType =  lineItem.form.Product2.Pricing_Type__c;
                lineItem.portfolioOliId = lineItem.form.Portfolio_OLI_ID__c;
            }

            if(this.record.Type.includes('New Business') || this.record.Type == 'Existing Business-Professional Services' || this.record.Type == 'Existing Business - Platform Transfer'
            || this.record.Type == 'Referral'){
                this.disablePartOfMinCommitCheckbox = true;
            }

            // Enable 'Enterprise Pricing' tab when company size grouped on account is 'Large' and platform is 'Bynder'
            if((this.record.Account.Company_Size_Grouped__c == 'Large'&& this.record.Platform__c == 'Bynder')|| data.pricingSuperUser){
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
                'Failed to load Opportunity record',
                ((e && e.body && e.body.message) ? JSON.parse(e.body.message).message : e) +
                '<br /><a href="/' + this.recordId + '" title="Go Back">Back to Opportunity</a>',
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
                super.callAsync(searchUpsellProducts, { recordId: this.recordId, query: query }).then(resultsJson => {
                    this.availableProducts = JSON.parse(resultsJson);
                    for (let index = 0; index < this.availableProducts.length; index++) {
                        this.availableProducts[index].index = index;
                        console.log('Load Products');
                        if(this.record.OEM__c != null){
                        if((this.record.OEM__r.Name == 'Workfront') && (this.availableProducts[index].Workfront_List_Price__c != null || this.availableProducts[index].Workfront_Renewal_Price__c !=null)){
                            if(this.record.Account.Original_Contract_Start_Date__c == this.record.Account.Current_Contract_Start_Date_new__c){
                                this.availableProducts[index].List_Price_ARR_One_off__c = (this.availableProducts[index].Workfront_List_Price__c != null?this.availableProducts[index].Workfront_List_Price_ARR_One_off__c:this.availableProducts[index].List_Price_ARR_One_off__c);
                                this.availableProducts[index].ConvertedUnitPriceARR = (this.availableProducts[index].Workfront_List_Price__c != null?this.availableProducts[index].ConvertedWorkfrontPriceARR:this.availableProducts[index].ConvertedUnitPriceARR);
                            }else{
                                this.availableProducts[index].List_Price_ARR_One_off__c = (this.availableProducts[index].Workfront_Renewal_Price__c != null?this.availableProducts[index].Workfront_Renewal_Price_ARR_One_off__c:this.availableProducts[index].Workfront_List_Price_ARR_One_off__c);
                                this.availableProducts[index].ConvertedUnitPriceARR = (this.availableProducts[index].Workfront_Renewal_Price__c != null?this.availableProducts[index].ConvertedWorkfrontRenewalPriceARR:this.availableProducts[index].ConvertedUnitPriceARR);
                             }
                        }
                        if(this.record.OEM__r.Name == 'Acquia'  && this.availableProducts[index].Acquia_List_Price__c != null ){
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
                    this.resultsError = this.availableProducts.length > 100 ? 'Your search returned over 100 results, use a more specific search string if you do not see the desired Product.' : null;
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
        this.shoppingCart[index].form.Part_of_a_package__c = event.target.checked;
        this.loadingCart = false;
    }
    
    //Executed when 'Part of Min Commit?' field is changed
    onPartOfMinCommitChanged(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Part_of_Min_Commit__c = event.target.checked;
        this.loadingCart = false;
    }

    //Executed when 'Swap Item?' field is changed
    onSwapItemChanged(event) {
        const index = event.target.dataset.index;
        this.loadingCart = true;
        this.shoppingCart[index].form.Swap_Item__c = event.target.checked;
        this.loadingCart = false;
    }

    // Go back to the Opportunity record
    cancelClick() {
        window.open('/' + this.recordId, '_parent');
    }

    // Performs an upsert on the Opportunity Line Items
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
                    UnitPrice: item.form.UnitPrice,
                    Quantity: item.form.Quantity,
                    Discount: item.form.Discount,
                    Recurring_Discount__c: item.form.Recurring_Discount__c,
                    Description: item.form.Description,
                    Sales_Price_ARR__c: item.form.Sales_Price_ARR__c,
                    //Default_Price__c: (item.Default_Price__c == null?(item.PricebookEntry.Product2.For_Contract_Renewals__c?item.form.Default_Price_ARR__c/12:item.form.Default_Price_ARR__c):item.Default_Price__c),
                    Default_Price__c: item.form.Default_Price__c,
                    Initial_Default_Price_ARR_One_off__c: item.form.Initial_Default_Price_ARR_One_off__c,
                    Product2Id : item.PricebookEntry.Product2Id,
                    Part_of_a_package__c : item.form.Part_of_a_package__c,
                    Part_of_Min_Commit__c : item.form.Part_of_Min_Commit__c,
                    Swap_Item__c : item.form.Swap_Item__c,
                    Parent_Solution_Product__c : item.parentProductId,
                    Portfolio_OLI_ID__c : item.portfolioOliId
                }
            };
        });

        // Send the data to the server
        this.loading = true;
        super.callAsync(saveProducts, { recordId: this.recordId, dataJson: JSON.stringify(data) }).then(() => {

            // Re-initialize the form now
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

    selectPortfolioProductClick(event) {
        const product = this.customerPortfolioProducts[event.target.dataset.index];
        console.log('Entered Portfolio Product Click');
        // Prevent double selection
        this.loadingCustomerPortfolioProducts = true;
        if(product.PricebookEntry.Product2.Pricing_Type__c =='Special Pricing' && this.disableSave == false){
            this.disableSave = true;
        }
        this.loadingCart = true;
        this.shoppingCart.push({
            // Custom data
            index: this.shoppingCart.length,
            classes: '',
            isDeleted: false,
            required: false,
            portfolioOliId : product.Id,
            // Line Item data
            PricebookEntry: JSON.parse(JSON.stringify(product.PricebookEntry)),
            UnitPrice: product.UnitPrice,
            ConvertedDefaultPriceARR: (product.ConvertedDefaultPriceARR!=null?product.ConvertedDefaultPriceARR:product.ConvertedUnitPriceARR).toFixed(2),
            form: {
                Quantity:   1.00,
                UnitPrice:  product.UnitPrice,
                Discount:  0,
                Recurring_Discount__c: product.Recurring_Discount__c,
                Description: null,
                Default_Price__c: product.Default_Price__c,//(product.Recurring_Discount__c == 'Yes'?product.UnitPrice:product.Default_Price__c),
                UnitPrice: product.UnitPrice,//(product.Recurring_Discount__c == 'Yes'?product.UnitPrice:product.Default_Price__c),
                Default_Price_ARR__c: product.Default_Price_ARR__c,//(product.Recurring_Discount__c == 'Yes'?product.Sales_Price_ARR__c:product.Default_Price_ARR__c),
                Sales_Price_ARR__c: product.Sales_Price_ARR__c,//(product.Recurring_Discount__c == 'Yes'?product.Sales_Price_ARR__c:product.Default_Price_ARR__c),
                Initial_Default_Price_ARR_One_off__c: product.Initial_Default_Price_ARR_One_off__c,//(product.Recurring_Discount__c == 'Yes'?product.Sales_Price_ARR__c:product.Default_Price_ARR__c),
                Part_of_a_package__c: product.Part_of_a_package__c,
                Part_of_Min_Commit__c: product.Part_of_Min_Commit__c
            }
        });

        // Short delay
        setTimeout(() => {
            this.loadingCart = false;
            this.loadingCustomerPortfolioProducts = false;
        }, 250);
    }

    selectProductClick(event) {
        const product = this.availableProducts[event.target.dataset.index];
        console.log('Entered Product Click');
        this.defaultPrice = null;
        this.defaultPriceARR = null;
        this.convertedDefaultPriceARR = null;
        //set default price for OEM opportunity line items
        if(this.record.OEM__c != null){
        if((this.record.OEM__r.Name == 'Workfront') && (product.Workfront_List_Price__c != null || product.Workfront_Renewal_Price__c !=null)){
            if(this.record.Account.Original_Contract_Start_Date__c == this.record.Account.Current_Contract_Start_Date_new__c){
                this.defaultPriceARR = (product.Workfront_List_Price__c != null?product.Workfront_List_Price_ARR_One_off__c:product.List_Price_ARR_One_off__c).toFixed(2);
                this.defaultPrice = (product.Workfront_List_Price__c != null?product.Workfront_List_Price__c:product.UnitPrice).toFixed(2);
                this.convertedDefaultPriceARR = (product.Workfront_List_Price__c != null?product.ConvertedWorkfrontPriceARR:product.ConvertedUnitPriceARR).toFixed(2);
            }else{
                this.defaultPriceARR = (product.Workfront_Renewal_Price__c != null?product.Workfront_Renewal_Price_ARR_One_off__c:product.Workfront_List_Price_ARR_One_off__c).toFixed(2);
                this.defaultPrice = (product.Workfront_Renewal_Price__c != null?product.Workfront_Renewal_Price__c:product.Workfront_List_Price__c).toFixed(2);
                this.convertedDefaultPriceARR = (product.Workfront_Renewal_Price__c != null?product.ConvertedWorkfrontRenewalPriceARR:product.ConvertedUnitPriceARR).toFixed(2);
             }
        }
        if(this.record.OEM__r.Name == 'Acquia' && product.Acquia_List_Price__c != null){
            this.defaultPriceARR = (product.Acquia_List_Price__c != null?product.Acquia_List_Price_ARR_One_off__c:product.List_Price_ARR_One_off__c).toFixed(2);
            this.defaultPrice = (product.Acquia_List_Price__c != null?product.Acquia_List_Price__c:product.UnitPrice).toFixed(2);
            this.convertedDefaultPriceARR = (product.Acquia_List_Price__c != null?product.ConvertedAcquiaPriceARR:product.ConvertedUnitPriceARR).toFixed(2);
        }
    }
        console.log("Default Price from LWC:"+this.defaultPrice);
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
                Default_Price_ARR__c: (this.defaultPriceARR!=null?this.defaultPriceARR:product.List_Price_ARR_One_off__c).toFixed(2),
                Sales_Price_ARR__c: (this.defaultPriceARR!=null?this.defaultPriceARR:product.List_Price_ARR_One_off__c).toFixed(2),
                Part_of_Min_Commit__c:((this.record.Type.includes('New Business') || this.record.Type == 'Existing Business - Platform Transfer' ) && product.Product2.For_Contract_Renewals__c?true:false)
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
                            Default_Price_ARR__c: (this.defaultPriceARR!=null?this.defaultPriceARR:reqProduct.List_Price_ARR_One_off__c),
                            Sales_Price_ARR__c: (this.defaultPriceARR!=null?this.defaultPriceARR:reqProduct.List_Price_ARR_One_off__c),
                            Part_of_Min_Commit__c:((this.record.Type.includes('New Business') || this.record.Type == 'Existing Business - Platform Transfer' ) && reqProduct.Product2.For_Contract_Renewals__c?true:false)                       
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

      /*  // Short delay
        setTimeout(() => {
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
    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_LINE_ITEM_OBJECT })
    oppLineItemInfoWire;
    get oppLineItemInfo() {
        if (this.oppLineItemInfoWire && this.oppLineItemInfoWire.data) {
            return this.oppLineItemInfoWire.data;
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
                    lineItemInfo: this.oppLineItemInfoWire.data,
                    invokedObject: 'Opportunity',
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
                            Sales_Price_ARR__c: addOn.form.Sales_Price_ARR__c,
                            Default_Price_ARR__c: addOn.form.Default_Price_ARR__c,
                            Part_of_Min_Commit__c:addOn.form.Part_of_Min_Commit__c
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
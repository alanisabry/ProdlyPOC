// Provides an interface from lwc to apex methods

import getOpportunityData from '@salesforce/apex/ManageOpportunityProducts.getOpportunityDataL';
import getPicklistValues from '@salesforce/apex/ManageOpportunityProducts.getPicklistValuesL';
import saveProducts from '@salesforce/apex/ManageOpportunityProducts.saveProductsL';
import searchProducts from '@salesforce/apex/ManageOpportunityProducts.searchProductsL';
import searchUpsellProducts from '@salesforce/apex/ManageOpportunityProducts.searchUpsellProductsL';
import getOpenOpportunitiesForAccount from '@salesforce/apex/ManageOpportunityProducts.getOpenOpportunitiesForAccountL';
import getOpenOpportunityLineItems from '@salesforce/apex/ManageOpportunityProducts.getOpenOpportunityLineItemsL';
import getProductDependancies from '@salesforce/apex/ManageOpportunityProducts.getProductDependancies';

export {
    getOpportunityData,
    getPicklistValues,
    saveProducts,
    searchProducts,
    searchUpsellProducts,
    getOpenOpportunitiesForAccount,
    getOpenOpportunityLineItems,
    getProductDependancies
}
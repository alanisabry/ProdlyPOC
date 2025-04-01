// Provides an interface from lwc to apex methods

import getQuoteData from '@salesforce/apex/ManageQuoteProducts.getQuoteDataL';
import getPicklistValues from '@salesforce/apex/ManageQuoteProducts.getPicklistValuesL';
import saveProducts from '@salesforce/apex/ManageQuoteProducts.saveProductsL';
import searchProducts from '@salesforce/apex/ManageQuoteProducts.searchProductsL';
import getRemovedQuoteLineItems from '@salesforce/apex/ManageQuoteProducts.getRemovedQuoteLineItemsL';
import getPriceBookEntryDetails from '@salesforce/apex/ManageQuoteProducts.getPriceBookEntryDetailsL';
import deleteRemovedQuoteLineItems from '@salesforce/apex/ManageQuoteProducts.deleteRemovedQuoteLineItemsL';
import getProductDependancies from '@salesforce/apex/ManageOpportunityProducts.getProductDependancies';

export {
    getQuoteData,
    getPicklistValues,
    saveProducts,
    searchProducts,
    getRemovedQuoteLineItems,
    getPriceBookEntryDetails,
    deleteRemovedQuoteLineItems,
    getProductDependancies
}
import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRenewalProducts from '@salesforce/apex/OpportunityProductsController.getRenewalProducts';
import getNonRenewalProducts from '@salesforce/apex/OpportunityProductsController.getNonRenewalProducts';

export default class OpportunityProductsTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @track renewalProducts = [];
    @track nonRenewalProducts = [];
    @track isLoading = true;
    @track sortedBy;
    @track sortedDirection = 'asc';

    columns = [
        {
            label: '',
            fieldName: 'rowNumber',
            type: 'number',
            sortable: false,
            initialWidth: 50,
            hideDefaultActions: true,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Product Name',
            fieldName: 'ProductUrl',
            type: 'url',
            sortable: true,
            initialWidth: 200,
            typeAttributes: {
                label: { fieldName: 'ProductName' },
                target: '_blank'
            },
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Quantity',
            fieldName: 'Quantity',
            type: 'number',
            sortable: true,
            initialWidth: 150,
            typeAttributes: {
                minimumFractionDigits: 2, 
                maximumFractionDigits: 2  
            },
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Default Price ARR',
            fieldName: 'DefaultPriceARR', 
            type: 'text', 
            sortable: true,
            initialWidth: 200,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Price Change',
            fieldName: 'PriceChange',
            type: 'text',
            sortable: true,
            initialWidth: 200,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Recurring Discount',
            fieldName: 'RecurringDiscount',
            type: 'text',
            sortable: true,
            initialWidth: 200,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Sales Price ARR',
            fieldName: 'SalesPriceARR', 
            type: 'text', 
            sortable: true,
            initialWidth: 200,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Total Sales Price ARR',
            fieldName: 'TotalSalesPriceARR', 
            type: 'text', 
            sortable: true,
            initialWidth: 200,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Description', 
            fieldName: 'Description', 
            type: 'text', 
            sortable: true, 
            initialWidth: 250, 
            cellAttributes: { alignment: 'left' } 
        },
        {
            label: 'For Renewal', 
            fieldName: 'ForRenewal', 
            type: 'boolean', 
            sortable: true, 
            initialWidth: 150, 
            cellAttributes: { alignment: 'left' } 
        },
        {
            label: 'Part of a Package', 
            fieldName: 'PartOfAPackage', 
            type: 'boolean', 
            sortable: true, 
            initialWidth: 150, 
            cellAttributes: { alignment: 'left' } 
        }
    ];


    connectedCallback() {
        if (!this.recordId) {
            console.error('No recordId available for opportunityProductsTable.');
            return;
        }
        this.fetchProducts();
    }

    async fetchProducts() {
        this.isLoading = true;
        try {
            const [renewal, nonRenewal] = await Promise.all([
                getRenewalProducts({ opportunityId: this.recordId }),
                getNonRenewalProducts({ opportunityId: this.recordId })
            ]);
            this.renewalProducts = this.addRowNumbers(this.formatProductUrls(renewal));
            this.nonRenewalProducts = this.addRowNumbers(this.formatProductUrls(nonRenewal));
        } catch (error) {
            console.error('Error fetching products:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleAddRemoveProducts() {
        console.log('Navigating to Manage Opportunity Products App Page');
        console.log(`Record ID: ${this.recordId}`); // Verify the recordId is correct

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
            url: `/lightning/n/Manage_Opportunity_Products?c__recordId=${this.recordId}&c__launchedFrom=opportunityProducts`
            }
        });
    }


    addRowNumbers(data) {
        return data.map((item, index) => ({
            ...item,
            rowNumber: index + 1 
        }));
    }

    formatProductUrls(data) {
        return data.map(item => ({
            ...item,
            ProductUrl: `/lightning/r/OpportunityLineItem/${item.Id}/view` // Change from Product2 to OLI
        }));
    }



    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        const sortData = data =>
            [...data].sort((a, b) => {
                let valueA = a[sortedBy];
                let valueB = b[sortedBy];

                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                }
                if (typeof valueB === 'string') {
                    valueB = valueB.toLowerCase();
                }

                if (sortDirection === 'asc') {
                    return valueA > valueB ? 1 : -1;
                } else {
                    return valueA < valueB ? 1 : -1;
                }
            });

        if (sortedBy !== 'rowNumber') {
            this.renewalProducts = this.addRowNumbers(sortData(this.renewalProducts));
            this.nonRenewalProducts = this.addRowNumbers(sortData(this.nonRenewalProducts));
        }
    }
}
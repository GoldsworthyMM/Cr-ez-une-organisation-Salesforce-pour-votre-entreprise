import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerRefreshHandler, unregisterRefreshHandler, RefreshEvent } from 'lightning/refresh';

import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';
import hasCanViewProduct from '@salesforce/customPermission/Can_View_Product';

import LABEL_TITLE from '@salesforce/label/c.Opp_Products_Title';
import LABEL_COL_PRODUCT_NAME from '@salesforce/label/c.Col_Product_Name';
import LABEL_COL_QUANTITY from '@salesforce/label/c.Col_Quantity';
import LABEL_COL_UNIT_PRICE from '@salesforce/label/c.Col_Unit_Price';
import LABEL_COL_TOTAL_PRICE from '@salesforce/label/c.Col_Total_Price';
import LABEL_COL_STOCK from '@salesforce/label/c.Col_Quantity_In_Stock';
import LABEL_COL_DELETE from '@salesforce/label/c.Col_Delete';
import LABEL_COL_VIEW_PRODUCT from '@salesforce/label/c.Col_View_Product';
import LABEL_NO_PRODUCTS from '@salesforce/label/c.Msg_No_Products';
import LABEL_STOCK_INSUFFICIENT from '@salesforce/label/c.Msg_Stock_Insufficient';

export default class OpportunityProductsList extends NavigationMixin(LightningElement) {
    @api recordId;

    lineItems = [];
    wiredResult;
    isLoading = true;
    errorMessage = null;
    refreshHandlerId;

    labels = {
        title: LABEL_TITLE,
        colProductName: LABEL_COL_PRODUCT_NAME,
        colQuantity: LABEL_COL_QUANTITY,
        colUnitPrice: LABEL_COL_UNIT_PRICE,
        colTotalPrice: LABEL_COL_TOTAL_PRICE,
        colQuantityInStock: LABEL_COL_STOCK,
        colDelete: LABEL_COL_DELETE,
        colViewProduct: LABEL_COL_VIEW_PRODUCT,
        noProductsMessage: LABEL_NO_PRODUCTS,
        stockInsufficientMessage: LABEL_STOCK_INSUFFICIENT
    };

    connectedCallback() {
        this.refreshHandlerId = registerRefreshHandler(this, this.refreshHandler);
    }

    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerId);
    }

    // Synchronise le tableau lorsque la page Lightning signale une mise à jour externe
    refreshHandler = async () => {
        if (!this.wiredResult) {
            return true;
        }

        this.isLoading = true;
        try {
            await refreshApex(this.wiredResult);
        } finally {
            this.isLoading = false;
        }
        return true;
    };

    get canViewProduct() {
        return hasCanViewProduct === true;
    }

    get hasNoProducts() {
        return !this.isLoading && !this.errorMessage && this.lineItems.length === 0;
    }

    get hasStockIssue() {
        return this.lineItems.some((item) => item.IsStockInsufficient__c === true);
    }

    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
    wiredLineItems(result) {
        this.wiredResult = result;
        const { data, error } = result;

        if (data) {
            this.errorMessage = null;
            this.lineItems = data.map((row) => {
                const isInsufficient = row.IsStockInsufficient__c === true;
                return {
                    ...row,
                    productName: row.Product2 ? row.Product2.Name : '',
                    quantityInStock: row.Product2 ? row.Product2.QuantityInStock__c : 0,
                    quantityCellClass: isInsufficient ? 'cell-stock-error' : ''
                };
            });
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this.errorMessage = this.extractErrorMessage(error);
            this.showToast('Erreur de chargement', this.errorMessage, 'error');
        }
    }

    async handleDelete(event) {
        const recordIdToDelete = event.currentTarget.dataset.id;
        this.isLoading = true;

        try {
            await deleteRecord(recordIdToDelete);
            await refreshApex(this.wiredResult);
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            this.isLoading = false;
            this.showToast('Erreur de suppression', this.extractErrorMessage(error), 'error');
        }
    }

    handleViewProduct(event) {
        const productId = event.currentTarget.dataset.productId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractErrorMessage(error) {
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        return 'Une erreur inattendue est survenue.';
    }
}
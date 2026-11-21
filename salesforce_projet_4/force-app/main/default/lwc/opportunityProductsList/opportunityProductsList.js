/**
 * Composant LWC qui affiche les produits associés à une opportunité.
 * Charge les lignes de produits, signale les stocks insuffisants et permet
 * de supprimer une ligne ou d'ouvrir la fiche d'un produit.
 *
 * @author MM
 * @date 20/11/2026
 */
// Outils LWC : classe de base, propriété publique recordId et récupération réactive des données.
import { LightningElement, api, wire } from 'lwc';
// Permet d'ouvrir la fiche d'un enregistrement dans la navigation Lightning.
import { NavigationMixin } from 'lightning/navigation';
// API Lightning Data Service utilisée pour supprimer une ligne de produit.
import { deleteRecord } from 'lightning/uiRecordApi';
// Permet de relire les données mises en cache par un wire Apex.
import { refreshApex } from '@salesforce/apex';
// Affiche les notifications toast de succès ou d'erreur.
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Inscrit le composant au mécanisme de rafraîchissement partagé de la page Lightning.
import { registerRefreshHandler, unregisterRefreshHandler, RefreshEvent } from 'lightning/refresh';

// Méthode Apex qui fournit les lignes de produits de l'opportunité.
import getOpportunityLineItems from '@salesforce/apex/OpportunityProductController.getOpportunityLineItems';
// Permission personnalisée utilisée pour contrôler l'affichage du bouton de navigation vers le produit.
import hasCanViewProduct from '@salesforce/customPermission/Can_View_Product';

// Libellés traduisibles utilisés dans le template HTML.
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
    /* -------------------------------------------------------------------------
     * 1. DONNÉES ET ÉTAT DU COMPOSANT
     * ---------------------------------------------------------------------- */

    // Identifiant de l'opportunité hôte, fourni automatiquement par Lightning.
    @api recordId;

    // État du composant : données, chargement et erreurs.
    lineItems = []; // Lignes de produits à afficher dans le tableau.
    wiredResult; // Résultat complet du wire Apex, conservé pour pouvoir recharger ses données avec refreshApex.
    isLoading = true; // Indique si le composant charge ou actualise ses données; contrôle l'affichage du spinner.
    errorMessage = null; // Message de la dernière erreur de chargement, ou null en l'absence d'erreur.
    refreshHandlerId; // Identifiant de l'abonnement RefreshView, nécessaire pour le retirer à la déconnexion.

    // Regroupe les libellés Salesforce utilisés par le template HTML.
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

    /* -------------------------------------------------------------------------
     * 2. CYCLE DE VIE ET RAFRAÎCHISSEMENT
     * ---------------------------------------------------------------------- */

    // Cycle de vie : s'abonne aux demandes de rafraîchissement de la page Lightning.
    connectedCallback() {
        // Enregistre le composant pour qu'il puisse actualiser ses données lors d'un RefreshEvent.
        this.refreshHandlerId = registerRefreshHandler(this, this.refreshHandler);
    }

    // Cycle de vie : retire l'abonnement lorsque le composant quitte la page.
    disconnectedCallback() {
        // Libère l'enregistrement lorsque le composant quitte la page.
        unregisterRefreshHandler(this.refreshHandlerId);
    }

    // Gestionnaire RefreshView : recharge les données Apex lorsque la page signale une mise à jour.
    // async permet d'attendre l'opération sans bloquer l'interface Lightning.
    refreshHandler = async () => {
        // Aucune donnée n'a encore été reçue par le wire : il n'y a rien à recharger.
        if (!this.wiredResult) {
            return true;
        }

        // Affiche le spinner pendant la nouvelle lecture.
        this.isLoading = true;

        // Relit les données fournies par le wire; le bloc finally arrêtera le spinner dans tous les cas.
        try {
            await refreshApex(this.wiredResult);
        } finally {
            // Arrête le spinner que la lecture réussisse ou échoue.
            this.isLoading = false;
        }
        return true;
    };

    /* -------------------------------------------------------------------------
     * 3. GETTERS : ÉTATS CALCULÉS UTILISÉS PAR LE TEMPLATE
     * ---------------------------------------------------------------------- */

    // Indique au template si l'action « Voir produit » doit être affichée selon la permission personnalisée.
    get canViewProduct() {
        // La permission personnalisée contrôle l'affichage de l'action, pas l'accès Salesforce à l'enregistrement.
        return hasCanViewProduct === true;
    }

    // Vrai uniquement lorsque le chargement est terminé, sans erreur, et qu'aucune ligne n'est présente.
    get hasNoProducts() {
        return !this.isLoading && !this.errorMessage && this.lineItems.length === 0;
    }

    // Vrai lorsqu'au moins une ligne de produit signale un stock insuffisant.
    get hasStockIssue() {
        return this.lineItems.some((item) => item.IsStockInsufficient__c === true);
    }

    /* -------------------------------------------------------------------------
     * 4. RÉCUPÉRATION DES DONNÉES ET GESTION DES ÉTATS
     * ---------------------------------------------------------------------- */

    // Récupère les lignes de produits de l'opportunité courante via le contrôleur Apex.
    @wire(getOpportunityLineItems, { opportunityId: '$recordId' })
    wiredLineItems(result) {
        // Conserve le résultat complet du wire pour permettre son actualisation avec refreshApex.
        this.wiredResult = result;
        const { data, error } = result;

        // En cas de succès, prépare les valeurs nécessaires à l'affichage du tableau.
        if (data) {
            this.errorMessage = null;

            // Prépare chaque ligne pour le tableau : détails du produit associé et mise en évidence du stock insuffisant.
            this.lineItems = data.map((row) => {
                // Récupère l'indicateur calculé par Salesforce pour savoir si le stock est insuffisant.
                const isInsufficient = row.IsStockInsufficient__c === true;

                return {
                    ...row,
                    // Rend le nom et le stock du produit directement accessibles au template.
                    // Si la relation Product2 est absente, utilise une chaîne vide et un stock de zéro.
                    productName: row.Product2 ? row.Product2.Name : '',
                    quantityInStock: row.Product2 ? row.Product2.QuantityInStock__c : 0,
                    quantityCellClass: isInsufficient ? 'cell-stock-error' : ''
                };
            });

            // Le chargement est terminé : le template peut afficher le tableau ou le message d'absence de produits.
            this.isLoading = false;

        } else if (error) {
            // En cas d'échec, arrête le chargement et informe l'utilisateur.
            this.isLoading = false;
            this.errorMessage = this.extractErrorMessage(error);
            this.showToast('Erreur de chargement', this.errorMessage, 'error');
        }
    }

    /* -------------------------------------------------------------------------
     * 5. SUPPRESSION D'UNE LIGNE DE PRODUIT
     * ---------------------------------------------------------------------- */

    // Gestionnaire d'événement : supprime la ligne sélectionnée puis demande le rafraîchissement de la page.
    // async permet d'attendre la réponse de l'API et de traiter un échec avec catch.
    async handleDelete(event) {
        // L'identifiant de la ligne est transmis par l'attribut data-id du bouton dans le template.
        const recordIdToDelete = event.currentTarget.dataset.id;

        // Garde le tableau en état de chargement jusqu'à son actualisation.
        this.isLoading = true;

        // Tente la suppression via Lightning Data Service; une erreur sera affichée à l'utilisateur.
        try {
            // N'émet l'événement de rafraîchissement qu'après confirmation de la suppression.
            await deleteRecord(recordIdToDelete);
            // Le gestionnaire enregistré rafraîchit ce tableau; l'événement informe aussi le reste de la page.
            this.dispatchEvent(new RefreshEvent());
        } catch (error) {
            // La suppression a échoué : réactive l'affichage normal avant de signaler l'erreur.
            this.isLoading = false;
            this.showToast('Erreur de suppression', this.extractErrorMessage(error), 'error');
        }
    }

    /* -------------------------------------------------------------------------
     * 6. OUVERTURE DE LA FICHE PRODUIT
     * ---------------------------------------------------------------------- */

    // Gestionnaire d'événement : ouvre la fiche du produit sélectionné dans Lightning.
    handleViewProduct(event) {
        // L'identifiant du produit est transmis par l'attribut data-product-id du bouton.
        const productId = event.currentTarget.dataset.productId;

        // Ouvre la fiche produit dans la navigation Lightning standard.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                objectApiName: 'Product2',
                actionName: 'view'
            }
        });
    }

    /* -------------------------------------------------------------------------
     * 7. HELPERS : NOTIFICATIONS ET GESTION DES ERREURS
     * ---------------------------------------------------------------------- */

    // Helper d'interface : affiche une notification Salesforce avec le titre, le message et le type fournis.
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // Helper d'erreur : extrait le message renvoyé par Salesforce ou utilise un message de repli.
    extractErrorMessage(error) {
        // Les erreurs des API Salesforce exposent généralement leur détail dans body.message.
        if (error && error.body && error.body.message) {
            return error.body.message;
        }
        // Fournit un message compréhensible lorsque Salesforce ne renvoie pas de détail exploitable.
        return 'Une erreur inattendue est survenue.';
    }
}
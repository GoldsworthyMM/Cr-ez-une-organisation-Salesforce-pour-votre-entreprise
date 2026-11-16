/**
 * Contrôleur Apex pour le composant LWC de gestion des produits d'opportunité.
 * Délègue la récupération des lignes de produits au selector dédié.
 *
 * @author MM
 * @date 10/11/2026
 */
public with sharing class OpportunityProductController {

    /**
     * Récupère la liste des lignes de produits (OpportunityLineItem) associées à une opportunité.
     * Inclut les informations du produit parent (nom et stock disponible) ainsi que
     * l'indicateur formule de rupture de stock (IsStockInsufficient__c).
     *
     * @param opportunityId L'identifiant unique (Id) de l'Opportunité consultée
     * @return Liste triée des OpportunityLineItem, ou liste vide si aucun ID n'est fourni
     */
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId) {
        // Sécurité défensive : si l'ID de l'opportunité est absent, on évite une requête inutile
        if (opportunityId == null) {
            return new List<OpportunityLineItem>();
        }

        return OpportunityLineItemSelector.selectByOpportunityId(opportunityId);
    }
}

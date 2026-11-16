/**
 * Selector responsable des requêtes SOQL sur les lignes de produits d'opportunité.
 * La requête s'exécute en mode utilisateur pour respecter les accès de l'utilisateur courant.
 *
 * @author MM
 * @date 16/11/2026
 */
public with sharing class OpportunityLineItemSelector {

    /**
     * Récupère les lignes de produits d'une opportunité, triées par nom de produit.
     *
     * @param opportunityId Identifiant de l'opportunité
     * @return Lignes de produits accessibles à l'utilisateur courant
     */
    public static List<OpportunityLineItem> selectByOpportunityId(Id opportunityId) {
        return [
            SELECT Id,
                   Product2Id,
                   Product2.Name,
                   Quantity,
                   UnitPrice,
                   TotalPrice,
                   Product2.QuantityInStock__c,
                   IsStockInsufficient__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
            WITH USER_MODE
            ORDER BY Product2.Name ASC
        ];
    }
}
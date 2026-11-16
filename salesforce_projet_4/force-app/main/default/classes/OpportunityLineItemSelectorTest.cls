/**
 * Classe de test unitaire pour OpportunityLineItemSelector.
 * Vérifie la récupération des lignes de produits, leurs champs et leur ordre.
 *
 * @author MM
 * @date 16/11/2026
 */
@IsTest
private class OpportunityLineItemSelectorTest {

    /**
     * Prépare une opportunité avec une ligne de produit pour les tests du Selector.
     */
    @TestSetup
    static void setupTestData() {
        VitesseTestDataFactory.createOpportunityWithProductLine();
    }

    /**
     * Vérifie que le Selector ne retourne que les lignes de l'opportunité demandée,
     * avec les champs attendus et dans l'ordre des noms de produits.
     */
    @IsTest
    static void testSelectByOpportunityIdReturnsOrderedMatchingLines() {
        // Récupère l'opportunité préparée par les données de test.
        Opportunity testOpportunity = getTestOpportunity();

        // Ajoute un second produit afin de vérifier le tri alphabétique du Selector.
        Product2 secondTestProduct = VitesseTestDataFactory.createTestProduct(
            'Audi Model X Test',
            10
        );

        // Crée son entrée au catalogue standard pour pouvoir l'ajouter à une ligne d'opportunité.
        PricebookEntry secondProductPricebookEntry =
            VitesseTestDataFactory.createStandardPricebookEntry(secondTestProduct.Id, 80000);
        VitesseTestDataFactory.createTestOpportunityLineItem(
            testOpportunity.Id,
            secondProductPricebookEntry.Id,
            2,
            80000
        );

        // Ajoute une ligne sur une autre opportunité pour vérifier qu'elle est exclue du résultat.
        Opportunity otherTestOpportunity =
            VitesseTestDataFactory.createTestOpportunity(Test.getStandardPricebookId());
        VitesseTestDataFactory.createTestOpportunityLineItem(
            otherTestOpportunity.Id,
            secondProductPricebookEntry.Id,
            1,
            80000
        );

        // Démarre la portion du test portant sur la requête du Selector.
        Test.startTest();
        List<OpportunityLineItem> selectedOpportunityLineItems =
            OpportunityLineItemSelector.selectByOpportunityId(testOpportunity.Id);
        Test.stopTest();

        // Le Selector doit retourner les deux lignes liées à l'opportunité demandée.
        System.assertEquals(
            2,
            selectedOpportunityLineItems.size(),
            'Seules les deux lignes de l\'opportunité demandée doivent être retournées.'
        );

        // Le produit Audi doit précéder le produit Tesla selon l'ordre alphabétique.
        System.assertEquals(
            'Audi Model X Test',
            selectedOpportunityLineItems.get(0).Product2.Name,
            'La première ligne doit correspondre au produit Audi.'
        );

        // La seconde ligne doit correspondre au produit Tesla créé dans le jeu de données.
        System.assertEquals(
            'Tesla Model S Test',
            selectedOpportunityLineItems.get(1).Product2.Name,
            'La seconde ligne doit correspondre au produit Tesla.'
        );

        // Le Selector doit inclure le stock du produit parent.
        System.assertEquals(
            10,
            selectedOpportunityLineItems.get(0).Product2.QuantityInStock__c,
            'Le stock du produit doit être inclus dans le résultat.'
        );

        // Une quantité commandée de 2 sur un stock de 10 ne constitue pas une rupture.
        System.assertEquals(
            false,
            selectedOpportunityLineItems.get(0).IsStockInsufficient__c,
            'L\'indicateur de rupture doit être false lorsque le stock est suffisant.'
        );
    }

    /**
     * Helper de test qui centralise la récupération de l'unique opportunité créée par les données.
     */
    private static Opportunity getTestOpportunity() {
        return [SELECT Id FROM Opportunity LIMIT 1];
    }
}